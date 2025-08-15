import 'package:aadanpradaan/pages/Auth/loginpage.dart';
import 'package:aadanpradaan/startpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../1s_Page/home_page.dart';

class signup extends StatefulWidget {
  const signup({super.key});

  @override
  State<signup> createState() => _signupState();
}

class _signupState extends State<signup> {
  TextEditingController fullName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool see = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registeruser() async {
    final name = fullName.text.trim();
    final userEmail = email.text.trim();
    final userPassword = password.text;

    if (name.isEmpty || userEmail.isEmpty || userPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in all fields");
      return;
    }

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      final User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fname': name,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(msg: "Account created successfully");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Mainpage()),
        );
      }
    } catch (e) {
      String errorMessage = "Registration failed";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "Email is already registered";
            break;
          case 'weak-password':
            errorMessage = "Password is too weak";
            break;
          case 'invalid-email':
            errorMessage = "Invalid email format";
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      Fluttertoast.showToast(msg: errorMessage);
      print("Registration error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 75),
                    child: Text(
                      "Sign Up ",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.greenAccent.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 50, left: 35, right: 35),
                    child: TextFormField(
                      controller: fullName,
                      decoration: InputDecoration(
                        filled: true,
                        label: Text("Full Name"),
                        hintText: "Enter your Name",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 35, right: 35),
                    child: TextFormField(
                      controller: email,
                      decoration: InputDecoration(
                        filled: true,
                        label: Text("Email"),
                        hintText: "Enter your email",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 35, right: 35),
                    child: TextFormField(
                      controller: password,
                      obscureText: !see,
                      decoration: InputDecoration(
                        filled: true,
                        label: Text("Password"),
                        hintText: "Enter your password",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              see = !see;
                            });
                          },
                          icon: Icon(see ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: ElevatedButton(
                      onPressed: registeruser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(20, 20),
                        padding: EdgeInsets.symmetric(horizontal: 65, vertical: 13),
                        backgroundColor: Colors.greenAccent.shade700,
                        textStyle: TextStyle(fontSize: 12),
                      ),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => loginPage()),
                        );
                      },
                      child: Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}