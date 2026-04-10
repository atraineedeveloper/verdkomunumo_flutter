import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8'

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'content-type': 'application/json; charset=utf-8',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders,
  })
}

function looksLikeEmail(value: string) {
  return EMAIL_PATTERN.test(value.trim())
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    return json({ error: 'Missing required env vars' }, 500)
  }

  let payload: unknown
  try {
    payload = await request.json()
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400)
  }

  const record = payload && typeof payload === 'object' ? payload as Record<string, unknown> : null
  const identifier = typeof record?.identifier === 'string' ? record.identifier.trim() : ''
  const password = typeof record?.password === 'string' ? record.password : ''

  if (!identifier || !password) {
    return json({ error: 'Missing credentials' }, 400)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })

  let email = identifier
  if (looksLikeEmail(identifier)) {
    email = identifier.toLowerCase()
  } else {
    const { data, error } = await adminClient.rpc('resolve_login_email', {
      login_identifier: identifier,
    })

    if (error || !data || typeof data !== 'string') {
      return json({ error: 'Invalid login credentials' }, 401)
    }

    email = data
  }

  const { data, error } = await authClient.auth.signInWithPassword({
    email,
    password,
  })

  if (error || !data.session) {
    return json({ error: 'Invalid login credentials' }, 401)
  }

  return json({
    session: {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    },
  })
})
