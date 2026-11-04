import type { IncomingMessage, ServerResponse } from "node:http";

type VercelRequest = IncomingMessage & { body?: unknown };

function send(res: ServerResponse, status: number, headers: Record<string, string>, body: unknown) {
  res.writeHead(status, { ...headers, "Content-Type": "application/json" });
  res.end(body === null ? undefined : JSON.stringify(body));
}

/**
 * Sends a stored photo. Images can't carry a sign-in token, so the unguessable
 * address is the protection, as it was with Firebase Storage download URLs.
 */
async function sendPhoto(res: ServerResponse, path: string | null) {
  const { readPhoto } = await import("../src/photos.js");
  const bytes = await readPhoto(path);
  if (!bytes) {
    res.writeHead(404).end();
    return;
  }
  res.writeHead(200, {
    "Content-Type": "image/jpeg",
    "Access-Control-Allow-Origin": "*",
    "Cache-Control": "private, max-age=86400",
  });
  res.end(bytes);
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
    if (route === "file") {
      await sendPhoto(res, url.searchParams.get("path"));
      return;
    }
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
