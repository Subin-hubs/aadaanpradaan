import 'package:aadanpradaan/pages/1s_Page/contribution.dart';
import 'package:aadanpradaan/pages/1s_Page/resources.dart';
import 'package:aadanpradaan/pages/1s_Page/takePage.dart';
import 'package:aadanpradaan/pages/4th_page/menu%20page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../2nd_page/userchatPage.dart';
import 'givepage.dart'; // Make sure this file exists

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> serviceCategories = [
    {'icon': Icons.book_sharp, 'label': 'Give'},
    {'icon': Icons.book_sharp, 'label': 'Take'},
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.list, 'label': 'My resources'}
  ];

  void handleNavigation(String label) {
    switch (label) {
      case 'Give':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GivePage()),
        );
      case 'Take':
        Navigator.push(context, MaterialPageRoute(builder: (context)=>TakePage()));
      case 'My resources':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> MyResourcesPage()));
      case 'Dashboard':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeDashboardPage()));

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Handle case where user is not authenticated
    if (currentUser == null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: const Center(
            child: Text("Please log in to continue"),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
              child: Center(
                child: Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text("Hello...");
                        }
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        String fname = data['fname'] ?? '';
                        return Text(
                          "Hello $fname",
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
              child: SizedBox(
                height: 50,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search any things",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: serviceCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final item = serviceCategories[index];
                    return GestureDetector(
                      onTap: () => handleNavigation(item['label']),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'],
                                size: 40,
                                color: Colors.greenAccent.shade700),
                            const SizedBox(height: 8),
                            Text(
                              item['label'],
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}