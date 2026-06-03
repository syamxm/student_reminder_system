import {setGlobalOptions} from "firebase-functions";
import {initializeApp} from "firebase-admin/app";

initializeApp();

setGlobalOptions({maxInstances: 10});

export {signupWithUsername} from "./auth/signup";
export {loginWithUsername} from "./auth/login";
