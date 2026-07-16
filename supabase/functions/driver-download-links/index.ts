import {
  checkRateLimit,
  rateLimitHeaders,
} from "../_shared/rateLimit.ts";

const DEFAULT_ALLOWED_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:5173",
  "http://localhost:8080",
  "https://localhost",
  "http://localhost",
  "capacitor://localhost",
  "ionic://localhost",
  "https://driver.omnyatech.com.br",
  "https://driver-57a.pages.dev",
];

const DEFAULT_MEDIAFIRE_APK_URL =
  "https://www.mediafire.com/file/cehfkctgxvhcqlu/driver-v1.0.17.apk/file";

const isLocalhostOrigin = (origin: string) => {
  try {
    const parsed = new URL(origin);
    return parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1";
  } catch (_) {
    return false;
  }
};

const normalizeOriginList = () => {
  const envOrigins =
    Deno.env.get("DRIVER_ALLOWED_WEB_ORIGINS") ??
      Deno.env.get("ALLOWED_WEB_ORIGINS") ??
      "";

  return Array.from(
    new Set(
      [...DEFAULT_ALLOWED_ORIGINS, ...envOrigins.split(",")]
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  );
};

const isAllowedOrigin = (origin?: string | null) => {
  if (!origin || origin === "null") return true;
  if (isLocalhostOrigin(origin)) return true;
  return normalizeOriginList().includes(origin);
};

const resolveAllowedOrigin = (origin?: string | null) => {
  if (!origin || origin === "null") return DEFAULT_ALLOWED_ORIGINS[0];
  if (isLocalhostOrigin(origin)) return origin;
  return isAllowedOrigin(origin) ? origin : "";
};

const buildHeaders = (origin?: string | null) => ({
  "Access-Control-Allow-Origin": resolveAllowedOrigin(origin),
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
  "Cache-Control": "no-store",
  "Content-Type": "application/json",
  "Referrer-Policy": "no-referrer",
  "Vary": "Origin",
  "X-Content-Type-Options": "nosniff",
});

const json = (
  req: Request,
  body: Record<string, unknown>,
  status = 200,
  headers: Record<string, string> = {},
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      ...buildHeaders(req.headers.get("origin")),
      ...headers,
    },
  });

const readUrl = (key: string) => {
  const value = Deno.env.get(key)?.trim();
  if (!value) return null;

  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:"
      ? url.toString()
      : null;
  } catch (_) {
    return null;
  }
};

Deno.serve((req) => {
  const origin = req.headers.get("origin");

  if (!isAllowedOrigin(origin)) {
    return json(req, { ok: false, message: "Origem nao permitida." }, 403);
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: buildHeaders(origin),
    });
  }

  if (req.method !== "GET" && req.method !== "POST") {
    return json(req, { ok: false, message: "Metodo nao permitido." }, 405);
  }

  const rateLimit = checkRateLimit(req, {
    name: "driver-download-links",
    ipLimit: 120,
    ipWindowMs: 60_000,
    userLimit: 180,
    userWindowMs: 60_000,
    tokenFallback: true,
  });
  if (!rateLimit.allowed) {
    return json(
      req,
      { ok: false, message: "Muitas tentativas. Aguarde e tente novamente." },
      429,
      rateLimitHeaders(rateLimit),
    );
  }

  return json(req, {
    ok: true,
    mediafire_apk_url:
      readUrl("DRIVER_MEDIAFIRE_APK_URL") ?? DEFAULT_MEDIAFIRE_APK_URL,
  });
});
