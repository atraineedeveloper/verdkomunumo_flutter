CREATE TABLE public.community_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 2000),
  client_nonce TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_community_messages_created_at
  ON public.community_messages(created_at DESC);

CREATE INDEX idx_community_messages_user_id_created_at
  ON public.community_messages(user_id, created_at DESC);

CREATE UNIQUE INDEX idx_community_messages_user_nonce
  ON public.community_messages(user_id, client_nonce)
  WHERE client_nonce IS NOT NULL;

ALTER TABLE public.community_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "community_messages_select_authenticated"
  ON public.community_messages
  FOR SELECT
  TO authenticated
  USING (NOT is_deleted);

CREATE POLICY "community_messages_insert_own"
  ON public.community_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id AND NOT is_deleted);

ALTER PUBLICATION supabase_realtime ADD TABLE public.community_messages;
