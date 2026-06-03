import {HttpsError} from "firebase-functions/v2/https";

export const USERNAME_RE = /^[a-zA-Z0-9_]{3,20}$/;
export const MIN_PASSWORD = 8;

/**
 * Validate username and password, throwing an HttpsError when invalid.
 * @param {unknown} username Raw username from the request.
 * @param {unknown} password Raw password from the request.
 */
export function assertValidCredentials(
  username: unknown,
  password: unknown,
): asserts username is string {
  if (typeof username !== "string" || !USERNAME_RE.test(username)) {
    throw new HttpsError(
      "invalid-argument",
      "Username must be 3-20 letters, digits, or underscores.",
    );
  }

  assertValidPassword(password);
}

/**
 * Validate a password, throwing an HttpsError when too short.
 * @param {unknown} password Raw password from the request.
 */
export function assertValidPassword(
  password: unknown,
): asserts password is string {
  if (typeof password !== "string" || password.length < MIN_PASSWORD) {
    throw new HttpsError(
      "invalid-argument",
      `Password must be at least ${MIN_PASSWORD} characters.`,
    );
  }
}
