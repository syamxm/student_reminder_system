import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import * as bcrypt from "bcryptjs";
import {assertValidCredentials} from "./validation";

const SALT_ROUNDS = 10;

export const signupWithUsername = onCall(async (request) => {
  const data = request.data ?? {};
  const username = String(data.username ?? "").trim();
  const password = String(data.password ?? "");
  const displayName = String(data.displayName ?? "").trim();

  assertValidCredentials(username, password);

  if (displayName.length === 0) {
    throw new HttpsError("invalid-argument", "Display name is required.");
  }

  const usernameLower = username.toLowerCase();
  const auth = getAuth();
  const db = getFirestore();

  const uid = (await auth.createUser({displayName})).uid;

  try {
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    await db.runTransaction(async (tx) => {
      const credRef = db.collection("credentials").doc(usernameLower);
      const existing = await tx.get(credRef);

      if (existing.exists) {
        throw new HttpsError("already-exists", "Username is taken.");
      }

      tx.create(credRef, {
        uid,
        username,
        passwordHash,
        createdAt: FieldValue.serverTimestamp(),
      });

      tx.set(db.collection("users").doc(uid), {
        uid,
        displayName,
        email: "",
        photoUrl: null,
        authProvider: "username",
        username,
        streakCount: 0,
        lastStreakDate: null,
        missedDeadlinesCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  } catch (error) {
    await auth.deleteUser(uid);
    throw error;
  }

  return {token: await auth.createCustomToken(uid)};
});
