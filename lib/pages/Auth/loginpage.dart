import 'dart:developer';

import 'package:aadanpradaan/pages/Auth/signuppage.dart';
import 'package:aadanpradaan/startpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool see = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  int _tabTextIndexSelected = 0;

  Future<User?> loginUser() async {
    final userEmail = email.text.trim();
    final userPassword = password.text;

    if (userEmail.isEmpty || userPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter both email and password");
      return null;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );

      final User? user = userCredential.user;

      final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      final userData = userSnapshot.data() as Map<String, dynamic>?;
      log("User data: $userData");

      Fluttertoast.showToast(msg: "Login successful");

      if (_tabTextIndexSelected == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Mainpage()),
        );
      }

      return user;
    } catch (e) {
      String errorMessage = "Login failed";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No user found with this email";
            break;
          case 'wrong-password':
            errorMessage = "Incorrect password";
            break;
          case 'invalid-email':
            errorMessage = "Invalid email format";
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      Fluttertoast.showToast(msg: errorMessage);
      print("Login Error: $e");
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset("assets/logo.png", width: 300, height: 300),
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
                    fillColor: Colors.white,
                    label: Text("Password"),
                    hintText: "Enter your Password",
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
                  child: ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(20, 20),
                      padding: EdgeInsets.symmetric(horizontal: 65, vertical: 13),
                      backgroundColor: Colors.greenAccent.shade700,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    child: Text("Login"),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text("Forget password?", style: TextStyle(fontSize: 12)),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => signup()));
                    },
                    child: Text("Don't have a account?", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}