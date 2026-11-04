/**
 * Runs the API on your PC against the Firebase emulators, the way Vercel
 * runs it in production. Start the emulators first, then:
 *
 *   npm run api:dev
 *
 * Uploaded photos go to .local-uploads/. The sweep runs every minute here,
 * as the scheduler does in production.
 */
import { createReadStream, existsSync } from "node:fs";
import { createServer, IncomingMessage } from "node:http";
import { join, normalize } from "node:path";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
process.env.GCLOUD_PROJECT ??= "demo-vvu-campus-safety";
process.env.CRON_SECRET ??= "local-dev-secret";
process.env.BACKUP_KEY ??= "local-dev-backup-key";

import { handleApi } from "../src/api/router";
import { localUploadsDir } from "../src/photoStore";

const PORT = Number(process.env.PORT ?? 3000);

async function readJson(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) chunks.push(chunk as Buffer);
  const text = Buffer.concat(chunks).toString("utf8");
  return text ? JSON.parse(text) : null;
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", "http://localhost");

  if (url.pathname.startsWith("/files/")) {
    const relative = normalize(decodeURIComponent(url.pathname.slice("/files/".length)));
    const file = join(localUploadsDir(), relative);
    if (relative.startsWith("..") || !existsSync(file)) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { "Content-Type": "image/jpeg", "Access-Control-Allow-Origin": "*" });
    createReadStream(file).pipe(res);
    return;
  }

  const response = await handleApi({
    method: req.method ?? "GET",
    route: url.pathname.split("/").pop() ?? "",
    authorization: req.headers.authorization,
    body: await readJson(req).catch(() => null),
  });
  res.writeHead(response.status, { ...response.headers, "Content-Type": "application/json" });
  res.end(response.body === null ? undefined : JSON.stringify(response.body));
});

server.listen(PORT, () => {
  console.log(`API running on http://localhost:${PORT}/api (emulators)`);
});

setInterval(() => {
  void handleApi({
    method: "GET",
    route: "sweep",
    authorization: `Bearer ${process.env.CRON_SECRET}`,
    body: null,
  });
}, 60_000);
