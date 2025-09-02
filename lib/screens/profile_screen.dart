import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameCtrl;
  late final TextEditingController genderCtrl;
  late final TextEditingController dobCtrl;
  late final TextEditingController heightCtrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    nameCtrl = TextEditingController(text: user?.displayName ?? '');
    genderCtrl = TextEditingController(text: user?.gender ?? '');
    dobCtrl = TextEditingController(text: user?.dob ?? '');
    heightCtrl = TextEditingController(text: user?.height ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    genderCtrl.dispose();
    dobCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final updated = UserProfile(
      uid: user.uid,
      displayName: nameCtrl.text.trim(),
      email: user.email,
      gender: genderCtrl.text.trim(),
      dob: dobCtrl.text.trim(),
      height: heightCtrl.text.trim(),
    );

    final messenger = ScaffoldMessenger.of(context);

    try {
      await auth.updateProfile(updated);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4EA), Color(0xFFD0F0C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : 'U',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: genderCtrl,
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            TextField(
              controller: dobCtrl,
              decoration: const InputDecoration(labelText: 'DOB'),
            ),
            TextField(
              controller: heightCtrl,
              decoration: const InputDecoration(labelText: 'Height'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
