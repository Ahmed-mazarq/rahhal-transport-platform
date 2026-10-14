import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createRemoteJWKSet, jwtVerify, SignJWT } from "https://deno.land/x/jose@v4.13.1/index.ts";

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') || '';
const FIREBASE_ISSUER = FIREBASE_PROJECT_ID
  ? `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`
  : '';
const JWKS_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const JWKS = createRemoteJWKSet(new URL(JWKS_URL));

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    if (!FIREBASE_PROJECT_ID) {
      throw new Error('FIREBASE_PROJECT_ID environment variable is not set');
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing or invalid Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', ...corsHeaders() }
      });
    }

    const firebaseToken = authHeader.replace('Bearer ', '');
    
    // 1. Verify the Firebase JWT
    const { payload } = await jwtVerify(firebaseToken, JWKS, {
      issuer: FIREBASE_ISSUER,
      audience: FIREBASE_PROJECT_ID,
    });

    const uid = payload.sub;
    if (!uid) {
      throw new Error("Missing 'sub' (uid) claim in Firebase token.");
    }

    // 2. Extract custom claims (e.g. admin)
    const isAdmin = payload.admin === true;

    // 3. Mint Supabase JWT
    const supabaseSecret = Deno.env.get('SUPABASE_JWT_SECRET');
    if (!supabaseSecret) {
      throw new Error('SUPABASE_JWT_SECRET environment variable is not set');
    }
    const secretKey = new TextEncoder().encode(supabaseSecret);

    const supabaseJwt = await new SignJWT({
      role: 'authenticated',
      sub: uid,
      aud: 'authenticated',
      admin: isAdmin, // Keep the custom claim for Admin view policies
      // You can add other claims like email or phone if needed
    })
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuedAt()
      .setExpirationTime('1h') // Token valid for 1 hour
      .sign(secretKey);

    return new Response(
      JSON.stringify({ supabase_token: supabaseJwt }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json', ...corsHeaders() } 
      }
    );
  } catch (err) {
    console.error('Auth bridge error:', err);
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
