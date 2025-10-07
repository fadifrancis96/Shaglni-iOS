/**
 * Firebase Cloud Functions Template for Shaglni App
 * 
 * This file should be deployed to Firebase Cloud Functions to handle push notifications.
 * 
 * Setup Instructions:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login to Firebase: firebase login
 * 3. Initialize functions in your project directory: firebase init functions
 * 4. Replace the content of functions/index.js with this code
 * 5. Deploy: firebase deploy --only functions
 * 
 * Required Dependencies:
 * - firebase-admin
 * - firebase-functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Trigger when a new offer is submitted
 * Sends push notification to the job poster
 */
exports.sendOfferNotification = functions.firestore
    .document('jobs/{jobId}/offers/{offerId}')
    .onCreate(async (snap, context) => {
        const offer = snap.data();
        const jobId = context.params.jobId;
        
        try {
            // Get job details
            const jobDoc = await admin.firestore().collection('jobs').doc(jobId).get();
            const job = jobDoc.data();
            
            // Get job poster's FCM token
            const userDoc = await admin.firestore().collection('users').doc(job.createdBy).get();
            const fcmToken = userDoc.data()?.fcmToken;
            
            if (!fcmToken) {
                console.log('No FCM token found for user:', job.createdBy);
                return null;
            }
            
            // Send notification
            const message = {
                notification: {
                    title: 'New Offer Received!',
                    body: `${offer.contractorName} offered ₪${Math.round(offer.price)} for ${job.title}`
                },
                data: {
                    type: 'new_offer',
                    jobId: jobId,
                    offerId: context.params.offerId,
                    jobTitle: job.title
                },
                token: fcmToken
            };
            
            await admin.messaging().send(message);
            console.log('Offer notification sent successfully');
            return null;
        } catch (error) {
            console.error('Error sending offer notification:', error);
            return null;
        }
    });

/**
 * Trigger when an offer status is updated
 * Sends push notification to the contractor
 */
exports.sendOfferResponseNotification = functions.firestore
    .document('jobs/{jobId}/offers/{offerId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Only send notification if status changed
        if (before.status === after.status) {
            return null;
        }
        
        const jobId = context.params.jobId;
        
        try {
            // Get job details
            const jobDoc = await admin.firestore().collection('jobs').doc(jobId).get();
            const job = jobDoc.data();
            
            // Get contractor's FCM token
            const userDoc = await admin.firestore().collection('users').doc(after.contractorId).get();
            const fcmToken = userDoc.data()?.fcmToken;
            
            if (!fcmToken) {
                console.log('No FCM token found for contractor:', after.contractorId);
                return null;
            }
            
            // Prepare notification body based on status
            let body;
            switch (after.status) {
                case 'accepted':
                    body = `Your offer for ${job.title} was accepted! 🎉`;
                    break;
                case 'rejected':
                    body = `Your offer for ${job.title} was declined.`;
                    break;
                case 'counter_offer':
                    body = `Counter offer: ₪${Math.round(after.counterPrice)} for ${job.title}`;
                    break;
                default:
                    body = `Status update for ${job.title}`;
            }
            
            // Send notification
            const message = {
                notification: {
                    title: 'Offer Update',
                    body: body
                },
                data: {
                    type: 'offer_response',
                    jobId: jobId,
                    offerId: context.params.offerId,
                    status: after.status,
                    jobTitle: job.title
                },
                token: fcmToken
            };
            
            await admin.messaging().send(message);
            console.log('Offer response notification sent successfully');
            return null;
        } catch (error) {
            console.error('Error sending offer response notification:', error);
            return null;
        }
    });

/**
 * Process pending notifications from the queue
 * This is a fallback for direct notification sending
 */
exports.processPendingNotifications = functions.firestore
    .document('pendingNotifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        
        try {
            const message = {
                notification: {
                    title: notification.notification.title,
                    body: notification.notification.body
                },
                data: notification.data || {},
                token: notification.to
            };
            
            await admin.messaging().send(message);
            console.log('Queued notification sent successfully');
            
            // Delete the processed notification
            await snap.ref.delete();
            return null;
        } catch (error) {
            console.error('Error processing queued notification:', error);
            
            // Mark as failed
            await snap.ref.update({
                status: 'failed',
                error: error.message
            });
            return null;
        }
    });

