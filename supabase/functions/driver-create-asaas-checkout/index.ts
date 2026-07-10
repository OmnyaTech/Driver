import { createClient } from "npm:@supabase/supabase-js@2";

import {
  buildCorsHeaders,
  isAllowedOrigin,
  jsonSecurityResponse,
} from "../driver-verify-turnstile/securityHeaders.ts";
import { safeLog } from "../driver-verify-turnstile/safeLogger.ts";

type CheckoutBody = {
  planType?: string | null;
  billingCycle?: string | null;
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

const resolvePrice = (planType: string, billingCycle: string) => {
  const key = `${planType}:${billingCycle}`;

  switch (key) {
    case "premium:MONTHLY":
      return Number(
        Deno.env.get("DRIVER_PREMIUM_MONTHLY_PRICE") ?? "29.90",
      );
    case "premium:YEARLY":
      return Number(
        Deno.env.get("DRIVER_PREMIUM_YEARLY_PRICE") ?? "299.90",
      );
    case "lifetime:ONCE":
      return Number(Deno.env.get("DRIVER_LIFETIME_PRICE") ?? "799.90");
    default:
      return null;
  }
};

const buildPaymentLinkPayload = (
  planType: string,
  billingCycle: string,
  value: number,
  externalReference: string,
  successUrl: string,
) => {
  if (planType === "premium") {
    return {
      name: `Omnya Driver ${billingCycle === "YEARLY" ? "Premium Anual" : "Premium Mensal"}`,
      description: "Plano pago do Omnya Driver.",
      value,
      billingType: "CREDIT_CARD",
      chargeType: "RECURRENT",
      subscriptionCycle: billingCycle,
      externalReference,
      callback: {
        successUrl,
        autoRedirect: false,
      },
      notificationEnabled: true,
    };
  }

  return {
    name: "Omnya Driver Lifetime",
    description: "Acesso vitalicio do Omnya Driver.",
    value,
    billingType: "UNDEFINED",
    chargeType: "DETACHED",
    dueDateLimitDays: 3,
    externalReference,
    callback: {
      successUrl,
      autoRedirect: false,
    },
    notificationEnabled: true,
  };
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: buildCorsHeaders(req.headers.get("origin")),
    });
  }

  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Origem nao permitida.",
      },
      403,
    );
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

  try {
    const apiKey = resolveAsaasApiKey();
    const admin = resolveSupabaseAdmin();
    const authHeader = req.headers.get("authorization");

    if (!apiKey || !admin || !authHeader) {
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Configuracao de billing indisponivel.",
        },
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
        {
          success: false,
          message: "Sessao invalida para iniciar o checkout.",
        },
        401,
      );
    }

    const body = (await req.json()) as CheckoutBody;
    const planType = (body.planType ?? "").trim().toLowerCase();
    const billingCycle = (body.billingCycle ?? "").trim().toUpperCase();
    const value = resolvePrice(planType, billingCycle);

    if (!value || !["premium", "lifetime"].includes(planType)) {
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Plano de checkout nao suportado.",
        },
        400,
      );
    }

    const successUrl =
      Deno.env.get("DRIVER_BILLING_SUCCESS_URL") ??
      Deno.env.get("BILLING_SUCCESS_URL") ??
      `${req.headers.get("origin") ?? "http://localhost:5173"}/`;
    const externalReference =
      `driver:${user.id}:${planType}:${billingCycle}:${Date.now()}`;
    const payload = buildPaymentLinkPayload(
      planType,
      billingCycle,
      value,
      externalReference,
      successUrl,
    );

    const asaasResponse = await fetch(`${resolveAsaasBaseUrl()}/v3/paymentLinks`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        access_token: apiKey,
      },
      body: JSON.stringify(payload),
    });

    const asaasData = await asaasResponse.json();
    if (!asaasResponse.ok) {
      safeLog("[driver-create-asaas-checkout]", {
        success: false,
        userId: user.id,
        planType,
        billingCycle,
        timestamp: new Date().toISOString(),
      });
      return jsonSecurityResponse(
        req,
        {
          success: false,
          message: "Nao foi possivel criar o checkout no Asaas.",
          details: asaasData,
        },
        400,
      );
    }

    await admin.schema("driver").rpc("record_billing_event", {
      p_provider: "asaas",
      p_event_type: "checkout_created",
      p_provider_object_id: asaasData.id ?? null,
      p_external_reference: externalReference,
      p_user_id: user.id,
      p_status: "created",
      p_payload: asaasData,
    });

    return jsonSecurityResponse(
      req,
      {
        success: true,
        provider: "asaas",
        planType,
        billingCycle,
        externalReference,
        url: asaasData.url,
      },
      200,
    );
  } catch (error) {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        message: "Falha inesperada ao criar o checkout.",
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
