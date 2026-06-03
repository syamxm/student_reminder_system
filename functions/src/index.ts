import {setGlobalOptions} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";

initializeApp();

setGlobalOptions({region: "asia-southeast1", maxInstances: 10});

export {signupWithUsername} from "./auth/signup";
export {loginWithUsername} from "./auth/login";
export {changePassword} from "./auth/changePassword";
export {deleteAccount} from "./auth/deleteAccount";
