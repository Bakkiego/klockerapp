import 'package:flutter/material.dart';
import 'package:klockerapp/screens/inbox.dart';
import 'package:klockerapp/screens/calendar.dart';
import 'package:klockerapp/screens/menu.dart';
import 'package:klockerapp/screens/home_screen.dart';

class BottomNav extends StatefulWidget {
  static String id = 'bottom_nav';
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  int navIndex = 0;
  final screens = [HomeScreen(), Inbox(), Calendar(), Menu()];
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(left: 25.0),
          child: Text("Home"),
        ),
        leading: Image.asset('images/logo.png'),
        actions: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('images/user.jpeg'),
          ),
        ],
      ),
      body: IndexedStack(index: navIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (index) {
          setState(() {
            navIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
