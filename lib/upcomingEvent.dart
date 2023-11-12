 // Assurez-vous de créer cette nouvelle page pour afficher les détails de l'événement.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpcomingEventsPage extends StatefulWidget {
  @override
  _UpcomingEventsPageState createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser; // Obtenir l'utilisateur actuellement connecté

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Événements à venir'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('events')
              .where('date', isGreaterThan: Timestamp.now()) // Filtrer pour obtenir des événements à venir
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("Aucun événement à venir."));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var event = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                // Convertir la date de Timestamp à DateTime pour un affichage facile
                DateTime date = event['date'].toDate();
                String day = date.day < 10 ? '0${date.day}' : '${date.day}';
                String month = date.month < 10 ? '0${date.month}' : '${date.month}';
                String eventDate = '$day/$month';

                // Extraire d'autres détails pertinents de l'événement
                var eventName = event.containsKey('name') ? event['name'] : 'N/A';
                var location = event.containsKey('location') ? event['location'] : 'N/A';
                var adminId = event.containsKey('adminId') ? event['adminId'] : 'N/A';

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
                    // Correction ici: utilisation de `adminData` au lieu de `userDataMap`
                    var profilePictureUrl = adminData.containsKey('profile_picture_url') ? adminData['profile_picture_url'] : null;

                    return GestureDetector(
                      onTap: (){

                      },
                      child: Container(
                        margin: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(15.0),
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
                            onBackgroundImageError: (exception, stackTrace) => {}, // Gestion des erreurs d'image
                          ),
                          title: Container(
                            color: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              eventName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.0),
                              Text('Organisé par : $adminName'),
                              SizedBox(height: 5.0),
                              Row(
                                children: <Widget>[
                                  Icon(Icons.calendar_today, color: Colors.black, size: 20.0),
                                  SizedBox(width: 5.0),
                                  Text(eventDate),
                                ],
                              ),
                              SizedBox(height: 5.0),
                              Row(
                                children: <Widget>[
                                  Icon(Icons.location_on, color: Colors.black, size: 20.0),
                                  SizedBox(width: 5.0),
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
        ),
      ),
    );
  }
}
