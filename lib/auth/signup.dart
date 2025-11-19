// lib/components/signup.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kDarkGreen = Color(0xFF004643);

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // extra fields
  String _sex = 'Rather not say';
  DateTime? _birthday;
  bool _isTosAccepted = false;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Strong password: 8+, upper, lower, digit, special
  bool _isStrong(String v) {
    final strong = RegExp(
      r'''^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-=\[\]{};:'"\\|,.<>/?]).{8,}$''',
    );
    return strong.hasMatch(v);
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Signup failed (${e.code}).';
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(1900);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select your birthday',
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isTosAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service.')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      // 1) create auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // optional display name
      await cred.user?.updateDisplayName(_usernameCtrl.text.trim());

      // 2) write firestore user profile
      final uid = cred.user!.uid;
      final users = FirebaseFirestore.instance.collection('users');

      await users.doc(uid).set({
        'uid': uid,
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'fullName': _fullNameCtrl.text.trim(),
        'sex': _sex, // 'Male' | 'Female' | 'Rather not say'
        'birthday': _birthday != null
            ? Timestamp.fromDate(DateTime(
            _birthday!.year, _birthday!.month, _birthday!.day))
            : null,
        'isTosAccepted': _isTosAccepted,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please sign in.')),
      );
      Navigator.of(context).pop(); // back to login
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grey = const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo + Wordmark
                    Image.asset('assets/GardenCityLogo.png',
                        width: 200, height: 100, fit: BoxFit.contain),
                    const SizedBox(height: 8),
                    Image.asset('assets/GardenCityText.png',
                        height: 40, fit: BoxFit.contain),
                    const SizedBox(height: 28),

                    Text(
                      'Create new account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kDarkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Username
                    _label('Username'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a username';
                        }
                        if (v.trim().length < 3) {
                          return 'Minimum 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    _label('Full Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Juan Dela Cruz',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _label('Email Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email address',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                        if (!ok) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _label('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        hintText:
                        'Min 8 chars, upper, lower, number, special',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter a password';
                        }
                        if (!_isStrong(v)) {
                          return 'Use 8+ chars, upper, lower, number, special';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _label('Confirm Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (v != _passCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sex
                    _label('Sex'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _sex,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(
                            value: 'Rather not say',
                            child: Text('Rather not say')),
                      ],
                      onChanged: (v) => setState(() => _sex = v ?? _sex),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Birthday
                    _label('Birthday'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickBirthday,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.cake_outlined),
                          hintText: 'Select your birth date',
                        ),
                        child: Text(
                          _birthday == null
                              ? 'Tap to choose'
                              : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ToS
                    Row(
                      children: [
                        Checkbox(
                          value: _isTosAccepted,
                          onChanged: (v) =>
                              setState(() => _isTosAccepted = v ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'I accept the Terms of Service',
                            style: TextStyle(fontSize: 13),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Sign Up
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: kDarkGreen,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: kDarkGreen,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}
