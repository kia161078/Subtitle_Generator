import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:subtitle/screens/login_screen.dart';
import 'register_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final TextEditingController nameController =
        TextEditingController(text: user?.displayName ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1430),
        title: const Text('Edit Display Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new display name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00F0FF)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBC13FE)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () async {
              try {
                setState(() => _isLoading = true);
                
                
                await user?.updateDisplayName(nameController.text.trim());
                await user?.reload();
                
                setState(() {
                  user = FirebaseAuth.instance.currentUser;
                  _isLoading = false;
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }

  
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1430),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await user?.delete();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        if (e.code == 'requires-recent-login') {
        
          _reauthenticateAndDelete(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _reauthenticateAndDelete(BuildContext context) async {
    final passwordController = TextEditingController();
    final passwordConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1430),
        title: const Text('Re-authentication Required', style: TextStyle(color: Colors.orangeAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This operation is sensitive. Please enter your password to confirm account deletion.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFBC13FE)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (passwordConfirm == true && passwordController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
       
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: passwordController.text.trim(),
        );

       
        await user?.reauthenticateWithCredential(credential);
        
        
        await user?.delete();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
          (route) => false,
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Re-authentication failed: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1430),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1430),
        title: const Text('Cyber Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBC13FE)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
             
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFBC13FE),
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.displayName ?? 'No Username',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No Email',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cyberpunk User Status: Active',
                          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),

                 
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF00F0FF)),
                    title: const Text('Edit Profile / Display Name', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Change your profile details', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Color(0xFFBC13FE)),
                    title: const Text('Reset Password', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Send password recovery email', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () async {
                      if (user?.email != null) {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent! Check your inbox.'), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orangeAccent),
                    title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Sign out from this account', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent)),
                    subtitle: const Text('Permanently remove your account data', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () => _deleteAccount(context),
                  ),
                ],
              ),
            ),
    );
  }
}