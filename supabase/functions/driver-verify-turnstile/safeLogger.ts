const SENSITIVE_KEY =
  /authorization|apikey|api_key|token|secret|password|senha|cpf|email|phone|telefone|certificate|private_?key|client_?secret|authorization_?code/i;

const maskString = (value: string) => {
  if (!value) return value;
  if (value.length <= 6) return "[redacted]";
  return `${value.slice(0, 2)}***${value.slice(-2)}`;
};

const sanitizeValue = (value: unknown): unknown => {
  if (value == null) return value;
  if (Array.isArray(value)) return value.map(sanitizeValue);
  if (typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, nested]) => [
        key,
        SENSITIVE_KEY.test(key) ? "[redacted]" : sanitizeValue(nested),
      ]),
    );
  }
  if (typeof value === "string") {
    return value
      .replace(/\bBearer\s+[A-Za-z0-9._-]+\b/gi, "Bearer [redacted]")
      .replace(/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/g, "[cpf_redacted]")
      .replace(
        /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi,
        "[email_redacted]",
      )
      .replace(
        /(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?(?:9\s*)?\d{4}[-\s]?\d{4}\b/g,
        "[phone_redacted]",
      )
      .replace(/\b(sk|pk|rk|tok|pat|key)_[A-Za-z0-9_-]{8,}\b/gi, (match) =>
        maskString(match),
      );
  }
  return value;
};

export const safeLog = (
  message: string,
  payload: Record<string, unknown> = {},
) => {
  console.info(message, sanitizeValue(payload));
};
