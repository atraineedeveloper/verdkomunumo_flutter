CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_unique_cmt_mention_event
  ON public.notifications(user_id, actor_id, type, comment_id)
  WHERE type = 'mention' AND comment_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.handle_comment_mention_notifications()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, message)
  SELECT DISTINCT
    profile.id,
    NEW.user_id,
    'mention',
    NEW.post_id,
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

DROP TRIGGER IF EXISTS on_comment_mention_notification ON public.comments;
CREATE TRIGGER on_comment_mention_notification
  AFTER INSERT OR UPDATE OF content
  ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_mention_notifications();
