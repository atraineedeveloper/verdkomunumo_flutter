-- Enable Realtime for notifications table so the push notification
-- subscription filter (user_id=eq.<id>) works correctly.
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
