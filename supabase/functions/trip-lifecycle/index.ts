import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { getFirestore, Timestamp } from "npm:firebase-admin@11.10.1/firestore";
import { initializeApp, cert, getApps } from "npm:firebase-admin@11.10.1/app";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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
    } catch (_) {}
  }

  if (serviceAccountStr.includes('%7B')) {
    try {
      serviceAccountStr = decodeURIComponent(serviceAccountStr);
    } catch (_) {}
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
    } catch (_) {}
  }

  serviceAccountStr = serviceAccountStr.replace(/\\"/g, '"');

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountStr);
  } catch (err: any) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT_INVALID_JSON: ${err.message}`);
  }

  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');

  initializeApp({
    credential: cert(serviceAccount),
  });
  firebaseInitialized = true;
}

function parseDateValue(val: any): Date | null {
  if (!val) return null;
  if (val instanceof Date) return val;
  if (typeof val.toDate === 'function') return val.toDate();
  if (typeof val === 'string') {
    const d = new Date(val);
    return isNaN(d.getTime()) ? null : d;
  }
  if (typeof val === 'number') return new Date(val);
  return null;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    initFirebase();
  } catch (initErr: any) {
    console.error('FIREBASE_CONFIG_ERROR', initErr.message);
    return new Response(JSON.stringify({ error: 'Firebase Admin initialization failed', details: initErr.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Fail closed: scheduled maintenance endpoints must never run without a secret.
  const authHeader = req.headers.get('Authorization') || '';
  const cronKey = Deno.env.get('CRON_SECRET');
  if (!cronKey) {
    console.error('CRON_SECRET_NOT_CONFIGURED');
    return new Response(JSON.stringify({ error: 'Server cron secret is not configured' }), {
      status: 503,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const suppliedSecret = req.headers.get('x-cron-secret') || req.headers.get('apikey') || '';
  const expected = `Bearer ${cronKey}`;
  if (authHeader !== expected && suppliedSecret !== cronKey) {
    return new Response(JSON.stringify({ error: 'Unauthorized: Invalid CRON_SECRET' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const firestore = getFirestore();
  const nowDate = new Date();
  const nowTimestamp = Timestamp.fromDate(nowDate);

  let departuresProcessed = 0;
  let expiredBookingsCount = 0;
  let arrivalsProcessed = 0;
  let completedBookingsCount = 0;

  try {
    // =========================================================================
    // STEP 1: DEPARTURE LIFECYCLE (Trip departureTime <= now)
    // Bookable trips -> close booking, transition to 'running'
    // Unresolved pending bookings -> expire
    // =========================================================================
    const bookableStatuses = ['open', 'published', 'active', 'scheduled', 'upcoming'];
    const activeTripsSnap = await firestore
      .collection('trips')
      .where('status', 'in', bookableStatuses)
      .get();

    for (const tripDoc of activeTripsSnap.docs) {
      const tripData = tripDoc.data();
      const depDate = parseDateValue(tripData.departureTime);

      if (depDate && depDate.getTime() <= nowDate.getTime()) {
        const tripId = tripDoc.id;

        // Transition trip to 'running'
        await tripDoc.ref.update({
          status: 'running',
          isBookable: false,
          remainingSeats: 0,
          departedAt: nowTimestamp,
          updatedAt: nowTimestamp,
        });
        departuresProcessed++;

        // Expire unresolved bookings for this trip
        const pendingBookingsSnap = await firestore
          .collection('bookings')
          .where('tripId', '==', tripId)
          .where('status', 'in', ['pending_payment', 'awaiting_payment', 'payment_not_received'])
          .get();

        const batch = firestore.batch();
        for (const bDoc of pendingBookingsSnap.docs) {
          batch.update(bDoc.ref, {
            status: 'expired',
            expirationReason: 'انطلق موعد الرحلة دون استكمال سداد تأكيد الحجز',
            expiredAt: nowTimestamp,
            updatedAt: nowTimestamp,
          });
          expiredBookingsCount++;
        }
        if (pendingBookingsSnap.docs.length > 0) {
          await batch.commit();
        }
      }
    }

    // =========================================================================
    // STEP 2: ARRIVAL LIFECYCLE (Trip arrivalTime <= now)
    // Running trips -> transition to 'completed'
    // Confirmed bookings -> transition to 'completed' (enabling rating flow)
    // =========================================================================
    const runningTripsSnap = await firestore
      .collection('trips')
      .where('status', '==', 'running')
      .get();

    for (const tripDoc of runningTripsSnap.docs) {
      const tripData = tripDoc.data();
      const arrDate = parseDateValue(tripData.arrivalTime);

      if (arrDate && arrDate.getTime() <= nowDate.getTime()) {
        const tripId = tripDoc.id;

        // Transition trip to 'completed'
        await tripDoc.ref.update({
          status: 'completed',
          completedAt: nowTimestamp,
          updatedAt: nowTimestamp,
        });
        arrivalsProcessed++;

        // Complete confirmed bookings for this trip
        const confirmedBookingsSnap = await firestore
          .collection('bookings')
          .where('tripId', '==', tripId)
          .where('status', 'in', ['confirmed', 'accepted', 'in_progress'])
          .get();

        const batch = firestore.batch();
        for (const bDoc of confirmedBookingsSnap.docs) {
          batch.update(bDoc.ref, {
            status: 'completed',
            completedAt: nowTimestamp,
            updatedAt: nowTimestamp,
          });
          completedBookingsCount++;
        }
        if (confirmedBookingsSnap.docs.length > 0) {
          await batch.commit();
        }
      }
    }

    const result = {
      success: true,
      timestamp: nowDate.toISOString(),
      departuresProcessed,
      expiredBookingsCount,
      arrivalsProcessed,
      completedBookingsCount,
    };

    console.log('[TRIP_LIFECYCLE_SUCCESS]', JSON.stringify(result));

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    console.error('[TRIP_LIFECYCLE_ERROR]', err);
    return new Response(JSON.stringify({
      error: 'Trip lifecycle execution failed',
      details: err.message,
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
