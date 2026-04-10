ALTER TABLE public.profiles
  ALTER COLUMN email_notifications_enabled SET DEFAULT TRUE,
  ALTER COLUMN email_notify_comment SET DEFAULT TRUE,
  ALTER COLUMN email_notify_message SET DEFAULT TRUE,
  ALTER COLUMN email_notify_mention SET DEFAULT TRUE,
  ALTER COLUMN email_notify_like SET DEFAULT FALSE,
  ALTER COLUMN email_notify_follow SET DEFAULT FALSE,
  ALTER COLUMN email_notify_category_approved SET DEFAULT FALSE,
  ALTER COLUMN email_notify_category_rejected SET DEFAULT FALSE;

UPDATE public.profiles
SET
  email_notify_like = FALSE,
  email_notify_follow = FALSE,
  email_notify_category_approved = FALSE,
  email_notify_category_rejected = FALSE
WHERE
  email_notify_like IS DISTINCT FROM FALSE
  OR email_notify_follow IS DISTINCT FROM FALSE
  OR email_notify_category_approved IS DISTINCT FROM FALSE
  OR email_notify_category_rejected IS DISTINCT FROM FALSE;
