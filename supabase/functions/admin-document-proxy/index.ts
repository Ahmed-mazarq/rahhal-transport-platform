import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getAuth } from "npm:firebase-admin@11.10.1/auth";
import { initializeApp, cert, getApps } from "npm:firebase-admin@11.10.1/app";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, firebase-authorization, x-client-info, apikey, content-type',
};

// Admin UID check removed to support role-based auth

// Initialize Firebase Admin lazily
let firebaseInitialized = false;

function initFirebase() {
  if (firebaseInitialized || getApps().length > 0) return;
  
  let serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '';
  if (!serviceAccountStr) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_MISSING');
  }

  serviceAccountStr = serviceAccountStr.trim();
  
  // Clean up any potential encoding issues safely without using eval/new Function
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

  if (!serviceAccount || typeof serviceAccount !== 'object') {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_NOT_OBJECT');
  }
  
  if (!serviceAccount.project_id) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_MISSING_PROJECT_ID');
  }
  
  if (!serviceAccount.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_MISSING_PRIVATE_KEY');
  }

  // Ensure private_key has correct newlines (Deno env vars often double-escape them)
  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');

  console.log('FIREBASE_ADMIN_PROJECT:', serviceAccount.project_id);
  console.log('FIREBASE_ADMIN_CLIENT:', serviceAccount.client_email);

  const expectedProjectId = Deno.env.get('FIREBASE_PROJECT_ID') || '';
  if (!expectedProjectId) {
    throw new Error('FIREBASE_PROJECT_ID_MISSING');
  }
  if (serviceAccount.project_id !== expectedProjectId) {
    throw new Error(`FIREBASE_PROJECT_MISMATCH: expected ${expectedProjectId} but got ${serviceAccount.project_id}`);
  }

  initializeApp({
    credential: cert(serviceAccount),
    projectId: serviceAccount.project_id
  });
  firebaseInitialized = true;
}

serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Firebase-Authorization') || req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Firebase-Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { path } = await req.json();
    if (!path) {
      return new Response(JSON.stringify({ error: 'Missing document path' }), {
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

    // Must be a known root folder
    const validRoots = ['drivers/', 'companies/', 'vehicles/', 'users/', 'documents/', 'driver_documents/', 'vehicle_documents/', 'verification_company/'];
    const isValidRoot = validRoots.some(root => normalizedPath.startsWith(root));
    if (!isValidRoot) {
      return new Response(JSON.stringify({ error: 'Invalid document path root' }), {
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
      console.error('FIREBASE_VERIFY_FAILED', {
        code: verifyError?.code,
        message: verifyError?.message,
      });

      return new Response(
        JSON.stringify({
          error: 'Invalid or expired Firebase token',
          code: verifyError?.code ?? 'UNKNOWN_FIREBASE_AUTH_ERROR',
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const uid = decodedToken.uid;
    console.log(`ADMIN DOCUMENT PROXY: verifiedUid = ${uid}`);
    console.log(`ADMIN DOCUMENT PROXY: requestedPath = ${normalizedPath}`);

    const hasAdminClaim = decodedToken.admin === true || decodedToken.role === 'admin';
    if (!hasAdminClaim) {
      console.error(`ADMIN_AUTHORIZATION_FAILED: uid ${uid} is not authorized`);
      return new Response(JSON.stringify({ error: 'ADMIN_AUTHORIZATION_FAILED', details: 'Admin access denied' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // User is the valid Admin. Proceed to download the file directly from Supabase Storage.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: fileData, error: fileError } = await supabaseAdmin
      .storage
      .from('rahhal-private')
      .download(normalizedPath);

    if (fileError) {
      console.error('Supabase storage download failure:', fileError.message);
      
      // If the error message implies not found, return 404
      if (fileError.message && (fileError.message.includes('not found') || fileError.message.includes('Object not found'))) {
        return new Response(JSON.stringify({ error: 'Document not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
      
      return new Response(JSON.stringify({ error: 'Failed to download document' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    if (!fileData) {
      return new Response(JSON.stringify({ error: 'Document data is empty' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    console.log('ADMIN DOCUMENT PROXY: download = SUCCESS');

    // Determine Content-Type from extension
    const lowerPath = normalizedPath.toLowerCase();
    let contentType = 'application/octet-stream';
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) contentType = 'image/jpeg';
    else if (lowerPath.endsWith('.png')) contentType = 'image/png';
    else if (lowerPath.endsWith('.webp')) contentType = 'image/webp';
    else if (lowerPath.endsWith('.pdf')) contentType = 'application/pdf';

    // Stream the binary data directly to the client
    return new Response(fileData, {
      status: 200,
      headers: { 
        ...corsHeaders, 
        'Content-Type': contentType,
        'Cache-Control': 'private, max-age=300'
      },
    });

  } catch (error: any) {
    console.error('Unexpected error');
    return new Response(
      JSON.stringify({ error: 'Unexpected proxy error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
