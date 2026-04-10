CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_id);

CREATE OR REPLACE FUNCTION public.validate_comment_reply()
RETURNS TRIGGER AS $$
DECLARE
  parent_post_id UUID;
  parent_parent_id UUID;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT post_id, parent_id
  INTO parent_post_id, parent_parent_id
  FROM public.comments
  WHERE id = NEW.parent_id;

  IF parent_post_id IS NULL THEN
    RAISE EXCEPTION 'Parent comment does not exist.';
  END IF;

  IF parent_post_id <> NEW.post_id THEN
    RAISE EXCEPTION 'Reply comment must belong to the same post as its parent.';
  END IF;

  IF parent_parent_id IS NOT NULL THEN
    RAISE EXCEPTION 'Nested replies deeper than one level are not allowed.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS comments_validate_reply ON public.comments;
CREATE TRIGGER comments_validate_reply
  BEFORE INSERT OR UPDATE OF post_id, parent_id ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.validate_comment_reply();

CREATE OR REPLACE FUNCTION public.handle_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_owner_id UUID;
  parent_owner_id UUID;
BEGIN
  SELECT user_id INTO post_owner_id
  FROM public.posts
  WHERE id = NEW.post_id;

  IF post_owner_id IS NOT NULL AND post_owner_id <> NEW.user_id THEN
    INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, message)
    VALUES (post_owner_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, LEFT(NEW.content, 180))
    ON CONFLICT DO NOTHING;
  END IF;

  IF NEW.parent_id IS NOT NULL THEN
    SELECT user_id INTO parent_owner_id
    FROM public.comments
    WHERE id = NEW.parent_id;

    IF parent_owner_id IS NOT NULL AND parent_owner_id <> NEW.user_id AND parent_owner_id <> post_owner_id THEN
      INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id, message)
      VALUES (parent_owner_id, NEW.user_id, 'comment', NEW.post_id, NEW.id, LEFT(NEW.content, 180))
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
