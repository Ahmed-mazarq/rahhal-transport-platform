import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getAuth } from "npm:firebase-admin@11.10.1/auth";
import { getFirestore } from "npm:firebase-admin@11.10.1/firestore";
import { initializeApp, cert, getApps } from "npm:firebase-admin@11.10.1/app";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, firebase-authorization, x-client-info, apikey, content-type',
};

// Initialize Firebase Admin lazily
let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized || getApps().length > 0) return;
  
  let serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '';
  if (!serviceAccountStr) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_MISSING');
  }

  serviceAccountStr = serviceAccountStr.trim();
  
  if (!serviceAccountStr.startsWith('{') && !serviceAccountStr.startsWith('"') && !serviceAccountStr.startsWith("'")) {
    try {
      const decoded = atob(serviceAccountStr);
      if (decoded.trim().startsWith('{')) {
        serviceAccountStr = decoded.trim();
      }
    } catch (e) {}
  }

  if (serviceAccountStr.includes('%7B')) {
    try {
      serviceAccountStr = decodeURIComponent(serviceAccountStr);
    } catch (e) {}
  }

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

  serviceAccountStr = serviceAccountStr.replace(/\\"/g, '"');

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountStr);
  } catch (err: any) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT_INVALID_JSON: ${err.message}`);
  }

  if (!serviceAccount || typeof serviceAccount !== 'object' || !serviceAccount.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_NOT_OBJECT_OR_MISSING_KEY');
  }

  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');

  initializeApp({
    credential: cert(serviceAccount)
  });
  firebaseInitialized = true;
}

serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { bookingId, path } = await req.json();
    if (!bookingId || !path) {
      return new Response(JSON.stringify({ error: 'Missing bookingId or path' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let normalizedPath = path;
    if (normalizedPath.startsWith('private://')) {
      normalizedPath = normalizedPath.replace('private://', '');
    }
    
    // Security check: Reject traversal attempts
    if (normalizedPath.includes('../') || normalizedPath.includes('..%2f') || normalizedPath.includes('..%2F')) {
      return new Response(JSON.stringify({ error: 'Invalid document path traversal' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify the Firebase JWT
    const firebaseToken = authHeader.replace('Bearer ', '');
    
    try {
      initFirebase();
    } catch (initErr: any) {
      console.error('FIREBASE_CONFIG_ERROR', initErr.message);
      return new Response(JSON.stringify({ error: 'Firebase Admin initialization failed', details: initErr.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const auth = getAuth();
    
    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(firebaseToken);
    } catch (verifyError: any) {
      console.error('FIREBASE_VERIFY_FAILED', { code: verifyError?.code, message: verifyError?.message });
      return new Response(
        JSON.stringify({ error: 'Invalid or expired Firebase token', code: verifyError?.code ?? 'UNKNOWN_FIREBASE_AUTH_ERROR' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const uid = decodedToken.uid;
    console.log(`BOOKING CHAT: verifiedUid = ${uid}, bookingId = ${bookingId}`);

    // Verify booking ownership
    const firestore = getFirestore();
    const bookingDoc = await firestore.collection('bookings').doc(bookingId).get();
    
    if (!bookingDoc.exists) {
      return new Response(JSON.stringify({ error: 'Booking not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const bookingData = bookingDoc.data();
    if (bookingData?.driverId !== uid && bookingData?.passengerId !== uid) {
      console.error(`BOOKING CHAT: uid ${uid} is not authorized for booking ${bookingId}`);
      return new Response(JSON.stringify({ error: 'AUTHORIZATION_FAILED', details: 'Access denied' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Strictly enforce booking chat path pattern
    if (!normalizedPath.includes(`/booking_chat/${bookingId}/`)) {
      console.error(`BOOKING CHAT: path does not belong to booking chat for booking ${bookingId}`);
      return new Response(JSON.stringify({ error: 'PATH_MISMATCH', details: 'Path mismatch' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Generate signed URL
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin
      .storage
      .from('rahhal-private')
      .createSignedUrl(normalizedPath, 900); // 15 minutes = 900 seconds

    if (signedUrlError) {
      console.error('Supabase createSignedUrl failure', signedUrlError);
      return new Response(JSON.stringify({ error: 'Failed to create signed URL' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({ signedUrl: signedUrlData.signedUrl }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error: any) {
    console.error('Unexpected error', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
