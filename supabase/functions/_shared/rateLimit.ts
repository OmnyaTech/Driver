type RateLimitRule = {
  key: string;
  limit: number;
  windowMs: number;
};

type RateLimitEntry = {
  count: number;
  resetAt: number;
};

export type RateLimitResult = {
  allowed: boolean;
  limit: number;
  remaining: number;
  resetAt: number;
  retryAfterSeconds: number;
  scope: string;
};

const buckets = new Map<string, RateLimitEntry>();
let lastSweepAt = 0;

const normalizeIdentifier = (value?: string | null) =>
  (value ?? "unknown").trim().toLowerCase().replace(/[^a-z0-9:._@-]/g, "_");

export const getClientIp = (req: Request) => {
  const forwardedFor = req.headers.get("x-forwarded-for");
  const firstForwarded = forwardedFor?.split(",")[0]?.trim();
  return (
    firstForwarded ||
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-real-ip") ||
    "unknown"
  );
};

export const getBearerToken = (req: Request) => {
  const authHeader = req.headers.get("authorization") ?? "";
  return authHeader.replace(/^Bearer\s+/i, "").trim();
};

export const fingerprintToken = (token?: string | null) => {
  const value = token?.trim();
  if (!value) return null;

  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = (hash * 31 + value.charCodeAt(index)) >>> 0;
  }
  return hash.toString(16);
};

const consumeRule = (
  scope: string,
  rule: RateLimitRule,
  now: number,
): RateLimitResult => {
  if (now - lastSweepAt > 60_000) {
    lastSweepAt = now;
    for (const [key, entry] of buckets.entries()) {
      if (entry.resetAt <= now) {
        buckets.delete(key);
      }
    }
  }

  const bucketKey = `${scope}:${rule.key}`;
  const current = buckets.get(bucketKey);
  const entry =
    current && current.resetAt > now
      ? current
      : { count: 0, resetAt: now + rule.windowMs };

  entry.count += 1;
  buckets.set(bucketKey, entry);

  const remaining = Math.max(rule.limit - entry.count, 0);
  return {
    allowed: entry.count <= rule.limit,
    limit: rule.limit,
    remaining,
    resetAt: entry.resetAt,
    retryAfterSeconds: Math.max(Math.ceil((entry.resetAt - now) / 1000), 1),
    scope,
  };
};

export const checkRateLimit = (
  req: Request,
  {
    name,
    ipLimit,
    ipWindowMs,
    userId,
    userLimit,
    userWindowMs,
    tokenFallback = false,
  }: {
    name: string;
    ipLimit: number;
    ipWindowMs: number;
    userId?: string | null;
    userLimit?: number;
    userWindowMs?: number;
    tokenFallback?: boolean;
  },
) => {
  const now = Date.now();
  const ipKey = normalizeIdentifier(getClientIp(req));
  const results = [
    consumeRule("ip", {
      key: `${name}:${ipKey}`,
      limit: ipLimit,
      windowMs: ipWindowMs,
    }, now),
  ];

  const resolvedUserId =
    userId ?? (tokenFallback ? fingerprintToken(getBearerToken(req)) : null);
  if (resolvedUserId && userLimit && userWindowMs) {
    results.push(
      consumeRule("user", {
        key: `${name}:${normalizeIdentifier(resolvedUserId)}`,
        limit: userLimit,
        windowMs: userWindowMs,
      }, now),
    );
  }

  return results.find((result) => !result.allowed) ??
    results[results.length - 1];
};

export const rateLimitHeaders = (result: RateLimitResult) => ({
  "Retry-After": String(result.retryAfterSeconds),
  "X-RateLimit-Limit": String(result.limit),
  "X-RateLimit-Remaining": String(result.remaining),
  "X-RateLimit-Reset": String(Math.ceil(result.resetAt / 1000)),
  "X-RateLimit-Scope": result.scope,
});
