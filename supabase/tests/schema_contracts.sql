begin;

select plan(28);

select has_column('public', 'profiles', 'push_notifications_enabled', 'profiles.push_notifications_enabled');
select has_column('public', 'profiles', 'push_notify_like', 'profiles.push_notify_like');
select has_column('public', 'profiles', 'push_notify_comment', 'profiles.push_notify_comment');
select has_column('public', 'profiles', 'push_notify_follow', 'profiles.push_notify_follow');
select has_column('public', 'profiles', 'push_notify_message', 'profiles.push_notify_message');
select has_column('public', 'profiles', 'push_notify_mention', 'profiles.push_notify_mention');
select has_column('public', 'profiles', 'push_notify_category_approved', 'profiles.push_notify_category_approved');
select has_column('public', 'profiles', 'push_notify_category_rejected', 'profiles.push_notify_category_rejected');

select has_column('public', 'notification_devices', 'user_id', 'notification_devices.user_id');
select has_column('public', 'notification_devices', 'platform', 'notification_devices.platform');
select has_column('public', 'notification_devices', 'push_provider', 'notification_devices.push_provider');
select has_column('public', 'notification_devices', 'token', 'notification_devices.token');
select has_column('public', 'notification_devices', 'device_id', 'notification_devices.device_id');
select has_column('public', 'notification_devices', 'is_enabled', 'notification_devices.is_enabled');
select has_column('public', 'notification_devices', 'last_seen_at', 'notification_devices.last_seen_at');
select has_column('public', 'notification_devices', 'revoked_at', 'notification_devices.revoked_at');
select has_column('public', 'notification_devices', 'created_at', 'notification_devices.created_at');
select has_column('public', 'notification_devices', 'updated_at', 'notification_devices.updated_at');

select has_column('public', 'notification_push_deliveries', 'notification_id', 'notification_push_deliveries.notification_id');
select has_column('public', 'notification_push_deliveries', 'notification_device_id', 'notification_push_deliveries.notification_device_id');
select has_column('public', 'notification_push_deliveries', 'user_id', 'notification_push_deliveries.user_id');
select has_column('public', 'notification_push_deliveries', 'type', 'notification_push_deliveries.type');
select has_column('public', 'notification_push_deliveries', 'status', 'notification_push_deliveries.status');
select has_column('public', 'notification_push_deliveries', 'provider_message_id', 'notification_push_deliveries.provider_message_id');
select has_column('public', 'notification_push_deliveries', 'error', 'notification_push_deliveries.error');
select has_column('public', 'notification_push_deliveries', 'sent_at', 'notification_push_deliveries.sent_at');
select has_column('public', 'notification_push_deliveries', 'created_at', 'notification_push_deliveries.created_at');
select has_column('public', 'notification_push_deliveries', 'updated_at', 'notification_push_deliveries.updated_at');

select * from finish();

rollback;
