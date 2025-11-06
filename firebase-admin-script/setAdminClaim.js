const admin = require("firebase-admin");

// Initialize the Firebase Admin SDK with your service account
const serviceAccount = require("./mubs-locator-firebase-adminsdk-fbsvc-7a7c735ec6.json"); // Replace with your service account file name

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Function to set the admin claim for a user
async function setAdminClaim(uid) {
  try {
    // Set custom user claim
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    console.log(`Admin claim set for user ${uid}`);

    // Verify the claim was set
    const user = await admin.auth().getUser(uid);
    console.log("User custom claims:", user.customClaims);
  } catch (error) {
    console.error("Error setting custom claim:", error);
  }
}
// Replace 'USER_UID' with the actual UID of the user
const userUid = "0QeBxEgowfToV60e6UT55VJqOF42"; // Replace with the actual UID
setAdminClaim(userUid).then(() => process.exit());
