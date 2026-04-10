ALTER TABLE public.notification_email_deliveries
  DROP CONSTRAINT IF EXISTS notification_email_deliveries_status_check;

ALTER TABLE public.notification_email_deliveries
  ADD CONSTRAINT notification_email_deliveries_status_check
  CHECK (status IN ('queued', 'processing', 'sent', 'skipped', 'failed'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_unique_comment_event
  ON public.notifications(user_id, actor_id, type, comment_id)
  WHERE type = 'comment' AND comment_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_unique_mention_event
  ON public.notifications(user_id, actor_id, type, post_id)
  WHERE type = 'mention' AND post_id IS NOT NULL;

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
    )
    ON CONFLICT DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.handle_post_mention_notifications()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (user_id, actor_id, type, post_id, message)
  SELECT DISTINCT
    profile.id,
    NEW.user_id,
    'mention',
    NEW.id,
    LEFT(NEW.content, 180)
  FROM regexp_matches(NEW.content, '(?<![A-Za-z0-9_&@#])@([a-z0-9_]+)', 'g') AS mention(match)
  JOIN public.profiles AS profile
    ON profile.username = mention.match[1]
  WHERE profile.id <> NEW.user_id
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
