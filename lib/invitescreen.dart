import 'package:blytzwow/mainPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class UserInvitePage2 extends StatefulWidget {
  final String eventID;
  UserInvitePage2(this.eventID);

  @override
  _UserInvitePage2State createState() => _UserInvitePage2State();
}

class _UserInvitePage2State extends State<UserInvitePage2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  final CollectionReference followersRef = FirebaseFirestore.instance.collection('followers');
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> selectedUsers = {};  // Nouvelle map pour suivre les utilisateurs sélectionnés.
  bool _isLoading = true;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _focusNode.addListener(() {
      setState(() {});
    });
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = false; // supposer que les données sont chargées
    });
  }

  Future<void> inviteUserToEvent(String userIdToInvite) async {
    await _firestore.collection('invitations').add({
      'userId': userIdToInvite,
      'eventId': widget.eventID,
      'status': 'en attente', // initial status
    });
  }

  Future<void> inviteSelectedUsers() async {
    for (var entry in selectedUsers.entries) {
      if (entry.value) {  // Si l'utilisateur est sélectionné.
        await inviteUserToEvent(entry.key);
      }
    }
  }

  String _nextString(String str) {
    // Cette fonction trouve le codePoint unicode le plus élevé dans la chaîne et le remplace par le caractère suivant.
    if (str == '') return str;
    int lastChar = str.codeUnitAt(str.length - 1);
    String nextString = str.substring(0, str.length - 1) + String.fromCharCode(lastChar + 1);
    return nextString;
  }

  Future<bool> isUserAlreadyInvited(String userId) async {
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: widget.eventID)
        .get();

    // Si la requête retourne au moins un document, cela signifie que l'invitation existe.
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('BLITZ', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: () async {
              await inviteSelectedUsers();  // Inviter les utilisateurs lorsque le bouton est appuyé.
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainPage()));
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: _focusNode.hasFocus
                  ? Border.all(
                color: Colors.black,
                width: 3.0,  // Augmenter la largeur de la bordure
              )
                  : Border.all(
                color: Colors.black45,
                width: 3.0,  // Augmenter la largeur de la bordure
              ),
              boxShadow: [
                if (_focusNode.hasFocus)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5.0,
                  ),
              ],
              borderRadius: BorderRadius.circular(15.0),  // Augmenter le rayon pour des coins plus arrondis
            ),
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              cursorColor: Colors.black,  // Changement de la couleur du curseur
              style: TextStyle(
                color: Colors.black,  // Changement de la couleur du texte
              ),
              decoration: InputDecoration(
                icon: _focusNode.hasFocus || _searchController.text.isNotEmpty
                    ? null
                    : Icon(Icons.search),
                labelText: 'Rechercher',
                labelStyle: TextStyle(
                  color: Colors.black, // Changement de la couleur du labelText
                ),
                suffixIcon: _focusNode.hasFocus || _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchTerm = '';
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
            ),
          ),
          // ... (votre code pour le champ de recherche reste inchangé)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: (_searchTerm.isEmpty)
                  ? followersRef.snapshots()
                  : followersRef
                  .where('followerId', isGreaterThanOrEqualTo: _searchTerm)
                  .where('followerId', isLessThan: _nextString(_searchTerm)) // Limite la recherche à des résultats pertinents
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Vous ne suivez encore personne qui commence par \"$_searchTerm\""));
                }
                var followingList = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: followingList.length,
                  itemBuilder: (context, index) {
                    var following = followingList[index];
                    var followingUserId = following['followingId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: usersRef.doc(followingUserId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        var user = snapshot.data!;
                        var username = user['username'];
                        var userPhotoURL = user['profile_picture_url'];

                        final isSelected = selectedUsers[followingUserId] ?? false;

                        return ListTile(
                          tileColor: isSelected ? Colors.black : null,  // Changer la couleur si sélectionné.
                          title: Text(username, style: isSelected? TextStyle(color: Colors.white, fontWeight: FontWeight.w500) : TextStyle(color: Colors.black, fontWeight: FontWeight.w500)) ,
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(userPhotoURL),

                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: isSelected ? Colors.white : Colors.black,
                              // Changer la couleur si sélectionné.
                            ),
                            onPressed: () {
                              setState(() {
                                // Mettre à jour l'état de sélection.
                                selectedUsers[followingUserId] = !isSelected;
                              });
                            },
                            child: Text(isSelected ? 'Sélectionné' : 'Sélectionner', style: isSelected? TextStyle(color: Colors.black, fontWeight: FontWeight.w400) : TextStyle(color: Colors.white, fontWeight: FontWeight.w300),),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class UserInvitePage extends StatefulWidget {
  final String eventID;
  UserInvitePage(this.eventID);

  @override
  _UserInvitePage2State createState() => _UserInvitePage2State();
}

class _UserInvitePageState extends State<UserInvitePage2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  final CollectionReference followersRef = FirebaseFirestore.instance.collection('followers');
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> selectedUsers = {};
  bool _isLoading = true;
  FocusNode _focusNode = FocusNode();
  late Timer _debounce;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _focusNode.addListener(() {
      setState(() {});
    });
    _initializeData();
    _debounce = Timer(const Duration(milliseconds: 500), () {});
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce.isActive) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Faites quelque chose si nécessaire
    });
  }

  Future<void> inviteUserToEvent(String userIdToInvite) async {
    await _firestore.collection('invitations').add({
      'userId': userIdToInvite,
      'eventId': widget.eventID,
      'status': 'pending', // initial status
    });
  }

  Future<void> inviteSelectedUsers() async {
    for (var entry in selectedUsers.entries) {
      if (entry.value) {
        await inviteUserToEvent(entry.key);
      }
    }
  }

  String _nextString(String str) {
    if (str == '') return str;
    int lastChar = str.codeUnitAt(str.length - 1);
    String nextString = str.substring(0, str.length - 1) + String.fromCharCode(lastChar + 1);
    return nextString;
  }

  Future<bool> isUserAlreadyInvited(String userId) async {
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: widget.eventID)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _searchController.addListener(_onSearchChanged);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('BLITZ', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: () async {
              await inviteSelectedUsers();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainPage()));
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: _focusNode.hasFocus
                  ? Border.all(
                color: Colors.black,
                width: 3.0,  // Augmenter la largeur de la bordure
              )
                  : Border.all(
                color: Colors.black45,
                width: 3.0,  // Augmenter la largeur de la bordure
              ),
              boxShadow: [
                if (_focusNode.hasFocus)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5.0,
                  ),
              ],
              borderRadius: BorderRadius.circular(15.0),  // Augmenter le rayon pour des coins plus arrondis
            ),
            child: TextField(
              focusNode: _focusNode,
              controller: _searchController,
              cursorColor: Colors.black,  // Changement de la couleur du curseur
              style: TextStyle(
                color: Colors.black,  // Changement de la couleur du texte
              ),
              decoration: InputDecoration(
                icon: _focusNode.hasFocus || _searchController.text.isNotEmpty
                    ? null
                    : Icon(Icons.search),
                labelText: 'Rechercher',
                labelStyle: TextStyle(
                  color: Colors.black, // Changement de la couleur du labelText
                ),
                suffixIcon: _focusNode.hasFocus || _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchTerm = '';
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
            ),
          ),
          // ... (votre code pour le champ de recherche reste inchangé)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: (_searchTerm.isEmpty)
                  ? followersRef.snapshots()
                  : followersRef
                  .where('followerId', isGreaterThanOrEqualTo: _searchTerm)
                  .where('followerId', isLessThan: _nextString(_searchTerm)) // Limite la recherche à des résultats pertinents
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Vous ne suivez encore personne qui commence par \"$_searchTerm\""));
                }
                var followingList = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: followingList.length,
                  itemBuilder: (context, index) {
                    var following = followingList[index];
                    var followingUserId = following['followingId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: usersRef.doc(followingUserId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }
                        var user = snapshot.data!;
                        var username = user['username'];
                        var userPhotoURL = user['profile_picture_url'];

                        final isSelected = selectedUsers[followingUserId] ?? false;

                        return ListTile(
                          tileColor: isSelected ? Colors.black : null,  // Changer la couleur si sélectionné.
                          title: Text(username, style: isSelected? TextStyle(color: Colors.white, fontWeight: FontWeight.w500) : TextStyle(color: Colors.black, fontWeight: FontWeight.w500)) ,
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(userPhotoURL),

                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: isSelected ? Colors.white : Colors.black,
                              // Changer la couleur si sélectionné.
                            ),
                            onPressed: () {
                              setState(() {
                                // Mettre à jour l'état de sélection.
                                selectedUsers[followingUserId] = !isSelected;
                              });
                            },
                            child: Text(isSelected ? 'Sélectionné' : 'Sélectionner', style: isSelected? TextStyle(color: Colors.black, fontWeight: FontWeight.w400) : TextStyle(color: Colors.white, fontWeight: FontWeight.w300),),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // ... (remaining code is similar to what you provided, handle search and selection)
        ],
      ),
    );
  }
}