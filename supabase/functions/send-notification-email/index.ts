import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8'

type NotificationType =
  | 'like'
  | 'comment'
  | 'follow'
  | 'message'
  | 'mention'
  | 'category_approved'
  | 'category_rejected'

type DeliveryRecord = {
  id: string
  notification_id: string
  user_id: string
  type: NotificationType
  status: 'queued' | 'processing' | 'sent' | 'skipped' | 'failed'
  recipient_email: string | null
}

type NotificationRecord = {
  id: string
  user_id: string
  actor_id: string
  type: NotificationType
  post_id: string | null
  conversation_id: string | null
  message: string | null
  actor?: {
    display_name: string
    username: string
  } | null
  recipient?: {
    display_name: string
    email_notifications_enabled: boolean
    email_notify_like: boolean
    email_notify_comment: boolean
    email_notify_follow: boolean
    email_notify_message: boolean
    email_notify_mention: boolean
    email_notify_category_approved: boolean
    email_notify_category_rejected: boolean
  } | null
}

type EmailPreferenceField =
  | 'email_notify_like'
  | 'email_notify_comment'
  | 'email_notify_follow'
  | 'email_notify_message'
  | 'email_notify_mention'
  | 'email_notify_category_approved'
  | 'email_notify_category_rejected'

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const resendApiKey = Deno.env.get('RESEND_API_KEY') ?? ''
const emailFrom = Deno.env.get('EMAIL_FROM') ?? ''
const appUrl = (Deno.env.get('VITE_APP_URL') ?? 'http://localhost:5174').replace(/\/+$/, '')
const webhookSecret = Deno.env.get('EMAIL_WEBHOOK_SECRET') ?? ''

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

const preferenceFields: Record<NotificationType, EmailPreferenceField> = {
  like: 'email_notify_like',
  comment: 'email_notify_comment',
  follow: 'email_notify_follow',
  message: 'email_notify_message',
  mention: 'email_notify_mention',
  category_approved: 'email_notify_category_approved',
  category_rejected: 'email_notify_category_rejected',
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  })
}

function extractDeliveryId(payload: unknown): string | null {
  if (!payload || typeof payload !== 'object') return null

  const record = payload as Record<string, unknown>
  if (typeof record.delivery_id === 'string') return record.delivery_id

  if (record.record && typeof record.record === 'object') {
    const webhookRecord = record.record as Record<string, unknown>
    if (typeof webhookRecord.id === 'string') return webhookRecord.id
  }

  return null
}

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

function truncate(value: string, max = 180) {
  return value.length > max ? `${value.slice(0, max - 1)}…` : value
}

function buildSettingsUrl(options?: { type?: NotificationType; unsubscribe?: boolean }) {
  const url = new URL('/agordoj', `${appUrl}/`)
  if (options?.type) {
    url.searchParams.set('email', options.type)
  }
  if (options?.unsubscribe) {
    url.searchParams.set('unsubscribe', '1')
  }
  url.hash = 'email-preferences'
  return url.toString()
}

function notificationTargetUrl(notification: NotificationRecord) {
  switch (notification.type) {
    case 'comment':
    case 'like':
    case 'mention':
      return notification.post_id ? `${appUrl}/afisxo/${notification.post_id}` : `${appUrl}/fonto`
    case 'message':
      return notification.conversation_id ? `${appUrl}/mesagxoj/${notification.conversation_id}` : `${appUrl}/mesagxoj`
    case 'follow':
      return notification.actor?.username ? `${appUrl}/profilo/${notification.actor.username}` : `${appUrl}/sciigoj`
    case 'category_approved':
    case 'category_rejected':
      return `${appUrl}/sciigoj`
  }
}

function notificationActionLabel(type: NotificationType) {
  switch (type) {
    case 'comment':
      return 'Vidi la komenton'
    case 'like':
      return 'Vidi la afiŝon'
    case 'follow':
      return 'Vidi la profilon'
    case 'message':
      return 'Malfermi la konversacion'
    case 'mention':
      return 'Vidi la mencion'
    case 'category_approved':
      return 'Vidi la sciigon'
    case 'category_rejected':
      return 'Vidi la sciigon'
  }
}

function notificationHeading(type: NotificationType) {
  switch (type) {
    case 'comment':
      return 'Nova komento ĉe Verdkomunumo'
    case 'like':
      return 'Nova ŝato ĉe Verdkomunumo'
    case 'follow':
      return 'Nova sekvanto ĉe Verdkomunumo'
    case 'message':
      return 'Nova mesaĝo ĉe Verdkomunumo'
    case 'mention':
      return 'Nova mencio ĉe Verdkomunumo'
    case 'category_approved':
      return 'Via propono estis aprobita'
    case 'category_rejected':
      return 'Via propono estis malakceptita'
  }
}

function notificationSummary(notification: NotificationRecord, actorName: string) {
  switch (notification.type) {
    case 'comment':
      return `<strong>${escapeHtml(actorName)}</strong> komentis vian afiŝon.`
    case 'like':
      return `<strong>${escapeHtml(actorName)}</strong> ŝatis vian afiŝon.`
    case 'follow':
      return `<strong>${escapeHtml(actorName)}</strong> komencis sekvi vin.`
    case 'message':
      return `<strong>${escapeHtml(actorName)}</strong> sendis al vi novan mesaĝon.`
    case 'mention':
      return `<strong>${escapeHtml(actorName)}</strong> menciis vin en afiŝo.`
    case 'category_approved':
      return 'Via kategorio-propono estis aprobita.'
    case 'category_rejected':
      return 'Via kategorio-propono estis malakceptita.'
  }
}

function notificationTextSummary(notification: NotificationRecord, actorName: string) {
  switch (notification.type) {
    case 'comment':
      return `${actorName} komentis vian afiŝon.`
    case 'like':
      return `${actorName} ŝatis vian afiŝon.`
    case 'follow':
      return `${actorName} komencis sekvi vin.`
    case 'message':
      return `${actorName} sendis al vi novan mesaĝon.`
    case 'mention':
      return `${actorName} menciis vin en afiŝo.`
    case 'category_approved':
      return 'Via kategorio-propono estis aprobita.'
    case 'category_rejected':
      return 'Via kategorio-propono estis malakceptita.'
  }
}

function buildEmail(notification: NotificationRecord) {
  const actorName = notification.actor?.display_name ?? 'Iu'
  const snippet = truncate(notification.message?.trim() || '')
  const targetUrl = notificationTargetUrl(notification)
  const settingsUrl = buildSettingsUrl()
  const unsubscribeUrl = buildSettingsUrl({ type: notification.type, unsubscribe: true })
  const heading = notificationHeading(notification.type)
  const actionLabel = notificationActionLabel(notification.type)
  const summaryHtml = notificationSummary(notification, actorName)
  const summaryText = notificationTextSummary(notification, actorName)

  return {
    subject: heading,
    html: `
      <div style="font-family:system-ui,-apple-system,sans-serif;line-height:1.6;color:#111827;">
        <h1 style="font-size:20px;margin:0 0 16px;">${escapeHtml(heading)}</h1>
        <p style="margin:0 0 12px;">${summaryHtml}</p>
        ${snippet ? `<blockquote style="margin:16px 0;padding:12px 16px;border-left:4px solid #16a34a;background:#f0fdf4;color:#14532d;">${escapeHtml(snippet)}</blockquote>` : ''}
        <p style="margin:20px 0 10px;">
          <a href="${targetUrl}" style="display:inline-block;padding:10px 16px;border-radius:10px;background:#16a34a;color:#ffffff;text-decoration:none;font-weight:600;">${escapeHtml(actionLabel)}</a>
        </p>
        <p style="margin:18px 0 0;font-size:13px;color:#4b5563;">
          <a href="${settingsUrl}" style="color:#166534;">Administri retpoŝtajn sciigojn</a>
          &nbsp;•&nbsp;
          <a href="${unsubscribeUrl}" style="color:#166534;">Malaboni ĉi tiun specon</a>
        </p>
      </div>
    `.trim(),
    text: `${summaryText}${snippet ? `\n\n"${snippet}"` : ''}\n\n${actionLabel}: ${targetUrl}\nAdministri retpoŝtajn sciigojn: ${settingsUrl}\nMalaboni ĉi tiun specon: ${unsubscribeUrl}`,
  }
}

async function updateDelivery(deliveryId: string, patch: Record<string, unknown>) {
  const { error } = await supabaseAdmin
    .from('notification_email_deliveries')
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq('id', deliveryId)

  if (error) {
    console.error('Failed to update delivery', deliveryId, error)
  }
}

async function claimQueuedDelivery(deliveryId: string) {
  const { data, error } = await supabaseAdmin
    .from('notification_email_deliveries')
    .update({
      status: 'processing',
      error: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', deliveryId)
    .eq('status', 'queued')
    .select('id, notification_id, user_id, type, status, recipient_email')
    .maybeSingle()

  return { data: data as DeliveryRecord | null, error }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  if (!supabaseUrl || !serviceRoleKey || !resendApiKey || !emailFrom) {
    return json({ error: 'Missing required env vars' }, 500)
  }

  if (!webhookSecret) {
    return json({ error: 'Missing required env vars' }, 500)
  }

  const received = request.headers.get('x-email-webhook-secret')
  if (received !== webhookSecret) {
    return json({ error: 'Unauthorized' }, 401)
  }

  let payload: unknown
  try {
    payload = await request.json()
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400)
  }

  const deliveryId = extractDeliveryId(payload)
  if (!deliveryId) {
    return json({ error: 'Missing delivery_id' }, 400)
  }

  const { data: claimedDelivery, error: claimError } = await claimQueuedDelivery(deliveryId)
  if (claimError) {
    console.error('Failed to claim delivery', deliveryId, claimError)
    return json({ error: 'Failed to claim delivery' }, 500)
  }

  if (!claimedDelivery) {
    const { data: existingDelivery, error: existingDeliveryError } = await supabaseAdmin
      .from('notification_email_deliveries')
      .select('id, status')
      .eq('id', deliveryId)
      .maybeSingle()

    if (existingDeliveryError || !existingDelivery) {
      return json({ error: 'Delivery not found' }, 404)
    }

    return json({
      ok: true,
      skipped: 'already-processed',
      status: existingDelivery.status,
    })
  }

  const currentDelivery = claimedDelivery

  const { data: notification, error: notificationError } = await supabaseAdmin
    .from('notifications')
    .select('id, user_id, actor_id, type, post_id, conversation_id, message, actor:profiles!actor_id(display_name, username), recipient:profiles!user_id(display_name, email_notifications_enabled, email_notify_like, email_notify_comment, email_notify_follow, email_notify_message, email_notify_mention, email_notify_category_approved, email_notify_category_rejected)')
    .eq('id', currentDelivery.notification_id)
    .single()

  if (notificationError || !notification) {
    await updateDelivery(currentDelivery.id, { status: 'failed', error: 'notification_not_found' })
    return json({ error: 'Notification not found' }, 404)
  }

  const currentNotification = notification as unknown as NotificationRecord
  const recipientPrefs = currentNotification.recipient
  const preferenceField = preferenceFields[currentNotification.type]
  const preferenceEnabled =
    recipientPrefs?.email_notifications_enabled !== false &&
    recipientPrefs?.[preferenceField] !== false

  if (!preferenceEnabled) {
    await updateDelivery(currentDelivery.id, { status: 'skipped', error: 'preference_disabled' })
    return json({ ok: true, skipped: 'preference-disabled' })
  }

  const { data: authUser, error: authUserError } = await supabaseAdmin.auth.admin.getUserById(currentDelivery.user_id)
  const recipientEmail = authUser?.user?.email ?? null

  if (authUserError || !recipientEmail) {
    await updateDelivery(currentDelivery.id, { status: 'skipped', error: 'recipient_email_missing' })
    return json({ ok: true, skipped: 'recipient-email-missing' })
  }

  const message = buildEmail(currentNotification)
  const resendResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      authorization: `Bearer ${resendApiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      from: emailFrom,
      to: [recipientEmail],
      subject: message.subject,
      html: message.html,
      text: message.text,
      tags: [{ name: 'notification_type', value: currentNotification.type }],
    }),
  })

  const resendBody = await resendResponse.json().catch(() => ({}))

  if (!resendResponse.ok) {
    await updateDelivery(currentDelivery.id, {
      recipient_email: recipientEmail,
      status: 'failed',
      error: typeof resendBody?.message === 'string' ? resendBody.message : 'resend_request_failed',
    })
    return json({ error: 'Failed to send email', details: resendBody }, 502)
  }

  await updateDelivery(currentDelivery.id, {
    recipient_email: recipientEmail,
    status: 'sent',
    provider_message_id: typeof resendBody?.id === 'string' ? resendBody.id : null,
    error: null,
    sent_at: new Date().toISOString(),
  })

  return json({ ok: true, delivery_id: currentDelivery.id })
})
