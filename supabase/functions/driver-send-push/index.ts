import { createClient } from "npm:@supabase/supabase-js@2";

type PushBody = {
  userId?: string | null;
  title?: string | null;
  body?: string | null;
  data?: Record<string, string> | null;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-driver-push-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (payload: unknown, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "X-Content-Type-Options": "nosniff",
    },
  });

const resolveSupabaseAdmin = () => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) return null;

  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
};

const resolveServerKey = () =>
  Deno.env.get("DRIVER_FCM_SERVER_KEY") ?? Deno.env.get("FCM_SERVER_KEY");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ success: false, message: "Metodo nao permitido." }, 405);
  }

  const admin = resolveSupabaseAdmin();
  const serverKey = resolveServerKey();
  if (!admin || !serverKey) {
    return json(
      { success: false, message: "Push nao configurado no servidor." },
      500,
    );
  }

  const body = (await req.json().catch(() => ({}))) as PushBody;
  const title = (body.title ?? "").trim();
  const message = (body.body ?? "").trim();
  if (!title || !message) {
    return json({ success: false, message: "Titulo e mensagem obrigatorios." }, 400);
  }

  const pushSecret = Deno.env.get("DRIVER_PUSH_SECRET");
  const receivedSecret = req.headers.get("x-driver-push-secret");
  const serviceCall =
    pushSecret && receivedSecret && receivedSecret === pushSecret;

  let targetUserId = body.userId ?? null;
  if (!serviceCall) {
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return json({ success: false, message: "Sessao obrigatoria." }, 401);
    }

    const {
      data: { user },
      error,
    } = await admin.auth.getUser(authHeader.replace("Bearer ", ""));

    if (error || !user) {
      return json({ success: false, message: "Sessao invalida." }, 401);
    }

    targetUserId = user.id;
  }

  if (!targetUserId) {
    return json({ success: false, message: "Usuario de destino obrigatorio." }, 400);
  }

  const { data: devices, error } = await admin
    .schema("driver")
    .from("driver_push_devices")
    .select("id, fcm_token")
    .eq("user_id", targetUserId)
    .eq("enabled", true)
    .not("fcm_token", "is", null);

  if (error) {
    return json({ success: false, message: "Falha ao buscar dispositivos." }, 500);
  }

  const tokens = (devices ?? [])
    .map((device) => String(device.fcm_token ?? "").trim())
    .filter((token) => token.length > 0);

  if (tokens.length === 0) {
    return json({ success: true, delivered: 0, message: "Sem dispositivo ativo." });
  }

  const response = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      Authorization: `key=${serverKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      registration_ids: tokens,
      priority: "high",
      notification: {
        title,
        body: message,
      },
      data: body.data ?? {},
    }),
  });

  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    return json(
      {
        success: false,
        message: "FCM recusou o envio.",
        details: result,
      },
      502,
    );
  }

  return json({
    success: true,
    delivered: result.success ?? 0,
    failed: result.failure ?? 0,
  });
});
