CREATE POLICY "notifications_insert_actor" ON public.notifications
FOR INSERT
WITH CHECK (auth.uid() = actor_id);
