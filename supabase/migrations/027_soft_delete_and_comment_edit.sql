ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE OR REPLACE FUNCTION public.handle_post_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_deleted IS DISTINCT FROM OLD.is_deleted THEN
    IF NEW.is_deleted THEN
      UPDATE public.profiles
        SET posts_count = GREATEST(posts_count - 1, 0)
        WHERE id = NEW.user_id;
      UPDATE public.categories
        SET post_count = GREATEST(post_count - 1, 0)
        WHERE id = NEW.category_id;
    ELSE
      UPDATE public.profiles
        SET posts_count = posts_count + 1
        WHERE id = NEW.user_id;
      UPDATE public.categories
        SET post_count = post_count + 1
        WHERE id = NEW.category_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_post_soft_delete ON public.posts;
CREATE TRIGGER on_post_soft_delete
  AFTER UPDATE OF is_deleted ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.handle_post_soft_delete();

CREATE OR REPLACE FUNCTION public.handle_comment_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_deleted IS DISTINCT FROM OLD.is_deleted THEN
    IF NEW.is_deleted THEN
      UPDATE public.posts
        SET comments_count = GREATEST(comments_count - 1, 0)
        WHERE id = NEW.post_id;
    ELSE
      UPDATE public.posts
        SET comments_count = comments_count + 1
        WHERE id = NEW.post_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_soft_delete ON public.comments;
CREATE TRIGGER on_comment_soft_delete
  AFTER UPDATE OF is_deleted ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_comment_soft_delete();
