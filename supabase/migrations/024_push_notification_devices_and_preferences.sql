ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_notify_like BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS push_notify_comment BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_notify_follow BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS push_notify_message BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_notify_mention BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_notify_category_approved BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS push_notify_category_rejected BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.notification_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('web', 'android', 'ios')),
  push_provider TEXT NOT NULL CHECK (push_provider IN ('webpush', 'fcm', 'apns')),
  token TEXT NOT NULL,
  device_id TEXT,
  app_version TEXT,
  locale TEXT,
  timezone TEXT,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_devices_provider_token
  ON public.notification_devices(push_provider, token);

CREATE INDEX IF NOT EXISTS idx_notification_devices_user_enabled
  ON public.notification_devices(user_id, is_enabled, last_seen_at DESC)
  WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notification_devices_device_id
  ON public.notification_devices(user_id, device_id)
  WHERE device_id IS NOT NULL;

ALTER TABLE public.notification_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_devices_select_own"
  ON public.notification_devices
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notification_devices_insert_own"
  ON public.notification_devices
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notification_devices_update_own"
  ON public.notification_devices
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "notification_devices_delete_own"
  ON public.notification_devices
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.touch_notification_device_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_notification_device_updated ON public.notification_devices;
CREATE TRIGGER on_notification_device_updated
  BEFORE UPDATE ON public.notification_devices
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_notification_device_updated_at();

CREATE TABLE IF NOT EXISTS public.notification_push_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  notification_device_id UUID NOT NULL REFERENCES public.notification_devices(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (
    type IN (
      'like',
      'comment',
      'follow',
      'message',
      'mention',
      'category_approved',
      'category_rejected'
    )
  ),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (
    status IN ('queued', 'processing', 'sent', 'skipped', 'failed', 'invalid_token')
  ),
  provider_message_id TEXT,
  error TEXT,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT notification_push_deliveries_unique_target
    UNIQUE (notification_id, notification_device_id)
);

CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_user_created
  ON public.notification_push_deliveries(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_push_deliveries_status_created
  ON public.notification_push_deliveries(status, created_at DESC);

ALTER TABLE public.notification_push_deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_push_deliveries_select_own"
  ON public.notification_push_deliveries
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.touch_notification_push_delivery_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_notification_push_delivery_updated ON public.notification_push_deliveries;
CREATE TRIGGER on_notification_push_delivery_updated
  BEFORE UPDATE ON public.notification_push_deliveries
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_notification_push_delivery_updated_at();

CREATE OR REPLACE FUNCTION public.push_notifications_enabled_for_type(
  profile_row public.profiles,
  notification_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  IF profile_row.push_notifications_enabled IS DISTINCT FROM TRUE THEN
    RETURN FALSE;
  END IF;

  RETURN CASE notification_type
    WHEN 'like' THEN profile_row.push_notify_like
    WHEN 'comment' THEN profile_row.push_notify_comment
    WHEN 'follow' THEN profile_row.push_notify_follow
    WHEN 'message' THEN profile_row.push_notify_message
    WHEN 'mention' THEN profile_row.push_notify_mention
    WHEN 'category_approved' THEN profile_row.push_notify_category_approved
    WHEN 'category_rejected' THEN profile_row.push_notify_category_rejected
    ELSE FALSE
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.queue_notification_push_delivery()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notification_push_deliveries (
    notification_id,
    notification_device_id,
    user_id,
    type,
    status,
    updated_at
  )
  SELECT
    NEW.id,
    device.id,
    NEW.user_id,
    NEW.type,
    'queued',
    NOW()
  FROM public.notification_devices AS device
  JOIN public.profiles AS profile
    ON profile.id = NEW.user_id
  WHERE device.user_id = NEW.user_id
    AND device.is_enabled = TRUE
    AND device.revoked_at IS NULL
    AND public.push_notifications_enabled_for_type(profile, NEW.type)
  ON CONFLICT (notification_id, notification_device_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_notification_queue_push_delivery ON public.notifications;
CREATE TRIGGER on_notification_queue_push_delivery
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.queue_notification_push_delivery();
