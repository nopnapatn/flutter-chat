import 'dart:io';

import 'package:chat/views/widgets/custom_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || _selectedImage == null) {
      // show error message ...
      return;
    }

    _form.currentState!.save();

    try {
      final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${userCredentials.user!.uid}.jpg');

      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredentials.user!.uid)
          .set({
        'username': _usernameController.text,
        'email': _emailController.text,
        'image_url': imageUrl,
      });
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImagePicker(
                  onPickImage: (pickedImage) {
                    _selectedImage = pickedImage;
                  },
                ),
                Text(
                  'Welcome back you\'ve been missed!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length < 4) {
                      return 'Please enter at least 4 characters.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _usernameController.text = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _emailController.text = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _passwordController.text = value!;
                  },
                ),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
