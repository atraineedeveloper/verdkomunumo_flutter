ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_like BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_follow BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_mention BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_category_approved BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_category_rejected BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.notification_email_deliveries
  DROP CONSTRAINT IF EXISTS notification_email_deliveries_type_check;

ALTER TABLE public.notification_email_deliveries
  ADD CONSTRAINT notification_email_deliveries_type_check
  CHECK (
    type IN (
      'like',
      'comment',
      'follow',
      'message',
      'mention',
      'category_approved',
      'category_rejected'
    )
  );

CREATE OR REPLACE FUNCTION public.queue_notification_email_delivery()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type IN (
    'like',
    'comment',
    'follow',
    'message',
    'mention',
    'category_approved',
    'category_rejected'
  ) THEN
    INSERT INTO public.notification_email_deliveries (notification_id, user_id, type, status, updated_at)
    VALUES (NEW.id, NEW.user_id, NEW.type, 'queued', NOW())
    ON CONFLICT (notification_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
