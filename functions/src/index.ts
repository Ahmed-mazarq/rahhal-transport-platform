import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { defineSecret, defineString } from 'firebase-functions/params';
import { createClient } from '@supabase/supabase-js';

const supabaseSecret = defineSecret('SUPABASE_SECRET_KEY');
const supabaseUrl = defineString('SUPABASE_URL');


admin.initializeApp();

export const onNotificationCreated = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();

    // Only process if status is 'sent'
    if (notification.status !== 'sent') {
      console.log(`Notification ${context.params.notificationId} is not marked as 'sent', skipping.`);
      return null;
    }

    const title = notification.title || 'New Notification';
    const body = notification.body || '';
    const targetRole = notification.targetRole || 'all';
    const userId = notification.userId;
    const payload = notification.payload || {};

    const messagePayload = {
      notification: {
        title,
        body,
      },
      data: {
        ...payload,
        id: snapshot.id,
        category: notification.category || 'general',
      }
    };

    try {
      if (userId && userId.trim() !== '') {
        // Targeted to a specific user
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (fcmToken) {
           await admin.messaging().send({
               ...messagePayload,
               token: fcmToken
           });
           console.log(`Successfully sent message to token for user ${userId}`);
           
           // Update delivered count
           await snapshot.ref.update({
             deliveredCount: admin.firestore.FieldValue.increment(1)
           });
        } else {
           console.log(`No FCM token found for user ${userId}`);
           await snapshot.ref.update({
             failedCount: admin.firestore.FieldValue.increment(1)
           });
        }
      } else {
        // Broadcast via Topic based on role
        const topic = targetRole; // e.g., 'all', 'passenger', 'driver', 'company'
        
        await admin.messaging().send({
            ...messagePayload,
            topic: topic
        });
        console.log(`Successfully sent broadcast message to topic: ${topic}`);
        
        await snapshot.ref.update({
            deliveredCount: admin.firestore.FieldValue.increment(1) // Just counting topic broadcast success
        });
      }
    } catch (error) {
      console.error('Error sending notification:', error);
      await snapshot.ref.update({
        failedCount: admin.firestore.FieldValue.increment(1)
      });
    }

    return null;
  });

export const expirePendingBookings = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  try {
    const expiredBookingsSnapshot = await db.collection('bookings')
      .where('status', '==', 'pending_payment')
      .where('paymentDeadline', '<', now)
      .get();

    if (expiredBookingsSnapshot.empty) {
      console.log('No expired bookings found.');
      return null;
    }

    console.log(`Found ${expiredBookingsSnapshot.size} expired bookings.`);

    const batch = db.batch();
    const tripUpdates: { [tripId: string]: Set<string> } = {};

    expiredBookingsSnapshot.forEach(doc => {
      batch.update(doc.ref, { 
        status: 'expired',
        updatedAt: now,
      });

      const booking = doc.data();
      const tripId = booking.tripId;
      if (!tripUpdates[tripId]) {
        tripUpdates[tripId] = new Set();
      }
      if (booking.seatNumbers && Array.isArray(booking.seatNumbers)) {
        booking.seatNumbers.forEach((seat: string) => tripUpdates[tripId].add(seat));
      } else if (booking.seatNumber) {
        tripUpdates[tripId].add(booking.seatNumber);
      }
    });

    await batch.commit();
    console.log('Successfully expired bookings.');

    // Release seats in trips
    for (const tripId of Object.keys(tripUpdates)) {
      const seatsToRelease = Array.from(tripUpdates[tripId]);
      if (seatsToRelease.length > 0) {
        await db.runTransaction(async (transaction) => {
          const tripRef = db.collection('trips').doc(tripId);
          const tripDoc = await transaction.get(tripRef);
          if (!tripDoc.exists) return;
          
          const tripData = tripDoc.data();
          if (!tripData) return;

          let seatLayout = tripData.seatLayout || [];
          let updated = false;

          for (const seat of seatLayout) {
            if (seatsToRelease.includes(seat.number)) {
              if (seat.status === 'temporarily_reserved' || seat.status === 'booked') {
                seat.status = 'available';
                updated = true;
              }
            }
          }

          if (updated) {
            transaction.update(tripRef, { 
              seatLayout: seatLayout,
              remainingSeats: admin.firestore.FieldValue.increment(seatsToRelease.length)
            });
          }
        });
        console.log(`Released seats ${seatsToRelease.join(', ')} for trip ${tripId}`);
      }
    }

  } catch (error) {
    console.error('Error expiring pending bookings:', error);
  }

  return null;
});

export const generateUploadUrl = functions.runWith({ secrets: [supabaseSecret] }).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { documentType, vehicleId } = data;
  if (!documentType || typeof documentType !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'documentType is required.');
  }

  const driverDocTypes = ['personalPhoto', 'idFront', 'idBack', 'licenseFront', 'licenseBack', 'insuranceDoc'];
  const vehicleDocTypes = ['vehicleFront', 'vehicleBack', 'vehicleRight', 'vehicleLeft', 'vehicleInterior', 'vehiclePlate'];
  
  if (!driverDocTypes.includes(documentType) && !vehicleDocTypes.includes(documentType)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid document type.');
  }

  const uid = context.auth.uid;
  let path = '';
  
  if (driverDocTypes.includes(documentType)) {
    path = `drivers/${uid}/documents/${documentType}.jpg`;
  } else if (vehicleDocTypes.includes(documentType)) {
    if (!vehicleId || typeof vehicleId !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'vehicleId is required for vehicle documents.');
    }
    path = `drivers/${uid}/vehicles/${vehicleId}/verification/${documentType}.jpg`;
  }

  const supabase = createClient(supabaseUrl.value(), supabaseSecret.value());

  const { data: uploadData, error } = await supabase.storage
    .from('rahhal-private')
    .createSignedUploadUrl(path);

  if (error || !uploadData) {
    console.error('Error generating signed upload URL:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate upload URL.');
  }

  return {
    signedUrl: uploadData.signedUrl,
    token: uploadData.token,
    path: uploadData.path,
  };
});

export const generateDownloadUrl = functions.runWith({ secrets: [supabaseSecret] }).https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { path } = data;
  if (!path || typeof path !== 'string' || !path.startsWith('drivers/')) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid path.');
  }

  const uid = context.auth.uid;
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  
  if (!userDoc.exists || userDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can view private documents.');
  }

  const supabase = createClient(supabaseUrl.value(), supabaseSecret.value());

  const { data: downloadData, error } = await supabase.storage
    .from('rahhal-private')
    .createSignedUrl(path, 900);

  if (error || !downloadData) {
    console.error('Error generating signed download URL:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate download URL.');
  }

  return {
    signedUrl: downloadData.signedUrl,
  };
});

export const revokeUserSessions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists || callerDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can perform this action.');
  }

  const { uid } = data;
  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Valid uid is required.');
  }

  try {
    await admin.auth().revokeRefreshTokens(uid);
    await admin.firestore().collection('security_events').add({
      type: 'session_revoked',
      userId: uid,
      adminId: callerUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      description: `User sessions revoked by Admin ${callerUid}`
    });
    return { success: true };
  } catch (error) {
    console.error('Error revoking tokens:', error);
    throw new functions.https.HttpsError('internal', 'Failed to revoke sessions.');
  }
});

export const lockAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists || callerDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can perform this action.');
  }

  const { uid, lock } = data;
  if (!uid || typeof uid !== 'string' || typeof lock !== 'boolean') {
    throw new functions.https.HttpsError('invalid-argument', 'Valid uid and lock boolean are required.');
  }

  try {
    await admin.auth().updateUser(uid, { disabled: lock });
    await admin.firestore().collection('users').doc(uid).update({
      status: lock ? 'locked' : 'active',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    await admin.firestore().collection('security_events').add({
      type: lock ? 'account_locked' : 'account_unlocked',
      userId: uid,
      adminId: callerUid,
      title: lock ? 'قفل حساب' : 'فتح حساب',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      description: `تم ${lock ? 'قفل' : 'فتح'} حساب المستخدم ${uid}`
    });
    return { success: true };
  } catch (error) {
    console.error(`Error ${lock ? 'locking' : 'unlocking'} account:`, error);
    throw new functions.https.HttpsError('internal', `Failed to ${lock ? 'lock' : 'unlock'} account.`);
  }
});
