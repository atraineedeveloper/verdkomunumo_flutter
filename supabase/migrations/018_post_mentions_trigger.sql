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
  WHERE profile.id <> NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_post_mention_notification ON public.posts;
CREATE TRIGGER on_post_mention_notification
  AFTER INSERT ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_mention_notifications();
