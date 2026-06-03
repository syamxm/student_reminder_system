import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import * as bcrypt from "bcryptjs";
import {assertValidCredentials} from "./validation";

const INVALID = new HttpsError(
  "unauthenticated",
  "Invalid username or password.",
);

export const loginWithUsername = onCall(async (request) => {
  const data = request.data ?? {};
  const username = String(data.username ?? "").trim();
  const password = String(data.password ?? "");

  assertValidCredentials(username, password);

  const db = getFirestore();
  const usernameLower = username.toLowerCase();
  const snapshot = await db.collection("credentials").doc(usernameLower).get();

  if (!snapshot.exists) {
    throw INVALID;
  }

  const passwordHash = snapshot.get("passwordHash") as string;
  const matches = await bcrypt.compare(password, passwordHash);

  if (!matches) {
    throw INVALID;
  }

  const uid = snapshot.get("uid") as string;
  return {token: await getAuth().createCustomToken(uid)};
});
