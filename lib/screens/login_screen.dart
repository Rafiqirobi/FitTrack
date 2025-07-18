import 'package:FitTrack/helpers/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool _isLoading = false;

  // ✅ Email format validation
  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(val)) return 'Enter valid email';
    return null;
  }

 void _login() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    try {
      User? user = await AuthService().signInWithEmail(email.trim(), password.trim());
      if (user != null) {
        print('Login succeeded for user: ${user.uid}');
        await SessionManager.saveUserSession(isLoggedIn: true, uid: user.uid);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });

        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful!')),
          );
        });
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



  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      User? user = await AuthService().signInWithGoogle();
      if (user != null) {
        await SessionManager.saveUserSession(isLoggedIn: true, uid: user.uid);
        Navigator.pushReplacementNamed(context, '/home'); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFFCCFF00),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => email = val,
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      onChanged: (val) => password = val,
                      validator: (val) =>
                          val != null && val.length < 6 ? 'Password too short' : null,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCCFF00),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _login,
                      child: Text('Login'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.login),
                      label: Text("Sign in with Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loginWithGoogle,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text("Don't have an account? Register"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
