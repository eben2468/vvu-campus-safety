import type { IncomingMessage, ServerResponse } from "node:http";

import { handleApi } from "../src/api/router";

type VercelRequest = IncomingMessage & { body?: unknown };

/**
 * Vercel's entry point. Every /api/* address is rewritten here (vercel.json),
 * so one function serves the whole API and stays warm, which keeps SOS
 * alerts fast.
 */
export default async function handler(req: VercelRequest, res: ServerResponse) {
  const url = new URL(req.url ?? "/", "http://localhost");
  const route = url.searchParams.get("route") ?? url.pathname.split("/").pop() ?? "";

  const response = await handleApi({
    method: req.method ?? "GET",
    route,
    authorization: req.headers.authorization,
    body: req.body,
  });

  res.writeHead(response.status, { ...response.headers, "Content-Type": "application/json" });
  res.end(response.body === null ? undefined : JSON.stringify(response.body));
}
