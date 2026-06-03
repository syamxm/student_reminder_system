import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import * as bcrypt from "bcryptjs";
import {assertValidPassword} from "./validation";

const SALT_ROUNDS = 10;

export const changePassword = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const data = request.data ?? {};
  const oldPassword = String(data.oldPassword ?? "");
  const newPassword = String(data.newPassword ?? "");

  assertValidPassword(newPassword);

  const uid = request.auth.uid;
  const db = getFirestore();

  const userSnap = await db.collection("users").doc(uid).get();
  if (userSnap.get("authProvider") !== "username") {
    throw new HttpsError(
      "failed-precondition",
      "This account has no password.",
    );
  }

  const username = userSnap.get("username") as string;
  const usernameLower = username.toLowerCase();
  const credRef = db.collection("credentials").doc(usernameLower);
  const credSnap = await credRef.get();

  const passwordHash = credSnap.get("passwordHash") as string | undefined;
  const matches = passwordHash ?
    await bcrypt.compare(oldPassword, passwordHash) :
    false;

  if (!matches) {
    throw new HttpsError(
      "invalid-argument",
      "Current password is incorrect.",
    );
  }

  await credRef.update({
    passwordHash: await bcrypt.hash(newPassword, SALT_ROUNDS),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {success: true};
});
