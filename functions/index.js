const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

// ============================================================
// Function 1: Request Password Reset Code
// ============================================================
exports.requestPasswordResetCode = onCall(async (request) => {
  const email = request.data.email;

  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required");
  }

  try {
    // 1. Check if user exists
    const user = await admin.auth().getUserByEmail(email);

    // 2. Generate 4-digit code
    const code = Math.floor(1000 + Math.random() * 9000).toString();

    // 3. Hash the code for security
    const codeHash = crypto.createHash("sha256").update(code).digest("hex");

    // 4. Store in Firestore with 10-minute expiration
    await admin.firestore().collection("password_resets").doc(user.uid).set({
      email: email,
      codeHash: codeHash,
      expiresAt: Date.now() + 10 * 60 * 1000, // 10 minutes
      used: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 5. Send email with the code
    // FOR NOW: Just log it (we'll add email sending next)
    console.log(`🔑 Reset code for ${email}: ${code}`);

    // TODO: Send actual email here (we'll add this in the next step)
    // For now, we'll just return success
    // In production, you MUST send this via email, not return it!

    return {
      success: true,
      message: "Reset code sent to email",
      // REMOVE THIS IN PRODUCTION - only for testing:
      debugCode: code,
    };
  } catch (error) {
    console.error("Error in requestPasswordResetCode:", error);
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "No account found with that email");
    }
    throw new HttpsError("internal", "Failed to send reset code");
  }
});

// ============================================================
// Function 2: Verify Code and Reset Password
// ============================================================
exports.verifyPasswordResetCode = onCall(async (request) => {
  const {email, code, newPassword} = request.data;

  if (!email || !code || !newPassword) {
    throw new HttpsError(
        "invalid-argument",
        "Email, code, and new password are required",
    );
  }

  try {
    // 1. Get user
    const user = await admin.auth().getUserByEmail(email);

    // 2. Get reset document
    const docRef = admin.firestore().collection("password_resets").doc(user.uid);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "No reset request found");
    }

    const data = doc.data();

    // 3. Check if already used
    if (data.used) {
      throw new HttpsError("failed-precondition", "Code already used");
    }

    // 4. Check if expired
    if (Date.now() > data.expiresAt) {
      throw new HttpsError("failed-precondition", "Code has expired");
    }

    // 5. Verify code
    const codeHash = crypto.createHash("sha256").update(code).digest("hex");
    if (codeHash !== data.codeHash) {
      throw new HttpsError("permission-denied", "Invalid code");
    }

    // 6. Update password
    await admin.auth().updateUser(user.uid, {
      password: newPassword,
    });

    // 7. Mark code as used
    await docRef.update({used: true});

    console.log(`✅ Password reset successful for ${email}`);

    return {
      success: true,
      message: "Password reset successful",
    };
  } catch (error) {
    console.error("Error in verifyPasswordResetCode:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal", "Failed to reset password");
  }
});