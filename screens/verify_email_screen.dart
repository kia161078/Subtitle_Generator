import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subtitle/screens/register_screen.dart';
import 'subtitle_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final User user;
  const VerifyEmailScreen({super.key, required this.user});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
   
    _sendVerificationEmail();


    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await widget.user.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        timer.cancel();
    
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SubtitleScreen()),
          );
        }
      }
    });
  }

  Future<void> _sendVerificationEmail() async {
    try {
      setState(() => _canResendEmail = false);
      await widget.user.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email resent!'), backgroundColor: Colors.green),
        );
      }
      
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _canResendEmail = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _canResendEmail = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending email: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1430),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 80, color: Color(0xFF00F0FF)),
            const SizedBox(height: 24),
            const Text(
              'Verify your Email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A verification link has been sent to:\n${widget.user.email}\nPlease click the link in your email to continue.',
              style: const TextStyle(fontSize: 14, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFFBC13FE)),
            const SizedBox(height: 20),
            const Text(
              'Waiting for email verification...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 40),
          
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBC13FE),
                foregroundColor: Colors.white,
              ),
              onPressed: _canResendEmail ? _sendVerificationEmail : null,
              child: const Text('Resend Email'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                }
              },
              child: const Text('Cancel / Back to Register', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}