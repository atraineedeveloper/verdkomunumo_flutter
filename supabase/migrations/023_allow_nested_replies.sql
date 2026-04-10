CREATE OR REPLACE FUNCTION public.validate_comment_reply()
RETURNS TRIGGER AS $$
DECLARE
  parent_post_id UUID;
BEGIN
  IF NEW.parent_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT post_id
  INTO parent_post_id
  FROM public.comments
  WHERE id = NEW.parent_id;

  IF parent_post_id IS NULL THEN
    RAISE EXCEPTION 'Parent comment does not exist.';
  END IF;

  IF parent_post_id <> NEW.post_id THEN
    RAISE EXCEPTION 'Reply comment must belong to the same post as its parent.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
