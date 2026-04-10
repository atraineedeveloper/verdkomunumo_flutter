CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email_notify_comment BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_notify_message BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_notifications_conversation ON public.notifications(conversation_id);

CREATE TABLE IF NOT EXISTS public.notification_email_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL UNIQUE REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('comment', 'message')),
  recipient_email TEXT,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'skipped', 'failed')),
  provider_message_id TEXT,
  error TEXT,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_email_deliveries_user_created
  ON public.notification_email_deliveries(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_email_deliveries_status
  ON public.notification_email_deliveries(status, created_at DESC);

ALTER TABLE public.notification_email_deliveries ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.handle_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_owner_id UUID;
BEGIN
  SELECT user_id INTO post_owner_id
  FROM public.posts
  WHERE id = NEW.post_id;

  IF post_owner_id IS NOT NULL AND post_owner_id <> NEW.user_id THEN
    INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, message)
    VALUES (
      post_owner_id,
      NEW.user_id,
      'comment',
      NEW.post_id,
      NEW.id,
      LEFT(NEW.content, 180)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_comment_notification ON public.comments;
CREATE TRIGGER on_comment_notification
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_notification();

CREATE OR REPLACE FUNCTION public.handle_message_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (user_id, actor_id, type, conversation_id, message)
  SELECT
    participant.user_id,
    NEW.sender_id,
    'message',
    NEW.conversation_id,
    LEFT(NEW.content, 180)
  FROM public.conversation_participants AS participant
  WHERE participant.conversation_id = NEW.conversation_id
    AND participant.user_id <> NEW.sender_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_message_notification ON public.messages;
CREATE TRIGGER on_message_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_message_notification();

CREATE OR REPLACE FUNCTION public.queue_notification_email_delivery()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type IN ('comment', 'message') THEN
    INSERT INTO public.notification_email_deliveries (notification_id, user_id, type, status, updated_at)
    VALUES (NEW.id, NEW.user_id, NEW.type, 'queued', NOW())
    ON CONFLICT (notification_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_notification_queue_email_delivery ON public.notifications;
CREATE TRIGGER on_notification_queue_email_delivery
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.queue_notification_email_delivery();
