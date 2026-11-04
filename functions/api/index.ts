import type { IncomingMessage, ServerResponse } from "node:http";

type VercelRequest = IncomingMessage & { body?: unknown };

function send(res: ServerResponse, status: number, headers: Record<string, string>, body: unknown) {
  res.writeHead(status, { ...headers, "Content-Type": "application/json" });
  res.end(body === null ? undefined : JSON.stringify(body));
}

/**
 * Vercel's entry point. Every /api/* address is rewritten here (vercel.json),
 * so one function serves the whole API and stays warm, which keeps SOS
 * alerts fast. The router is imported here rather than at the top so that a
 * start-up failure gives a readable error, not a bare crash page.
 */
export default async function handler(req: VercelRequest, res: ServerResponse) {
  const url = new URL(req.url ?? "/", "http://localhost");
  const route = url.searchParams.get("route") ?? url.pathname.split("/").pop() ?? "";

  try {
    const { handleApi } = await import("../src/api/router.js");
    const response = await handleApi({
      method: req.method ?? "GET",
      route,
      authorization: req.headers.authorization,
      body: req.body,
    });
    send(res, response.status, response.headers, response.body);
  } catch (error) {
    console.error("API failed to start", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    send(res, 500, {}, { error: { code: "internal", message: `Server failed to start: ${message}` } });
  }
}
