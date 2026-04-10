CREATE TABLE public.app_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) >= 4 AND char_length(title) <= 80),
  description TEXT NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 500),
  context TEXT NOT NULL DEFAULT '' CHECK (char_length(context) <= 500),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'planned', 'closed')),
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_app_suggestions_status ON public.app_suggestions(status, created_at DESC);
CREATE INDEX idx_app_suggestions_user ON public.app_suggestions(user_id, created_at DESC);

ALTER TABLE public.app_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_suggestions_insert" ON public.app_suggestions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "app_suggestions_select" ON public.app_suggestions
FOR SELECT
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);

CREATE POLICY "app_suggestions_update_staff" ON public.app_suggestions
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('owner', 'admin', 'moderator')
  )
);
