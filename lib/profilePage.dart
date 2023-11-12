import 'package:blytzwow/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assurez-vous d'avoir firebase_auth dans vos dépendances.
import 'package:firebase_storage/firebase_storage.dart'; // Pour le stockage de l'image de profil.
import 'package:cloud_firestore/cloud_firestore.dart'; // Si vous stockez des données utilisateur dans Firestore.


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthenticationWrapper()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
      ),
      body: userData == null ? Center(child: CircularProgressIndicator()) : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (userData!['profile_picture_url'] != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(userData!['profile_picture_url']),
              )
            else
              Icon(
                Icons.account_circle,
                size: 60,
                color: Colors.grey[400],
              ),
            SizedBox(height: 15),
            Text('Nom d\'utilisateur: ${userData?['username'] ?? 'Non disponible'}'),
            SizedBox(height: 5),
            Text('Email: ${userData?['email'] ?? 'Non disponible'}'),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: _signOut,
              child: Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

