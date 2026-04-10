ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('user', 'moderator', 'admin', 'owner'));

DROP POLICY IF EXISTS "posts_admin_update" ON public.posts;
CREATE POLICY "posts_admin_update" ON public.posts FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "comments_admin_update" ON public.comments;
CREATE POLICY "comments_admin_update" ON public.comments FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "categories_admin_select" ON public.categories;
CREATE POLICY "categories_admin_select" ON public.categories FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin')
  )
);

DROP POLICY IF EXISTS "categories_admin_insert" ON public.categories;
CREATE POLICY "categories_admin_insert" ON public.categories FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin')
  )
);

DROP POLICY IF EXISTS "categories_admin_update" ON public.categories;
CREATE POLICY "categories_admin_update" ON public.categories FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin')
  )
);

DROP POLICY IF EXISTS "suggestions_select" ON public.category_suggestions;
CREATE POLICY "suggestions_select" ON public.category_suggestions FOR SELECT USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "suggestions_update_staff" ON public.category_suggestions;
CREATE POLICY "suggestions_update_staff" ON public.category_suggestions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "app_suggestions_select" ON public.app_suggestions;
CREATE POLICY "app_suggestions_select" ON public.app_suggestions FOR SELECT USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

DROP POLICY IF EXISTS "app_suggestions_update_staff" ON public.app_suggestions;
CREATE POLICY "app_suggestions_update_staff" ON public.app_suggestions FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);
