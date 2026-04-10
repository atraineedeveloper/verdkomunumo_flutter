begin;

select plan(26);

select ok(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'profiles'),
  'profiles RLS enabled'
);
select ok(
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'profiles') > 0,
  'profiles policies exist'
);

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'posts'), 'posts RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'posts') > 0, 'posts policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'comments'), 'comments RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'comments') > 0, 'comments policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'likes'), 'likes RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'likes') > 0, 'likes policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'follows'), 'follows RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'follows') > 0, 'follows policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'categories'), 'categories RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'categories') > 0, 'categories policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'category_suggestions'), 'category_suggestions RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'category_suggestions') > 0, 'category_suggestions policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'conversations'), 'conversations RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'conversations') > 0, 'conversations policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'conversation_participants'), 'conversation_participants RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'conversation_participants') > 0, 'conversation_participants policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'messages'), 'messages RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'messages') > 0, 'messages policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'notifications'), 'notifications RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'notifications') > 0, 'notifications policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'notification_devices'), 'notification_devices RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'notification_devices') > 0, 'notification_devices policies exist');

select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'notification_push_deliveries'), 'notification_push_deliveries RLS enabled');
select ok((select count(*) from pg_policies where schemaname = 'public' and tablename = 'notification_push_deliveries') > 0, 'notification_push_deliveries policies exist');

select * from finish();

rollback;
