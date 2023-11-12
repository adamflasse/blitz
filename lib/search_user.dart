import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSearchPage extends StatefulWidget {

  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');
  final CollectionReference followersRef = FirebaseFirestore.instance.collection('followers');

  bool _isLoading = true;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    _initializeData();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void followUser(String userIdToFollow) {
    if (currentUser != null) {
      followersRef.add({
        'followerId': currentUser!.uid,
        'followingId': userIdToFollow,
      });
    }
  }

  void unfollowUser(String userIdToUnfollow) {
    if (currentUser != null) {
      followersRef
          .where('followerId', isEqualTo: currentUser!.uid)
          .where('followingId', isEqualTo: userIdToUnfollow)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((document) {
          document.reference.delete();
        });
      });
    }
  }

  String _nextString(String str) {
    // UTF-8 string are represented in a list of code units.
    // 'last' gives the last character of the string, and 'replaceRange' is used to modify a substring.
    return str.substring(0, str.length - 1) + String.fromCharCode(str.codeUnitAt(str.length - 1) + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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


          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: (_searchTerm.isEmpty)
                  ? usersRef.snapshots()
                  : usersRef
                  .where('username', isGreaterThanOrEqualTo: _searchTerm)
                  .where('username', isLessThan: _nextString(_searchTerm)) // Limite la recherche à des résultats pertinents
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No users found."));
                }
                var usersList = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: usersList.length,
                  separatorBuilder: (BuildContext context, int index) => Divider(),
                  itemBuilder: (context, index) {
                    var user = usersList[index];
                    var userId = user.id;
                    var username = user['username'];
                    var userPhotoURL = user['profile_picture_url'];

                    bool isCurrentUser = currentUser?.uid == userId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userPhotoURL),
                      ),
                      title: Text(
                        username,
                        style: TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: isCurrentUser
                          ? null
                          : FutureBuilder<QuerySnapshot>(
                        future: followersRef
                            .where('followerId', isEqualTo: currentUser!.uid)
                            .where('followingId', isEqualTo: userId)
                            .get(),
                        builder: (context, snapshot) {
                          var firstDoc = snapshot.data?.docs.isNotEmpty == true ? snapshot.data!.docs.first : null;
                          bool following = firstDoc?.exists ?? false;

                          return ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (following) {
                                  unfollowUser(userId);
                                } else {
                                  followUser(userId);
                                }
                              });
                            },
                            child: Text(following ? 'Unfollow' : 'Follow'),
                            style: ElevatedButton.styleFrom(
                              primary: following ? Colors.grey : Colors.blue,
                            ),
                          );
                        },
                      ),
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
