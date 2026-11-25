import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TelaCarregamento();
        }
        if (snapshot.data != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class _TelaCarregamento extends StatelessWidget {
  const _TelaCarregamento();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.explore_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Passaporte',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
