import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";

import { put } from "@vercel/blob";

/** Somewhere to keep uploaded files; returns the file's URL. */
export interface FileStore {
  save(path: string, bytes: Buffer, contentType: string): Promise<string>;
}

/**
 * Vercel Blob, used in production. The random suffix makes each URL
 * unguessable, like a Firebase Storage download token, and means a file can
 * never be overwritten. Only people who can read the incident see the URL.
 */
class BlobStore implements FileStore {
  async save(path: string, bytes: Buffer, contentType: string): Promise<string> {
    const blob = await put(path, bytes, { access: "public", addRandomSuffix: true, contentType });
    return blob.url;
  }
}

/** A local folder, served by scripts/devServer.ts during development. */
class LocalStore implements FileStore {
  async save(path: string, bytes: Buffer): Promise<string> {
    const file = join(localUploadsDir(), path);
    await mkdir(dirname(file), { recursive: true });
    await writeFile(file, bytes);
    return `${process.env.API_PUBLIC_URL ?? "http://localhost:3000"}/files/${path}`;
  }
}

export function localUploadsDir(): string {
  return join(process.cwd(), ".local-uploads");
}

/**
 * True on Vercel once a Blob store is connected. Connected stores get
 * BLOB_STORE_ID and sign in with Vercel's OIDC token; older ones have a
 * read-write token. @vercel/blob handles either by itself.
 */
export function hasBlobStore(env: NodeJS.ProcessEnv = process.env): boolean {
  return Boolean(env.BLOB_STORE_ID || env.BLOB_READ_WRITE_TOKEN);
}

export function getFileStore(): FileStore {
  return hasBlobStore() ? new BlobStore() : new LocalStore();
}
