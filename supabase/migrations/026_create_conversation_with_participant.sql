CREATE OR REPLACE FUNCTION public.create_conversation_with_participant(
  target_user_id UUID
)
RETURNS UUID AS $$
DECLARE
  new_conversation_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF target_user_id IS NULL OR target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Invalid participant';
  END IF;

  INSERT INTO public.conversations DEFAULT VALUES
  RETURNING id INTO new_conversation_id;

  INSERT INTO public.conversation_participants (conversation_id, user_id)
  VALUES
    (new_conversation_id, auth.uid()),
    (new_conversation_id, target_user_id);

  RETURN new_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
