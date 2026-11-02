/**
 * Cloud Functions entry point for the VVU Campus Safety app.
 *
 * Each function lives in its own module (see docs/ARCHITECTURE.md §5) and is
 * re-exported here.
 */
import { setGlobalOptions } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";

// Same region as Firestore, close to Ghana.
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

initializeApp();

export { verifyId } from "./verifyId";
