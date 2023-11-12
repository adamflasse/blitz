import 'package:blytzwow/detailedInvitationPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingInvitationsPage extends StatefulWidget {
  @override
  _PendingInvitationsPageState createState() => _PendingInvitationsPageState();
}

class _PendingInvitationsPageState extends State<PendingInvitationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser; // Obtenir l'utilisateur actuellement connecté

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Invitations en attente'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('invitations')
              .where('status', isEqualTo: 'en attente')
              .where('userId', isEqualTo: currentUser?.uid) // Filtrer par l'utilisateur actuellement connecté
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("Aucune invitation en attente."));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var invitation = snapshot.data!.docs[index];

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: Future.wait([
                    _firestore.collection('users').doc(invitation['userId']).get(),
                    _firestore.collection('events').doc(invitation['eventId']).get(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return Center(child: Text("Erreur de chargement des données."));
                    }
                    String day = '';
                    String month = '';

                    var userDataMap = snapshot.data![0].data() as Map<String, dynamic>;
                    var eventDataMap = snapshot.data![1].data() as Map<String, dynamic>;
                    if (eventDataMap.containsKey('date')) {
                      DateTime date = eventDataMap['date'].toDate();
                      day = date.day < 10 ? '0${date.day}' : '${date.day}'; // Ajoutez un zéro si le jour est inférieur à 10
                      month = date.month < 10 ? '0${date.month}' : '${date.month}'; // Ajoutez un zéro si le mois est inférieur à 10
                    }

                    var profilePictureUrl = userDataMap.containsKey('profile_picture_url') ? userDataMap['profile_picture_url'] : null;
                    var username = userDataMap.containsKey('username') ? userDataMap['username'] : 'N/A';
                    var eventName = eventDataMap.containsKey('name') ? eventDataMap['name'] : 'N/A';
                    var adminId = eventDataMap.containsKey('adminId') ? eventDataMap['adminId'] : 'N/A';
                    var eventDate = eventDataMap.containsKey('date') ? '$day/$month' : 'N/A';
                    var location = eventDataMap.containsKey('location') ? eventDataMap['location'] : 'N/A';

                    // Effectuer une requête supplémentaire pour obtenir les informations de l'administrateur
                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('users').doc(adminId).get(),
                      builder: (context, adminSnapshot) {
                        if (adminSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!adminSnapshot.hasData) {
                          return Text("Impossible de charger les données de l'administrateur.");
                        }

                        var adminData = adminSnapshot.data!.data() as Map<String, dynamic>;
                        var adminName = adminData.containsKey('username') ? adminData['username'] : 'N/A';

                        return GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvitationDetailsPage(
                                  invitationData: invitation,

                                  eventData: eventDataMap, // passez les données d'événement appropriées
                                  userData: userDataMap, // passez les données utilisateur appropriées
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.white, // Couleur de fond de la ListTile
                              border: Border.all(color: Colors.black), // Bordure noire
                              borderRadius: BorderRadius.circular(15.0), // Bords arrondis
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl) : null,
                              ),
                              title: Container(
                                color: Colors.black, // Bande noire pour le titre
                                padding: EdgeInsets.symmetric(vertical: 5.0), // Espacement vertical pour le titre
                                child: Text(
                                  eventName,
                                  style: TextStyle(
                                    color: Colors.white, // Titre en blanc
                                    fontWeight: FontWeight.bold, // Texte en gras
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10.0), // Espacement supplémentaire pour la lisibilité
                                  Text('Par : $adminName'),
                                  SizedBox(height: 5.0), // Espacement entre les éléments
                                  Row(
                                    children: <Widget>[
                                      Icon(Icons.calendar_today, color: Colors.black, size: 20.0), // Icône de calendrier pour la date
                                      SizedBox(width: 5.0), // Espacement entre l'icône et le texte
                                      Text(eventDate),
                                    ],
                                  ),
                                  SizedBox(height: 5.0), // Espacement entre les éléments
                                  Row(
                                    children: <Widget>[
                                      Icon(Icons.location_on, color: Colors.black, size: 20.0), // Icône de localisation pour le lieu
                                      SizedBox(width: 5.0), // Espacement entre l'icône et le texte
                                      Text(location),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
