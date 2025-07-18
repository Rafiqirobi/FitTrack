import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '', confirmPassword = '';
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        User? user = await AuthService().registerWithEmail(email, password);
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email'),
                      onChanged: (val) => email = val,
                      validator: (val) => val!.isEmpty ? 'Enter email' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      onChanged: (val) => password = val,
                      validator: (val) =>
                          val!.length < 6 ? 'Password too short' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Confirm Password'),
                      obscureText: true,
                      onChanged: (val) => confirmPassword = val,
                      validator: (val) =>
                          val!.length < 6 ? 'Confirm password' : null,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCCFF00),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Register'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
