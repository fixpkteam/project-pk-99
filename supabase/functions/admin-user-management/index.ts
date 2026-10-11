import { createClient } from 'jsr:@supabase/supabase-js@2';

const allowedRoles = new Set([
  'admin',
  'operations',
  'estimator',
  'support',
  'content_manager',
]);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return jsonResponse(405, { error: 'method_not_allowed' });

  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return jsonResponse(401, { error: 'authentication_required' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return jsonResponse(500, { error: 'server_configuration_missing' });
  }

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: callerData, error: callerError } = await callerClient.auth.getUser();
  const caller = callerData.user;
  if (callerError || !caller) return jsonResponse(401, { error: 'invalid_session' });

  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: callerRoles, error: roleError } = await adminClient
    .from('user_roles')
    .select('role')
    .eq('user_id', caller.id);
  if (roleError) return jsonResponse(500, { error: 'authorization_check_failed' });
  if (!callerRoles?.some((entry) => entry.role === 'admin')) {
    return jsonResponse(403, { error: 'admin_role_required' });
  }

  let body: Record<string, unknown>;
  try {
    const decoded: unknown = await request.json();
    if (!decoded || typeof decoded !== 'object' || Array.isArray(decoded)) {
      return jsonResponse(400, { error: 'invalid_request' });
    }
    body = decoded as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { error: 'invalid_json' });
  }

  const action = body.action;
  if (action === 'list') {
    const page = Math.max(1, Math.min(100, Number(body.page) || 1));
    const perPage = Math.max(1, Math.min(50, Number(body.perPage) || 50));
    const { data, error } = await adminClient.auth.admin.listUsers({ page, perPage });
    if (error) return jsonResponse(502, { error: 'user_list_unavailable' });
    const userIds = data.users.map((user) => user.id);
    let profiles: Array<{ id: string; full_name: string | null; phone: string | null }> = [];
    let roles: Array<{ user_id: string; role: string }> = [];
    if (userIds.length > 0) {
      const profileResult = await adminClient
        .from('profiles')
        .select('id,full_name,phone')
        .in('id', userIds);
      const roleResult = await adminClient
        .from('user_roles')
        .select('user_id,role')
        .in('user_id', userIds);
      if (profileResult.error || roleResult.error) {
        return jsonResponse(502, { error: 'account_details_unavailable' });
      }
      profiles = profileResult.data ?? [];
      roles = roleResult.data ?? [];
    }
    const profileById = new Map(profiles.map((profile) => [profile.id, profile]));
    const rolesById = new Map<string, string[]>();
    for (const item of roles) {
      const values = rolesById.get(item.user_id) ?? [];
      values.push(item.role);
      rolesById.set(item.user_id, values);
    }
    const users = data.users.map((user) => {
      const profile = profileById.get(user.id);
      return {
        id: user.id,
        email: user.email ?? '',
        user_metadata: {
          ...user.user_metadata,
          ...(profile?.full_name ? { full_name: profile.full_name } : {}),
          ...(profile?.phone ? { phone: profile.phone } : {}),
        },
        roles: rolesById.get(user.id) ?? [],
        banned_until: user.banned_until,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
      };
    });
    return jsonResponse(200, { users, page, perPage, hasMore: users.length === perPage });
  }

  const targetUserId = typeof body.userId === 'string' ? body.userId : '';
  if (!targetUserId || targetUserId.length > 80) {
    return jsonResponse(400, { error: 'valid_user_id_required' });
  }

  if (action === 'set_role') {
    const role = typeof body.role === 'string' ? body.role : '';
    const enabled = body.enabled === true;
    if (!allowedRoles.has(role)) return jsonResponse(400, { error: 'unsupported_role' });
    if (enabled) {
      const result = await adminClient.from('user_roles').upsert(
          { user_id: targetUserId, role },
          { onConflict: 'user_id,role', ignoreDuplicates: true },
        );
      if (result.error) return jsonResponse(502, { error: 'role_update_failed' });
    } else {
      const { data, error } = await adminClient.rpc('fixpk_admin_remove_user_role', {
        p_user_id: targetUserId,
        p_role: role,
      });
      if (error) return jsonResponse(502, { error: 'role_update_failed' });
      if (data !== true) return jsonResponse(409, { error: 'cannot_remove_last_admin' });
    }
    return jsonResponse(200, { ok: true });
  }

  if (action === 'suspend' || action === 'restore') {
    if (targetUserId === caller.id) return jsonResponse(409, { error: 'cannot_suspend_self' });
    const { data: targetRoles, error: targetRoleError } = await adminClient
      .from('user_roles')
      .select('role')
      .eq('user_id', targetUserId);
    if (targetRoleError) return jsonResponse(500, { error: 'target_role_check_failed' });
    if (action === 'suspend' && targetRoles?.some((entry) => entry.role === 'admin')) {
      return jsonResponse(409, { error: 'remove_admin_role_before_suspending' });
    }
    const { error } = await adminClient.auth.admin.updateUserById(targetUserId, {
      ban_duration: action === 'suspend' ? '876000h' : 'none',
    });
    if (error) return jsonResponse(502, { error: 'sign_in_access_update_failed' });
    return jsonResponse(200, { ok: true });
  }

  return jsonResponse(400, { error: 'unsupported_action' });
});
