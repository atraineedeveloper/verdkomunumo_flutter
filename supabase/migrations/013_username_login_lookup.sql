create or replace function public.resolve_login_email(login_identifier text)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  resolved_email text;
begin
  select u.email
    into resolved_email
  from public.profiles p
  join auth.users u on u.id = p.id
  where lower(p.username) = lower(login_identifier)
  limit 1;

  return resolved_email;
end;
$$;

revoke all on function public.resolve_login_email(text) from public;
grant execute on function public.resolve_login_email(text) to anon, authenticated;
