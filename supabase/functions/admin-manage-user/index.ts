import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getAuth } from "npm:firebase-admin@11.10.1/auth";
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
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const { action } = body;

    if (!action) {
      return new Response(JSON.stringify({ error: 'Missing action' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Verify the Firebase JWT
    const firebaseToken = authHeader.replace('Bearer ', '');
    
    try {
      initFirebase();
    } catch (initErr: any) {
      console.error('FIREBASE_CONFIG_ERROR', initErr.message);
      return new Response(JSON.stringify({ error: 'Firebase Admin initialization failed', details: initErr.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const auth = getAuth();
    
    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(firebaseToken);
    } catch (verifyError: any) {
      return new Response(JSON.stringify({ error: 'Invalid or expired Firebase token' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const uid = decodedToken.uid;
    console.log(`ADMIN MANAGE USER: verifiedUid = ${uid}`);

    const isAdmin = decodedToken.admin === true;
    const isSuperAdmin = isAdmin && decodedToken.app_role === 'super_admin';
    
    if (!isAdmin) {
       return new Response(JSON.stringify({ error: 'ADMIN_AUTHORIZATION_FAILED', details: 'Admin access denied' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const requiresSuperAdmin = ['grant_admin_claims', 'create_sub_admin', 'delete_sub_admin'];
    if (requiresSuperAdmin.includes(action) && !isSuperAdmin) {
       return new Response(JSON.stringify({ error: 'SUPER_ADMIN_REQUIRED', details: 'Action requires super_admin app_role' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'set_disabled_status') {
      const { targetUid, disabled } = body;
      if (!targetUid || disabled === undefined) {
         return new Response(JSON.stringify({ error: 'Missing targetUid or disabled' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
      
      try {
        await auth.updateUser(targetUid, { disabled: disabled });
        console.log(`Successfully updated disabled status for ${targetUid} to ${disabled}`);
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      } catch(e: any) {
        console.error('Auth Disable Error', e);
        return new Response(JSON.stringify({ error: 'Failed to update user auth status', details: e.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    } 
    
    else if (action === 'create_sub_admin') {
      const { email, password, displayName, phone, role } = body;
      if (!email || !password || !role) {
         return new Response(JSON.stringify({ error: 'Missing email, password, or role' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      const allowedRoles = ['admin', 'operations_manager', 'support_manager', 'fleet_manager', 'finance_manager', 'compliance_manager'];
      if (!allowedRoles.includes(role)) {
         return new Response(JSON.stringify({ error: 'Invalid app_role requested' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      try {
        const userRecord = await auth.createUser({
          email: email,
          password: password,
          displayName: displayName,
          phoneNumber: phone || undefined,
        });
        
        // Set necessary admin claims
        await auth.setCustomUserClaims(userRecord.uid, {
          role: 'authenticated',
          admin: true,
          app_role: role
        });
        
        console.log('Successfully created new sub admin with claims:', userRecord.uid);
        
        return new Response(JSON.stringify({ success: true, uid: userRecord.uid }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      } catch(e: any) {
        console.error('Auth Create Error', e);
        return new Response(JSON.stringify({ error: 'Failed to create auth user', details: e.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    } 
    
    else if (action === 'grant_admin_claims') {
      const { targetUid } = body;
      if (!targetUid) {
         return new Response(JSON.stringify({ error: 'Missing targetUid' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      try {
        const userRecord = await auth.getUser(targetUid);
        const currentClaims = userRecord.customClaims || {};
        
        await auth.setCustomUserClaims(targetUid, {
          ...currentClaims,
          role: 'authenticated',
          admin: true,
          app_role: currentClaims.app_role || 'admin'
        });
        
        console.log('Successfully granted admin claims to:', targetUid);
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      } catch(e: any) {
        console.error('Auth Update Claims Error', e);
        return new Response(JSON.stringify({ error: 'Failed to update user claims', details: e.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    } 
    
    else if (action === 'delete_sub_admin') {
      const { targetUid } = body;
      if (!targetUid) {
         return new Response(JSON.stringify({ error: 'Missing targetUid' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }

      try {
        await auth.deleteUser(targetUid);
        console.log('Successfully deleted stranded sub admin:', targetUid);
        
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      } catch(e: any) {
        console.error('Auth Delete Error', e);
        return new Response(JSON.stringify({ error: 'Failed to delete auth user', details: e.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    }

    return new Response(JSON.stringify({ error: 'Invalid action' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (error: any) {
    console.error('Unexpected error', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
