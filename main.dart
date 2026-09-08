import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subtitle/firebase_options.dart';
import 'package:subtitle/screens/register_screen.dart';
import 'package:subtitle/screens/subtitle_screen.dart';
import 'package:subtitle/screens/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'What The Sub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1B1430),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)));
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            if (user.emailVerified) {
              return const SubtitleScreen();
            } else {
              return VerifyEmailScreen(user: user);
            }
          }
          return const RegisterScreen();
        },
      ),
    );
  }
}