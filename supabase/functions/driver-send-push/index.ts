import { createClient } from "npm:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

type PushBody = {
  jobId?: string | null;
  limit?: number | null;
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
  Deno.env.get("DRIVER_FCM_SERVER_KEY") ?? Deno.env.get("FCM_SERVER_KEY") ??
  null;

const resolveFirebaseServiceAccount = () => {
  const raw =
    Deno.env.get("DRIVER_FIREBASE_SERVICE_ACCOUNT_JSON") ??
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ??
    Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!raw) return null;

  try {
    return JSON.parse(raw) as {
      client_email?: string;
      private_key?: string;
      project_id?: string;
    };
  } catch {
    return null;
  }
};

const resolveFirebaseProjectId = (
  serviceAccount: { project_id?: string } | null,
) =>
  Deno.env.get("DRIVER_FIREBASE_PROJECT_ID") ??
  Deno.env.get("FIREBASE_PROJECT_ID") ??
  serviceAccount?.project_id ??
  null;

const stringifyData = (data: Record<string, unknown> | null | undefined) =>
  Object.fromEntries(
    Object.entries(data ?? {}).map(([key, value]) => [key, String(value)]),
  );

const markJob = async (
  admin: ReturnType<typeof createClient>,
  jobId: string,
  status: "sent" | "failed",
  failureReason: string | null = null,
) => {
  await admin
    .schema("driver")
    .from("driver_push_jobs")
    .update({
      status,
      sent_at: status === "sent" ? new Date().toISOString() : null,
      failed_at: status === "failed" ? new Date().toISOString() : null,
      failure_reason: failureReason,
      updated_at: new Date().toISOString(),
    })
    .eq("id", jobId);
};

const findNotificationState = async (
  admin: ReturnType<typeof createClient>,
  userId: string,
  notificationKey: string | null | undefined,
) => {
  const key = String(notificationKey ?? "").trim();
  if (!key) return null;

  const { data } = await admin
    .schema("driver")
    .from("driver_notifications")
    .select("read_at, delivered_at")
    .eq("user_id", userId)
    .eq("notification_key", key)
    .maybeSingle();

  return data as { read_at?: string | null; delivered_at?: string | null } | null;
};

const markNotificationDelivered = async (
  admin: ReturnType<typeof createClient>,
  userId: string,
  notificationKey: string | null | undefined,
) => {
  const key = String(notificationKey ?? "").trim();
  if (!key) return;

  await admin
    .schema("driver")
    .from("driver_notifications")
    .update({
      delivered_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("user_id", userId)
    .eq("notification_key", key)
    .is("read_at", null)
    .is("delivered_at", null);
};

const sendToUser = async ({
  admin,
  serverKey,
  serviceAccount,
  projectId,
  userId,
  title,
  message,
  data,
}: {
  admin: ReturnType<typeof createClient>;
  serverKey: string | null;
  serviceAccount: {
    client_email?: string;
    private_key?: string;
    project_id?: string;
  } | null;
  projectId: string | null;
  userId: string;
  title: string;
  message: string;
  data: Record<string, string>;
}) => {
  const { data: devices, error } = await admin
    .schema("driver")
    .from("driver_push_devices")
    .select("id, fcm_token")
    .eq("user_id", userId)
    .eq("enabled", true)
    .not("fcm_token", "is", null);

  if (error) {
    return {
      ok: false,
      delivered: 0,
      failed: 0,
      message: "Falha ao buscar dispositivos.",
      status: 500,
    };
  }

  const tokens = (devices ?? [])
    .map((device) => String(device.fcm_token ?? "").trim())
    .filter((token) => token.length > 0);

  if (tokens.length === 0) {
    return {
      ok: true,
      delivered: 0,
      failed: 0,
      message: "Sem dispositivo ativo.",
      status: 200,
    };
  }

  if (serviceAccount?.client_email && serviceAccount.private_key && projectId) {
    const authClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const access = await authClient.authorize();
    const accessToken = access.access_token;
    if (!accessToken) {
      return {
        ok: false,
        delivered: 0,
        failed: tokens.length,
        message: "Nao foi possivel autenticar no Firebase HTTP v1.",
        status: 502,
      };
    }

    let delivered = 0;
    let failed = 0;
    const details = [];
    for (const token of tokens) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body: message },
              data,
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: "omnya_driver_alerts",
                  notification_priority: "PRIORITY_HIGH",
                  visibility: "PUBLIC",
                },
              },
            },
          }),
        },
      );
      const result = await response.json().catch(() => ({}));
      details.push(result);
      if (response.ok) {
        delivered += 1;
      } else {
        failed += 1;
      }
    }

    return {
      ok: delivered > 0 || failed === 0,
      delivered,
      failed,
      message: delivered > 0 ? "Push enviado." : "FCM recusou o envio.",
      status: delivered > 0 ? 200 : 502,
      details,
    };
  }

  if (!serverKey) {
    return {
      ok: false,
      delivered: 0,
      failed: tokens.length,
      message: "Firebase nao configurado no servidor.",
      status: 500,
    };
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
      data,
    }),
  });

  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    return {
      ok: false,
      delivered: 0,
      failed: tokens.length,
      message: "FCM recusou o envio.",
      status: 502,
      details: result,
    };
  }

  return {
    ok: true,
    delivered: Number(result.success ?? 0),
    failed: Number(result.failure ?? 0),
    message: "Push enviado.",
    status: 200,
    details: result,
  };
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ success: false, message: "Metodo nao permitido." }, 405);
  }

  const admin = resolveSupabaseAdmin();
  const serverKey = resolveServerKey();
  const serviceAccount = resolveFirebaseServiceAccount();
  const projectId = resolveFirebaseProjectId(serviceAccount);
  if (!admin || (!serverKey && !serviceAccount)) {
    return json(
      { success: false, message: "Push nao configurado no servidor." },
      500,
    );
  }

  const pushSecret = Deno.env.get("DRIVER_PUSH_SECRET");
  const receivedSecret = req.headers.get("x-driver-push-secret");
  const serviceCall =
    pushSecret && receivedSecret && receivedSecret === pushSecret;

  const body = (await req.json().catch(() => ({}))) as PushBody;
  let targetUserId = body.userId ?? null;
  let title = (body.title ?? "").trim();
  let message = (body.body ?? "").trim();
  let payloadData = stringifyData(body.data);
  const jobId = (body.jobId ?? "").trim();
  let jobNotificationKey: string | null = null;

  if (!jobId && serviceCall && !targetUserId && !title && !message) {
    const limit = Math.min(Math.max(Number(body.limit ?? 25), 1), 100);
    await admin
      .schema("driver")
      .rpc("enqueue_operational_push_jobs")
      .catch(() => null);

    const { data: jobs, error: jobsError } = await admin
      .schema("driver")
      .from("driver_push_jobs")
      .select("id, user_id, notification_key, title, body, payload")
      .eq("status", "queued")
      .lte("scheduled_at", new Date().toISOString())
      .order("scheduled_at", { ascending: true })
      .limit(limit);

    if (jobsError) {
      return json({ success: false, message: "Falha ao buscar fila de push." }, 500);
    }

    const results = [];
    for (const job of jobs ?? []) {
      const notificationKey = String(job.notification_key ?? "");
      const notificationState = await findNotificationState(
        admin,
        String(job.user_id),
        notificationKey,
      );
      if (notificationState?.read_at || notificationState?.delivered_at) {
        await markJob(admin, String(job.id), "sent");
        results.push({
          jobId: job.id,
          delivered: 0,
          failed: 0,
          ok: true,
          skipped: "notification_already_handled",
        });
        continue;
      }

      const result = await sendToUser({
        admin,
        serverKey,
        serviceAccount,
        projectId,
        userId: String(job.user_id),
        title: String(job.title ?? "").trim(),
        message: String(job.body ?? "").trim(),
        data: stringifyData(job.payload as Record<string, unknown> | null),
      });

      await markJob(
        admin,
        String(job.id),
        result.ok ? "sent" : "failed",
        result.ok ? null : result.message,
      );
      if (result.ok && result.delivered > 0) {
        await markNotificationDelivered(
          admin,
          String(job.user_id),
          notificationKey,
        );
      }

      results.push({
        jobId: job.id,
        delivered: result.delivered,
        failed: result.failed,
        ok: result.ok,
      });
    }

    return json({
      success: true,
      processed: results.length,
      results,
    });
  }

  if (jobId) {
    if (!serviceCall) {
      return json({ success: false, message: "Chave de push obrigatoria." }, 401);
    }

    const { data: job, error: jobError } = await admin
      .schema("driver")
      .from("driver_push_jobs")
      .select("id, user_id, notification_key, title, body, payload, status")
      .eq("id", jobId)
      .maybeSingle();

    if (jobError || !job) {
      return json({ success: false, message: "Job de push nao encontrado." }, 404);
    }

    if (job.status !== "queued") {
      return json({ success: true, delivered: 0, message: "Job ja processado." });
    }

    targetUserId = String(job.user_id);
    title = String(job.title ?? "").trim();
    message = String(job.body ?? "").trim();
    payloadData = stringifyData(job.payload as Record<string, unknown> | null);
    jobNotificationKey = String(job.notification_key ?? "");
    const notificationState = await findNotificationState(
      admin,
      targetUserId,
      jobNotificationKey,
    );
    if (notificationState?.read_at || notificationState?.delivered_at) {
      await markJob(admin, jobId, "sent");
      return json({
        success: true,
        delivered: 0,
        message: "Aviso ja lido ou entregue.",
      });
    }
  }

  if (!title || !message) {
    return json({ success: false, message: "Titulo e mensagem obrigatorios." }, 400);
  }

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

  const result = await sendToUser({
    admin,
    serverKey,
    serviceAccount,
    projectId,
    userId: targetUserId,
    title,
    message,
    data: payloadData,
  });

  if (result.message === "Sem dispositivo ativo.") {
    if (jobId) {
      await markJob(admin, jobId, "failed", "Sem dispositivo ativo.");
    }
    return json({ success: true, delivered: 0, message: "Sem dispositivo ativo." });
  }

  if (!result.ok) {
    if (jobId) {
      await markJob(admin, jobId, "failed", result.message);
    }
    return json(
      {
        success: false,
        message: result.message,
        details: result.details,
      },
      result.status,
    );
  }

  if (jobId) {
    await markJob(admin, jobId, "sent");
    if (result.delivered > 0) {
      await markNotificationDelivered(admin, targetUserId, jobNotificationKey);
    }
  }

  return json({
    success: true,
    delivered: result.delivered,
    failed: result.failed,
  });
});
