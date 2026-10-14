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

  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');

  initializeApp({
    credential: cert(serviceAccount)
  });
  firebaseInitialized = true;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    initFirebase();
  } catch (initErr: any) {
    console.error('FIREBASE_CONFIG_ERROR', initErr.message);
    return new Response(JSON.stringify({ error: 'Firebase Admin initialization failed' }), {
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
  if (authHeader !== `Bearer ${cronKey}` && suppliedSecret !== cronKey) {
    return new Response(JSON.stringify({ error: 'Unauthorized: Invalid CRON_SECRET' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const firestore = getFirestore();
  const now = Timestamp.now();
  
  try {
    const bookingsSnapshot = await firestore
      .collection('bookings')
      .where('status', '==', 'pending_payment')
      .where('paymentDeadline', '<=', now)
      .get();
      
    console.log(`Found ${bookingsSnapshot.size} expired bookings`);

    let expiredCount = 0;
    const batch = firestore.batch();

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();
      const bookingRef = doc.ref;
      
      const tripId = booking.tripId;
      const seatNumbers: string[] = booking.seatNumbers || [];
      const seatCount = booking.seatCount || 1;
      
      const tripRef = firestore.collection('trips').doc(tripId);
      
      // We should use a transaction to safely update the trip
      await firestore.runTransaction(async (t) => {
        // Read the booking again inside the transaction to prevent race conditions
        const currentBookingDoc = await t.get(bookingRef);
        if (!currentBookingDoc.exists) return;
        const currentBookingData = currentBookingDoc.data()!;
        
        // Verify it is still pending_payment and the deadline has actually passed
        if (currentBookingData.status !== 'pending_payment') return;
        if (!currentBookingData.paymentDeadline) return;
        
        // Handle both string and Timestamp deadlines correctly
        let deadlineTime: number;
        if (typeof currentBookingData.paymentDeadline === 'string') {
          deadlineTime = new Date(currentBookingData.paymentDeadline).getTime();
        } else if (currentBookingData.paymentDeadline.toDate) {
          deadlineTime = currentBookingData.paymentDeadline.toDate().getTime();
        } else {
          return;
        }
        
        const nowTime = Timestamp.now().toDate().getTime();
        if (deadlineTime > nowTime) return;

        const tripDoc = await t.get(tripRef);
        if (!tripDoc.exists) return;
        
        const tripData = tripDoc.data()!;
        
        // Restore seats
        let seatLayout = tripData.seatLayout;
        let seatsRestored = 0;
        if (seatLayout && Array.isArray(seatLayout)) {
            seatLayout = seatLayout.map((seat: any) => {
                if (seatNumbers.includes(seat.id) && seat.status === 'temporarily_reserved') {
                    seatsRestored++;
                    return { ...seat, isAvailable: true, status: 'available' };
                }
                return seat;
            });
        }
        
        // If seatCount > 0, we'll restore that many. If using explicit seats, we could use seatsRestored.
        // Fallback to seatCount if seatsRestored is 0 but we need to restore something.
        const seatsToAdd = Math.max(seatsRestored, seatCount);

        t.update(tripRef, {
            remainingSeats: (tripData.remainingSeats || 0) + seatsToAdd,
            seatLayout: seatLayout
        });
        
        t.update(bookingRef, {
            status: 'expired',
            paymentStatus: 'not_submitted',
            updatedAt: Timestamp.now()
        });
      });
      
      expiredCount++;
    }

    return new Response(JSON.stringify({ success: true, processed: expiredCount }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    console.error('Error expiring bookings', err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
