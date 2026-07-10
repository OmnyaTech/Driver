export type TurnstileAction = "login" | "register" | "oauth";
export type TurnstileProvider = "google" | "microsoft" | null;

export type VerifyTurnstileBody = {
  token?: string | null;
  turnstileToken?: string | null;
  captchaToken?: string | null;
  action?: TurnstileAction | string | null;
  provider?: TurnstileProvider | string | null;
};

export type VerifyTurnstileResponse = {
  success: boolean;
  code?: "missing_token" | "missing_secret" | "turnstile_failed" | "network_error";
  message?: string;
  errorCodes?: string[];
  details?: string[];
};

const ALLOWED_ACTIONS = new Set<TurnstileAction>([
  "login",
  "register",
  "oauth",
]);
const ALLOWED_PROVIDERS = new Set<Exclude<TurnstileProvider, null>>([
  "google",
  "microsoft",
]);

export const resolveTurnstileToken = (
  body: VerifyTurnstileBody | null | undefined,
) => {
  const candidates = [body?.token, body?.turnstileToken, body?.captchaToken];
  return candidates.find(
    (value) => typeof value === "string" && value.trim().length > 0,
  )?.trim() ?? null;
};

export const normalizeTurnstileAction = (
  value: VerifyTurnstileBody["action"],
): TurnstileAction =>
  ALLOWED_ACTIONS.has(value as TurnstileAction)
    ? (value as TurnstileAction)
    : "login";

export const normalizeTurnstileProvider = (
  value: VerifyTurnstileBody["provider"],
): TurnstileProvider => {
  if (value === "azure") return "microsoft";
  return ALLOWED_PROVIDERS.has(value as Exclude<TurnstileProvider, null>)
    ? (value as Exclude<TurnstileProvider, null>)
    : null;
};

export const resolveTurnstileSecret = (env: {
  get(name: string): string | undefined;
}) =>
  env.get("DRIVER_CLOUDFLARE_TURNSTILE_SECRET_KEY") ??
  env.get("DRIVER_TURNSTILE_SECRET_KEY") ??
  env.get("CLOUDFLARE_TURNSTILE_SECRET_KEY") ??
  env.get("TURNSTILE_SECRET_KEY") ??
  null;

export const isDevelopmentLike = (env: {
  get(name: string): string | undefined;
}) => {
  const mode = env.get("ENVIRONMENT") ?? env.get("NODE_ENV") ?? "";
  return mode === "development" || mode === "local" || mode === "test";
};
