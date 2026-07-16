import {
  isDevelopmentLike,
  normalizeTurnstileAction,
  normalizeTurnstileProvider,
  resolveTurnstileSecret,
  resolveTurnstileToken,
  type VerifyTurnstileBody,
} from "./contract.ts";
import {
  buildCorsHeaders,
  isAllowedOrigin,
  jsonSecurityResponse,
} from "./securityHeaders.ts";
import { safeLog } from "./safeLogger.ts";
import {
  checkRateLimit,
  rateLimitHeaders,
} from "../_shared/rateLimit.ts";

Deno.serve(async (req) => {
  if (!isAllowedOrigin(req.headers.get("origin"))) {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        code: "network_error",
        message: "Origem nao permitida.",
      },
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
      {
        success: false,
        code: "network_error",
        message: "Metodo nao permitido.",
      },
      405,
    );
  }

  const rateLimit = checkRateLimit(req, {
    name: "driver-verify-turnstile",
    ipLimit: 20,
    ipWindowMs: 60_000,
    userLimit: 30,
    userWindowMs: 60_000,
    tokenFallback: true,
  });
  if (!rateLimit.allowed) {
    return jsonSecurityResponse(
      req,
      {
        success: false,
        code: "rate_limited",
        message: "Muitas tentativas em pouco tempo. Aguarde e tente novamente.",
      },
      429,
      rateLimitHeaders(rateLimit),
    );
  }

  let action = "login";
  let provider: string | null = null;

  try {
    const body = (await req.json()) as VerifyTurnstileBody;
    const token = resolveTurnstileToken(body);
    action = normalizeTurnstileAction(body?.action);
    provider = normalizeTurnstileProvider(body?.provider);

    if (!token) {
      safeLog("[driver-verify-turnstile]", {
        action,
        provider,
        success: false,
        code: "missing_token",
        timestamp: new Date().toISOString(),
      });
      return jsonSecurityResponse(
        req,
        {
          success: false,
          code: "missing_token",
          message: "Token de seguranca ausente.",
        },
        400,
      );
    }

    const secret = resolveTurnstileSecret(Deno.env);
    if (!secret) {
      safeLog("[driver-verify-turnstile]", {
        action,
        provider,
        success: false,
        code: "missing_secret",
        timestamp: new Date().toISOString(),
      });
      return jsonSecurityResponse(
        req,
        {
          success: false,
          code: "missing_secret",
          message: "Configuracao de seguranca indisponivel.",
        },
        500,
      );
    }

    const response = await fetch(
      "https://challenges.cloudflare.com/turnstile/v0/siteverify",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          secret,
          response: token,
        }),
      },
    );

    const data = await response.json();
    const success = Boolean(data?.success);
    const errorCodes = Array.isArray(data?.["error-codes"])
      ? data["error-codes"].filter(
          (value: unknown): value is string => typeof value === "string",
        )
      : [];

    if (!success) {
      safeLog("[driver-verify-turnstile]", {
        action,
        provider,
        success: false,
        code: "turnstile_failed",
        errorCodes,
        timestamp: new Date().toISOString(),
      });
      return jsonSecurityResponse(
        req,
        {
          success: false,
          code: "turnstile_failed",
          message: "Verificacao de seguranca falhou.",
          errorCodes,
          ...(isDevelopmentLike(Deno.env) ? { details: errorCodes } : {}),
        },
        400,
      );
    }

    safeLog("[driver-verify-turnstile]", {
      action,
      provider,
      success: true,
      errorCodes,
      timestamp: new Date().toISOString(),
    });
    return jsonSecurityResponse(
      req,
      {
        success: true,
        errorCodes,
      },
      200,
    );
  } catch (error) {
    const details = error instanceof Error ? [error.message] : [];
    safeLog("[driver-verify-turnstile]", {
      action,
      provider,
      success: false,
      code: "network_error",
      timestamp: new Date().toISOString(),
    });
    return jsonSecurityResponse(
      req,
      {
        success: false,
        code: "network_error",
        message: "Nao foi possivel validar a seguranca agora. Tente novamente.",
        ...(isDevelopmentLike(Deno.env) ? { details } : {}),
      },
      400,
    );
  }
});
