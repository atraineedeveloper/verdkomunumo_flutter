revoke execute on function public.resolve_login_email(text) from anon, authenticated;

comment on function public.resolve_login_email(text)
is 'Internal helper for server-side username login lookup. Do not expose to client roles.';
