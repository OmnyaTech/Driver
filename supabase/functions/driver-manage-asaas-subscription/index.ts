import { createClient } from "npm:@supabase/supabase-js@2";

import {
  buildCorsHeaders,
  isAllowedOrigin,
  jsonSecurityResponse,
} from "../driver-verify-turnstile/securityHeaders.ts";
import { safeLog } from "../driver-verify-turnstile/safeLogger.ts";
import {
  checkRateLimit,
  rateLimitHeaders,
} from "../_shared/rateLimit.ts";

type ManageSubscriptionBody = {
  action?: "cancel" | "change_plan" | null;
  planType?: string | null;
  reason?: string | null;
};

const resolveAsaasBaseUrl = () => {
  const environment = (
    Deno.env.get("DRIVER_ASAAS_ENV") ??
    Deno.env.get("ASAAS_ENV") ??
    "sandbox"
  ).toLowerCase();

  return environment === "production"
    ? "https://api.asaas.com"
    : "https://api-sandbox.asaas.com";
};

const resolveAsaasApiKey = () =>
  Deno.env.get("DRIVER_ASAAS_API_KEY") ??
  Deno.env.get("ASAAS_API_KEY") ??
  null;

const resolveSupabaseAdmin = () => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) return null;

  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
};

const resolveSupabaseUserClient = (authHeader: string) => {
  const url = Deno.env.get("SUPABASE_URL");
  const anonKey =
    Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !anonKey) return null;

  return createClient(url, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });
};

const asaasDelete = async (
  apiKey: string,
  path: string,
): Promise<{ ok: boolean; status: number; data: unknown }> => {
  const response = await fetch(`${resolveAsaasBaseUrl()}${path}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      access_token: apiKey,
    },
  });

  let data: unknown = null;
  try {
    data = await response.json();
  } catch (_) {
    data = null;
  }

  return { ok: response.ok, status: response.status, data };
};

Deno.serve(async (req) => {
  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return jsonSecurityResponse(
      req,
      { success: false, message: "Origem nao permitida." },
      403,
    );
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: buildCorsHeaders(req.headers.get("origin")),
    });
  }

  if (req.method !== "POST") {
    return jsonSecurityResponse(
      req,
      { success: false, message: "Metodo nao permitido." },
      405,
    );
  }

  const preAuthRateLimit = checkRateLimit(req, {
    name: "driver-manage-asaas-subscription-preauth",
    ipLimit: 30,
    ipWindowMs: 60_000,
    userLimit: 40,
    userWindowMs: 60_000,
    tokenFallback: true,
  });
  if (!preAuthRateLimit.allowed) {
    return jsonSecurityResponse(
      req,
      { success: false, message: "Muitas tentativas. Aguarde e tente novamente." },
      429,
      rateLimitHeaders(preAuthRateLimit),
    );
  }

  try {
    const apiKey = resolveAsaasApiKey();
    const admin = resolveSupabaseAdmin();
    const authHeader = req.headers.get("authorization");
    const userClient = authHeader ? resolveSupabaseUserClient(authHeader) : null;

    if (!apiKey || !admin || !authHeader || !userClient) {
      return jsonSecurityResponse(
        req,
        { success: false, message: "Configuracao de assinatura indisponivel." },
        500,
      );
    }

    const {
      data: { user },
      error: userError,
    } = await admin.auth.getUser(authHeader.replace("Bearer ", ""));

    if (userError || !user) {
      return jsonSecurityResponse(
        req,
        { success: false, message: "Sessao invalida para gerenciar assinatura." },
        401,
      );
    }

    const userRateLimit = checkRateLimit(req, {
      name: "driver-manage-asaas-subscription",
      ipLimit: 20,
      ipWindowMs: 60_000,
      userId: user.id,
      userLimit: 8,
      userWindowMs: 60_000,
    });
    if (!userRateLimit.allowed) {
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Muitas tentativas de assinatura. Aguarde e tente novamente.",
        },
        429,
        rateLimitHeaders(userRateLimit),
      );
    }

    const body = (await req.json()) as ManageSubscriptionBody;
    const action = body.action;
    const reason = (body.reason ?? "").trim();

    if (action !== "cancel" && action !== "change_plan") {
      return jsonSecurityResponse(
        req,
        { success: false, message: "Acao de assinatura nao suportada." },
        400,
      );
    }

    const { data: subscriptions, error: subscriptionError } = await admin
      .schema("driver")
      .from("subscriptions")
      .select(
        "id, plan_type, status, provider_subscription_id, external_reference, expires_at",
      )
      .eq("user_id", user.id)
      .is("cancelled_at", null)
      .in("status", ["pending", "active", "overdue", "gifted"])
      .order("updated_at", { ascending: false })
      .limit(1);

    if (subscriptionError) throw subscriptionError;

    const subscription = Array.isArray(subscriptions)
      ? subscriptions[0]
      : null;

    if (!subscription) {
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Nenhuma assinatura ativa ou pendente foi encontrada.",
        },
        404,
      );
    }

    if (action === "cancel") {
      let asaasResult: Record<string, unknown> = {
        attempted: false,
        ok: false,
      };

      const providerSubscriptionId = subscription.provider_subscription_id;
      if (providerSubscriptionId) {
        const subscriptionCancel = await asaasDelete(
          apiKey,
          `/v3/subscriptions/${providerSubscriptionId}`,
        );
        let finalCancel = subscriptionCancel;

        if (!subscriptionCancel.ok) {
          finalCancel = await asaasDelete(
            apiKey,
            `/v3/paymentLinks/${providerSubscriptionId}`,
          );
        }

        asaasResult = {
          attempted: true,
          ok: finalCancel.ok,
          status: finalCancel.status,
        };
      }

      const { data, error } = await userClient
        .schema("driver")
        .rpc("request_subscription_cancellation", {
          p_reason: reason.length > 0 ? reason : null,
        });

      if (error) throw error;

      safeLog("[driver-manage-asaas-subscription]", {
        action,
        userId: user.id,
        subscriptionId: subscription.id,
        asaasResult,
      });

      return jsonSecurityResponse(req, {
        success: true,
        action,
        asaas: asaasResult,
        result: data,
      });
    }

    const planType = (body.planType ?? "").trim().toLowerCase();
    if (planType !== "premium" && planType !== "free") {
      return jsonSecurityResponse(
        req,
        { success: false, message: "Plano de troca nao suportado." },
        400,
      );
    }

    const { data, error } = await userClient
      .schema("driver")
      .rpc("request_subscription_plan_change", {
        p_plan_type: planType,
      });

    if (error) throw error;

    safeLog("[driver-manage-asaas-subscription]", {
      action,
      userId: user.id,
      subscriptionId: subscription.id,
      planType,
      startsAt: subscription.expires_at,
    });

    return jsonSecurityResponse(req, {
      success: true,
      action,
      result: data,
      message:
        "A troca ficou agendada para a proxima renovacao. Se precisar cobrar agora, gere um novo checkout.",
    });
  } catch (error) {
    safeLog("[driver-manage-asaas-subscription:error]", {
      message: error instanceof Error ? error.message : String(error),
    });

    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Nao foi possivel atualizar a assinatura agora.",
      },
      500,
    );
  }
});
