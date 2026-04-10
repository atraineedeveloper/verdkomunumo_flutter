CREATE TABLE public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'hate', 'nudity', 'violence', 'misinformation', 'other')),
  details TEXT NOT NULL DEFAULT '' CHECK (char_length(details) <= 500),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolution_note TEXT NOT NULL DEFAULT '' CHECK (char_length(resolution_note) <= 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT content_reports_target_check CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR
    (post_id IS NULL AND comment_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_content_reports_unique_post_per_user
  ON public.content_reports(user_id, post_id)
  WHERE post_id IS NOT NULL;

CREATE UNIQUE INDEX idx_content_reports_unique_comment_per_user
  ON public.content_reports(user_id, comment_id)
  WHERE comment_id IS NOT NULL;

CREATE INDEX idx_content_reports_status_created
  ON public.content_reports(status, created_at DESC);

CREATE INDEX idx_content_reports_post
  ON public.content_reports(post_id, created_at DESC);

CREATE INDEX idx_content_reports_comment
  ON public.content_reports(comment_id, created_at DESC);

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "content_reports_insert_own" ON public.content_reports
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "content_reports_select" ON public.content_reports
FOR SELECT
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

CREATE POLICY "content_reports_update_staff" ON public.content_reports
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

CREATE POLICY "posts_staff_select" ON public.posts
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

CREATE POLICY "comments_staff_select" ON public.comments
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "categories_admin_delete" ON public.categories;
CREATE POLICY "categories_admin_delete" ON public.categories
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin')
  )
);
