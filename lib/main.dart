import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '958691525428-ic7ht1ntcn24b3qf8ome5ld3l021b7t4.apps.googleusercontent.com',
    );
  }

  runApp(const StudentReminderApp());
}
