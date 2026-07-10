const DEFAULT_ALLOWED_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:5173",
  "http://localhost:8080",
  "https://localhost",
  "http://localhost",
  "capacitor://localhost",
  "ionic://localhost",
];

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

const isLocalhostOrigin = (origin: string) => {
  try {
    const parsed = new URL(origin);
    return parsed.hostname === "localhost" || parsed.hostname === "127.0.0.1";
  } catch (_) {
    return false;
  }
};

export const isAllowedOrigin = (origin?: string | null) => {
  if (!origin || origin === "null") return true;
  if (isLocalhostOrigin(origin)) return true;
  const allowedOrigins = normalizeOriginList();
  return allowedOrigins.includes(origin);
};

const resolveAllowedOrigin = (origin?: string | null) => {
  if (!origin || origin === "null") return DEFAULT_ALLOWED_ORIGINS[0];
  if (isLocalhostOrigin(origin)) return origin;
  return isAllowedOrigin(origin) ? origin : DEFAULT_ALLOWED_ORIGINS[0];
};

export const buildCorsHeaders = (origin?: string | null) => ({
  "Access-Control-Allow-Origin": resolveAllowedOrigin(origin),
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
  Vary: "Origin",
});

export const buildSecurityHeaders = (origin?: string | null) => ({
  ...buildCorsHeaders(origin),
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
  Pragma: "no-cache",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
});

export const jsonSecurityResponse = (
  req: Request,
  body: Record<string, unknown>,
  status = 200,
) =>
  new Response(JSON.stringify(body), {
    status,
    headers: buildSecurityHeaders(req.headers.get("origin")),
  });
