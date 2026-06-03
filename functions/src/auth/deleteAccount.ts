import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import * as bcrypt from "bcryptjs";

export const deleteAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const uid = request.auth.uid;
  const password = String(request.data?.password ?? "");
  const db = getFirestore();

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();

  // Username accounts must prove ownership with their password.
  if (userSnap.get("authProvider") === "username") {
    const usernameLower = String(userSnap.get("username") ?? "").toLowerCase();
    const credRef = db.collection("credentials").doc(usernameLower);
    const passwordHash = (await credRef.get()).get("passwordHash") as
      | string
      | undefined;
    const matches = passwordHash ?
      await bcrypt.compare(password, passwordHash) :
      false;

    if (!matches) {
      throw new HttpsError("invalid-argument", "Password is incorrect.");
    }

    await credRef.delete();
    await db.collection("loginAttempts").doc(usernameLower).delete();
  }

  // Wipe the user doc and its subcollections (reminders, timetable, profile).
  await db.recursiveDelete(userRef);

  // Remove the auth account last so an earlier failure can be retried.
  await getAuth().deleteUser(uid);

  return {success: true};
});
