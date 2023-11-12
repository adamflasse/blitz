import "package:blytzwow/event_creation.dart";
import "package:blytzwow/pendingInvitationScreen.dart";
import "package:blytzwow/profilePage.dart";
import "package:blytzwow/search_user.dart";
import "package:blytzwow/upcomingEvent.dart";
import "package:flutter/material.dart";

import "eventPageView.dart";

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

    appBar: AppBar(
    backgroundColor: Colors.black,

    title: Text('BLITZ', style: TextStyle(backgroundColor: Colors.white, color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),

    ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: <Widget>[
          EventPageView(),
          //UserSearchPage(),
          UpcomingEventsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (selectedIndex) {
          _pageController.jumpToPage(selectedIndex);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Page 1'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Page 2'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Page 3'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action pour le bouton
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EventCreationFlow()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}