import { getApps, initializeApp, cert, getApp, App } from "firebase-admin/app";
import { getAuth, Auth } from "firebase-admin/auth";
import { getFirestore, Firestore } from "firebase-admin/firestore";

function getServiceAccount() {
  const serviceAccountEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;

  if (serviceAccountEnv) {
    try {
      if (serviceAccountEnv.trim().startsWith("{")) {
        return JSON.parse(serviceAccountEnv);
      }
    } catch (e) {
      console.warn("Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY JSON string:", e);
    }
  }

  // Fallback to separate env variables
  const projectId = process.env.FIREBASE_PROJECT_ID || process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "schedly-b4b8d";
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (clientEmail && privateKey) {
    if (privateKey.includes("\\n")) {
      privateKey = privateKey.replace(/\\n/g, "\n");
    }
    return {
      projectId,
      clientEmail,
      privateKey,
    };
  }

  return null;
}

let app: App;

if (!getApps().length) {
  const serviceAccount = getServiceAccount();

  if (serviceAccount) {
    app = initializeApp({
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id || serviceAccount.projectId || "schedly-b4b8d",
    });
  } else {
    app = initializeApp({
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "schedly-b4b8d",
    });
  }
} else {
  app = getApp();
}

export const adminAuth: Auth = getAuth(app);
export const adminDb: Firestore = getFirestore(app);
export default app;
