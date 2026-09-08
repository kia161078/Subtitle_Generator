import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 0; // 0: Monthly ($4.99), 1: Yearly ($49.99)
  bool _isLoading = false;
  bool _isRestoring = false;

  void _showManualPaymentDialog(BuildContext context) {
    final bool isYearly = _selectedPlan == 1;
    final String price = isYearly ? '\$49.99' : '\$4.99';
    final String planTitle = isYearly ? 'Yearly Subscription' : 'Monthly Subscription';
    final transactionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1430),
        title: Text('Manual PayPal Payment', style: TextStyle(color: Color(0xFF00F0FF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Plan: $planTitle ($price)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please send the exact amount to the following PayPal email:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const SelectableText(
              'myname@outlook.com',
              style: TextStyle(color: Color(0xFF00F0FF), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'After payment, enter your PayPal Transaction ID / Receipt code below for verification:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: transactionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter Transaction ID',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBC13FE)),
            onPressed: () async {
              if (transactionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid Transaction ID')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  
                  await FirebaseFirestore.instance.collection('payment_requests').add({
                    'uid': user.uid,
                    'email': user.email,
                    'plan': planTitle,
                    'price': price,
                    'transactionId': transactionController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'pending',
                  });
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment request submitted! We will review and activate your account soon.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium, size: 70, color: Color(0xFF00F0FF)),
          const SizedBox(height: 16),
          const Text(
            'Unlock Full AI Power',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get unlimited subtitle generations and advanced features.',
            style: TextStyle(fontSize: 14, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildFeatureRow(Icons.all_inclusive, 'Unlimited AI Subtitle Generation'),
          _buildFeatureRow(Icons.speed, 'Priority Processing Speed'),
          _buildFeatureRow(Icons.hd, 'Export in 4K & High-Res Formats'),
          _buildFeatureRow(Icons.support_agent, '24/7 VIP Customer Support'),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildPlanCard(0, 'Monthly', '\$4.99', 'per month')),
              const SizedBox(width: 16),
              Expanded(child: _buildPlanCard(1, 'Yearly', '\$49.99', 'save 20%')),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBC13FE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                shadowColor: const Color(0xFFBC13FE).withOpacity(0.6),
              ),
              onPressed: _isLoading ? null : () => _showManualPaymentDialog(context),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upgrade Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _isRestoring ? null : () async {
              setState(() => _isRestoring = true);

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                
                  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

                  if (!mounted) return;

                  if (doc.exists && (doc.data()?['isPremium'] == true)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subscription restored successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No active subscription found.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error restoring purchases: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isRestoring = false);
                }
              }
            },
            child: _isRestoring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                  )
                : const Text('Restore Purchases', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00F0FF), size: 22),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, String title, String price, String subtitle) {
    bool isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF261A45),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}