import 'dart:ui';
import 'package:aadanpradaan/pages/1s_Page/home_page.dart';
import 'package:aadanpradaan/pages/2nd_page/2nd_Page.dart';
import 'package:aadanpradaan/pages/2nd_page/userchatPage.dart';
import 'package:aadanpradaan/pages/4th_page/menu%20page.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  int _currentIndex = 0;
  late LiquidController _liquidController;

  @override
  void initState() {
    _liquidController = LiquidController();
    super.initState();
  }

  final List<Widget> pages = [
    const Home(),
    const MessengerChatListPage(),
    const menuPage()
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _liquidController.animateToPage(page: index, duration: 70);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidSwipe(
        pages: pages,
        enableLoop: false,
        slideIconWidget:  Icon(Icons.back_hand),
        liquidController: _liquidController,
        onPageChangeCallback: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  void dispose() {
    // _liquidController.dispose();
    super.dispose();
  }
}
