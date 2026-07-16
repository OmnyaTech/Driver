import { createClient } from "npm:@supabase/supabase-js@2";

import {
  buildCorsHeaders,
  jsonSecurityResponse,
} from "../driver-verify-turnstile/securityHeaders.ts";
import { safeLog } from "../driver-verify-turnstile/safeLogger.ts";
import {
  checkRateLimit,
  rateLimitHeaders,
} from "../_shared/rateLimit.ts";

type AsaasWebhookPayload = {
  event?: string;
  payment?: Record<string, unknown> | null;
  subscription?: Record<string, unknown> | null;
};

const resolveSupabaseAdmin = () => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) return null;

  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
};

const resolveWebhookToken = () =>
  Deno.env.get("DRIVER_ASAAS_WEBHOOK_TOKEN") ??
  Deno.env.get("ASAAS_WEBHOOK_TOKEN") ??
  null;

const parseUserIdFromReference = (reference?: string | null) => {
  if (!reference) return null;
  const parts = reference.split(":");
  return parts.length >= 5 && parts[0] === "driver" ? parts[1] : null;
};

const parsePlanFromReference = (reference?: string | null) => {
  if (!reference) return null;
  const parts = reference.split(":");
  return parts.length >= 5 && parts[0] === "driver" ? parts[2] : null;
};

const mapEventToStatus = (eventType: string) => {
  if (["PAYMENT_RECEIVED", "PAYMENT_CONFIRMED"].includes(eventType)) {
    return "active";
  }

  if (
    ["PAYMENT_CREATED", "SUBSCRIPTION_CREATED", "SUBSCRIPTION_UPDATED"].includes(
      eventType,
    )
  ) {
    return "pending";
  }

  if (["PAYMENT_OVERDUE"].includes(eventType)) {
    return "overdue";
  }

  if (
    ["SUBSCRIPTION_INACTIVATED", "SUBSCRIPTION_DELETED", "PAYMENT_DELETED"].includes(
      eventType,
    )
  ) {
    return "inactive";
  }

  return null;
};

const mapPlanType = (planType?: string | null) => {
  return "premium";
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: buildCorsHeaders(req.headers.get("origin")),
    });
  }

  if (req.method !== "POST") {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Metodo nao permitido.",
      },
      405,
    );
  }

  const rateLimit = checkRateLimit(req, {
    name: "driver-asaas-webhook",
    ipLimit: 300,
    ipWindowMs: 60_000,
  });
  if (!rateLimit.allowed) {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Muitas chamadas de webhook em pouco tempo.",
      },
      429,
      rateLimitHeaders(rateLimit),
    );
  }

  try {
    const admin = resolveSupabaseAdmin();
    if (!admin) {
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Configuracao administrativa indisponivel.",
        },
        500,
      );
    }

    const webhookToken = resolveWebhookToken();
    if (webhookToken) {
      const providedToken =
        req.headers.get("asaas-access-token") ??
        req.headers.get("x-asaas-access-token");
      if (providedToken !== webhookToken) {
        return jsonSecurityResponse(
          req,
          {
            success: false,
            message: "Webhook token invalido.",
          },
          401,
        );
      }
    }

    const payload = (await req.json()) as AsaasWebhookPayload;
    const eventType = (payload.event ?? "unknown").toString();
    const payment = payload.payment ?? {};
    const subscription = payload.subscription ?? {};
    const paymentReference = payment["externalReference"]?.toString() ?? null;
    const subscriptionReference =
      subscription["externalReference"]?.toString() ?? null;
    const externalReference = paymentReference ?? subscriptionReference;
    const userId = parseUserIdFromReference(externalReference);
    const planType = mapPlanType(parsePlanFromReference(externalReference));
    const mappedStatus = mapEventToStatus(eventType);
    const providerObjectId =
      payment["id"]?.toString() ?? subscription["id"]?.toString() ?? null;
    const customerId =
      payment["customer"]?.toString() ?? subscription["customer"]?.toString() ??
      null;
    const providerSubscriptionId =
      payment["subscription"]?.toString() ??
      subscription["id"]?.toString() ??
      null;
    const dueDateRaw =
      payment["dueDate"]?.toString() ?? subscription["nextDueDate"]?.toString() ??
      null;
    const expiresAt = dueDateRaw ? new Date(`${dueDateRaw}T23:59:59Z`) : null;

    await admin.schema("driver").rpc("record_billing_event", {
      p_provider: "asaas",
      p_event_type: eventType,
      p_provider_object_id: providerObjectId,
      p_external_reference: externalReference,
      p_user_id: userId,
      p_status: mappedStatus,
      p_payload: payload,
    });

    if (userId && mappedStatus && planType) {
      await admin.schema("driver").rpc("apply_billing_subscription_state", {
        p_user_id: userId,
        p_plan_type: planType,
        p_status: mappedStatus,
        p_provider: "asaas",
        p_provider_customer_id: customerId,
        p_provider_subscription_id: providerSubscriptionId,
        p_current_period_end: expiresAt?.toISOString() ?? null,
        p_payload: payload,
        p_external_reference: externalReference,
      });
    }

    safeLog("[driver-asaas-webhook]", {
      success: true,
      eventType,
      userId,
      providerObjectId,
      timestamp: new Date().toISOString(),
    });

    return jsonSecurityResponse(req, { success: true }, 200);
  } catch (error) {
    safeLog("[driver-asaas-webhook]", {
      success: false,
      timestamp: new Date().toISOString(),
    });
    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Falha ao processar webhook do Asaas.",
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
