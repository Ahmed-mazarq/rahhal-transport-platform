import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { getAuth } from "npm:firebase-admin@11.10.1/auth";
import { initializeApp, cert, getApps } from "npm:firebase-admin@11.10.1/app";

// Initialize Firebase Admin lazily to avoid cold start overhead if it's an OPTIONS request
let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized || getApps().length > 0) return;
  
  let serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '';
  if (!serviceAccountStr) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing');
  }

  serviceAccountStr = serviceAccountStr.trim();
  
  // 1. Try decoding Base64 if it doesn't start with {
  if (!serviceAccountStr.startsWith('{') && !serviceAccountStr.startsWith('"') && !serviceAccountStr.startsWith("'")) {
    try {
      const decoded = atob(serviceAccountStr);
      if (decoded.trim().startsWith('{')) {
        serviceAccountStr = decoded.trim();
      }
    } catch (e) {}
  }

  // 2. Try URI decoding
  if (serviceAccountStr.includes('%7B')) {
    try {
      serviceAccountStr = decodeURIComponent(serviceAccountStr);
    } catch (e) {}
  }

  // 3. Strip surrounding quotes if present
  if (serviceAccountStr.startsWith("'") && serviceAccountStr.endsWith("'")) {
    serviceAccountStr = serviceAccountStr.slice(1, -1).trim();
  }
  if (serviceAccountStr.startsWith('"') && serviceAccountStr.endsWith('"')) {
    try {
      const unescaped = JSON.parse(serviceAccountStr);
      if (typeof unescaped === 'string') {
        serviceAccountStr = unescaped.trim();
      }
    } catch (e) {}
  }

  // 4. Try unescaping raw backslashes if double escaped
  serviceAccountStr = serviceAccountStr.replace(/\\"/g, '"');

  let serviceAccount;
  let firstErr = '';
  try {
    serviceAccount = JSON.parse(serviceAccountStr);
  } catch (err: any) {
    firstErr = err.message;
    try {
      // 5. Try loose JS evaluation
      serviceAccount = new Function('return (' + serviceAccountStr + ');')();
    } catch (err2: any) {
      throw new Error(`FIREBASE_SERVICE_ACCOUNT is not valid JSON. JSON.parse error: ${firstErr}. Fallback error: ${err2.message}`);
    }
  }

  if (!serviceAccount || typeof serviceAccount !== 'object' || !serviceAccount.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT parsed but missing private_key. Keys found: ' + Object.keys(serviceAccount || {}).join(', '));
  }

  // Ensure private_key has correct newlines (Deno env vars often double-escape them)
  if (serviceAccount.private_key) {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
  }

  initializeApp({
    credential: cert(serviceAccount)
  });
  firebaseInitialized = true;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', ...corsHeaders() }
      });
    }

    const firebaseToken = authHeader.replace('Bearer ', '');
    
    initFirebase();
    const auth = getAuth();

    // 1. Verify the Firebase JWT
    const decodedToken = await auth.verifyIdToken(firebaseToken);
    const uid = decodedToken.uid;

    if (!uid) {
      throw new Error("Missing 'uid' in Firebase token.");
    }

    // 2. Fetch the user's current claims
    const user = await auth.getUser(uid);
    const currentClaims = user.customClaims || {};

    // 3. Set or preserve custom claims, appending `role: "authenticated"`
    if (currentClaims.role !== "authenticated") {
      const newClaims = {
        ...currentClaims,
        role: "authenticated",
      };

      // Never auto-assign admin=true here
      await auth.setCustomUserClaims(uid, newClaims);
      console.log(`Assigned role: authenticated to UID: ${uid}`);
    } else {
      console.log(`UID: ${uid} already has role: authenticated`);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json', ...corsHeaders() } 
      }
    );
  } catch (err: any) {
    console.error('Firebase Claim Bridge error:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }),
      { 
        status: 401, 
        headers: { 'Content-Type': 'application/json', ...corsHeaders() } 
      }
    );
  }
});

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}
