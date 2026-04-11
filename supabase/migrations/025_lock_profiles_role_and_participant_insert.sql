-- Tighten RLS for conversation participants and prevent role self-promotion.

-- Prevent users from inserting themselves into conversations they do not belong to,
-- except for bootstrapping a brand-new conversation.
DROP POLICY IF EXISTS "participants_insert_own" ON public.conversation_participants;
CREATE POLICY "participants_insert_own" ON public.conversation_participants
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      public.is_conversation_participant(conversation_id)
      OR NOT EXISTS (
        SELECT 1
        FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
      )
    )
  );

-- Prevent authenticated users from changing their own role.
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (
      SELECT role
      FROM public.profiles p
      WHERE p.id = auth.uid()
    )
  );

REVOKE UPDATE (role) ON public.profiles FROM authenticated;
REVOKE UPDATE (role) ON public.profiles FROM anon;
