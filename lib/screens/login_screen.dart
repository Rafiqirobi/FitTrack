import 'package:FitTrack/helpers/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  
  const LoginScreen({super.key, this.initialEmail});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  String email = '', password = '';
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    email = widget.initialEmail ?? '';
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  //  Email format validation
  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(val)) return 'Enter valid email';
    return null;
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricLoginEnabled();
      setState(() {
        _isBiometricAvailable = available;
        _isBiometricEnabled = enabled;
      });
    } catch (e) {
      print('Error checking biometric availability: $e');
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _biometricService.biometricLogin();
      if (user != null) {
        print('Biometric login succeeded for user: ${user.uid}');
        await SessionManager.saveUserSession(isLoggedIn: true, uid: user.uid);

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/navBottomBar');
          });

          Future.microtask(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric login successful!')),
            );
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed')),
          );
        }
      }
    } catch (e) {
      print('Biometric login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showBiometricSetupDialog(String email) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Biometric Login'),
          content: const Text(
            'Would you like to enable fingerprint or face recognition for faster login next time?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to main app
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/navBottomBar');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login successful!')),
                );
              },
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _biometricService.setupBiometricLogin(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric login enabled!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to enable biometric login: $e')),
                    );
                  }
                }
                // Navigate to main app
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacementNamed(context, '/navBottomBar');
                  });
                }
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        User? user = await AuthService().signInWithEmail(email.trim(), password.trim());
        if (user != null) {
          print('Login succeeded for user: ${user.uid}');
          await SessionManager.saveUserSession(isLoggedIn: true, uid: user.uid);

          // Check if biometric is available and offer to set it up
          if (_isBiometricAvailable && !_isBiometricEnabled) {
            if (mounted) {
              _showBiometricSetupDialog(user.email!);
            }
          } else {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/navBottomBar');
              });

              Future.microtask(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login successful!')),
                );
              });
            }
          }
        } else {
          print('Login returned null user');
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Title
                    Text(
                      'FitTrack',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (val) => email = val,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              ),
                            ),
                            obscureText: true,
                            onChanged: (val) => password = val,
                            validator: (val) => val != null && val.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 32),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _login,
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Biometric Login Button (only show if available and enabled)
                          if (_isBiometricAvailable && _isBiometricEnabled)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Sign In with Biometrics'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  foregroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _biometricLogin,
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // Register Link
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.grey[600]),
                                children: [
                                  TextSpan(
                                    text: "Sign Up",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
