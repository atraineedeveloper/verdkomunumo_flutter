CREATE OR REPLACE FUNCTION public.is_conversation_participant(conversation_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.conversation_participants
    WHERE conversation_id = conversation_uuid
      AND user_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "messages_select" ON public.messages;
CREATE POLICY "messages_select" ON public.messages FOR SELECT USING (
  public.is_conversation_participant(conversation_id)
);

DROP POLICY IF EXISTS "messages_insert" ON public.messages;
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND public.is_conversation_participant(conversation_id)
);

DROP POLICY IF EXISTS "messages_update_participant" ON public.messages;
CREATE POLICY "messages_update_participant" ON public.messages FOR UPDATE USING (
  public.is_conversation_participant(conversation_id)
) WITH CHECK (
  public.is_conversation_participant(conversation_id)
);

DROP POLICY IF EXISTS "participants_select" ON public.conversation_participants;
CREATE POLICY "participants_select" ON public.conversation_participants FOR SELECT USING (
  auth.uid() = user_id OR public.is_conversation_participant(conversation_id)
);

DROP POLICY IF EXISTS "participants_insert_own" ON public.conversation_participants;
CREATE POLICY "participants_insert_own" ON public.conversation_participants FOR INSERT WITH CHECK (
  auth.uid() = user_id OR public.is_conversation_participant(conversation_id)
);

DROP POLICY IF EXISTS "participants_update_own" ON public.conversation_participants;
CREATE POLICY "participants_update_own" ON public.conversation_participants FOR UPDATE USING (
  auth.uid() = user_id
) WITH CHECK (
  auth.uid() = user_id
);

DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
CREATE POLICY "conversations_select" ON public.conversations FOR SELECT USING (
  public.is_conversation_participant(id)
);

DROP POLICY IF EXISTS "conversations_insert_authenticated" ON public.conversations;
CREATE POLICY "conversations_insert_authenticated" ON public.conversations FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
);
