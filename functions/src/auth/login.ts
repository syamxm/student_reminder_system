import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {
  getFirestore,
  Timestamp,
  DocumentReference,
} from "firebase-admin/firestore";
import * as bcrypt from "bcryptjs";
import {assertValidCredentials} from "./validation";

const INVALID = new HttpsError(
  "unauthenticated",
  "Invalid username or password.",
);

const MAX_ATTEMPTS = 5;
const WINDOW_MS = 15 * 60 * 1000;
// TODO: restore to 15 * 60 * 1000 before production — 1 min is a test value.
const LOCK_MS = 1 * 60 * 1000;

export const loginWithUsername = onCall(async (request) => {
  const data = request.data ?? {};
  const username = String(data.username ?? "").trim();
  const password = String(data.password ?? "");

  assertValidCredentials(username, password);

  const db = getFirestore();
  const usernameLower = username.toLowerCase();
  const attemptsRef = db.collection("loginAttempts").doc(usernameLower);

  const attempts = await attemptsRef.get();
  const lockedUntil = attempts.get("lockedUntil") as Timestamp | undefined;
  if (lockedUntil && lockedUntil.toMillis() > Date.now()) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many attempts. Try again later.",
    );
  }

  const snapshot = await db.collection("credentials").doc(usernameLower).get();
  const passwordHash = snapshot.exists ?
    (snapshot.get("passwordHash") as string) :
    null;

  const matches = passwordHash ?
    await bcrypt.compare(password, passwordHash) :
    false;

  if (!matches) {
    await recordFailure(attemptsRef);
    throw INVALID;
  }

  await attemptsRef.delete();
  const uid = snapshot.get("uid") as string;
  return {token: await getAuth().createCustomToken(uid)};
});

/**
 * Record a failed login attempt and lock the account after too many.
 * @param {DocumentReference} attemptsRef Reference to the attempts doc.
 */
async function recordFailure(attemptsRef: DocumentReference): Promise<void> {
  await getFirestore().runTransaction(async (tx) => {
    const doc = await tx.get(attemptsRef);
    const now = Date.now();
    const windowStart =
      (doc.get("windowStart") as Timestamp | undefined)?.toMillis() ?? now;
    const inWindow = now - windowStart < WINDOW_MS;
    const count = (inWindow ? ((doc.get("count") as number) ?? 0) : 0) + 1;

    if (count >= MAX_ATTEMPTS) {
      tx.set(attemptsRef, {
        count: 0,
        windowStart: Timestamp.fromMillis(now),
        lockedUntil: Timestamp.fromMillis(now + LOCK_MS),
      });
      return;
    }

    tx.set(attemptsRef, {
      count,
      windowStart: Timestamp.fromMillis(inWindow ? windowStart : now),
    });
  });
}
