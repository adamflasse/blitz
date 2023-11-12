import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationDetailsPage extends StatelessWidget {
  final DocumentSnapshot invitationData; // modification pour passer le snapshot complet
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> userData;

  InvitationDetailsPage({
    required this.invitationData,
    required this.eventData,
    required this.userData,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String _formatDate(DateTime dateTime) {
    // Construction de la chaîne de date dans le format dd/mm/yy
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString().substring(2); // Prenez les deux derniers chiffres de l'année

    return '$day/$month/$year'; // dd/mm/yy
  }

  Future<void> acceptEvent(String eventId) async {
    if (currentUser == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté
      print('Aucun utilisateur connecté');
      return;
    }

    // L'UID de l'utilisateur actuellement connecté
    String currentUserId = currentUser!.uid;

    try {
      // Référence au document de l'événement
      DocumentReference eventRef = _firestore.collection('events').doc(eventId);

      // Ajouter l'UID de l'utilisateur au tableau acceptedUsers dans le document de l'événement
      return await eventRef.update({
        'acceptedUsers': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e) {
      // Gérer les erreurs
      print('Une erreur s\'est produite lors de l\'acceptation de l\'événement: $e');
    }
  }


  Future<void> declineEvent(String eventId) async {
    if (currentUser == null) {
      // Gérer le cas où l'utilisateur n'est pas connecté
      print('Aucun utilisateur connecté');
      return;
    }

    // L'UID de l'utilisateur actuellement connecté
    String currentUserId = currentUser!.uid;

    try {
      // Référence au document de l'événement
      DocumentReference eventRef = _firestore.collection('events').doc(eventId);

      // Ajouter l'UID de l'utilisateur au tableau acceptedUsers dans le document de l'événement
      return await eventRef.update({
        'declinedUsers': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e) {
      // Gérer les erreurs
      print('Une erreur s\'est produite lors de l\'acceptation de l\'événement: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    String eventName = eventData['name'] ?? 'N/A';
    String username = userData['username'] ?? 'N/A';

    // Vous pouvez extraire plus de détails si nécessaire...

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // ici vous pouvez changer la hauteur de l'AppBar
        child: AppBar(
          title: Text(
            'Détails de l\'invitation',
            style: TextStyle(
              backgroundColor: Colors.black,
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
           // définit la couleur de fond de l'AppBar
          shape: Border(bottom: BorderSide(color: Colors.black, width: 3.0)), // ajoute une bordure en bas
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 50, // Vous pouvez ajuster la taille en modifiant la valeur du rayon
              backgroundImage: NetworkImage(userData['profile_picture_url'] ?? 'url_par_defaut'), // Remplacer 'url_par_defaut' par l'URL de votre image par défaut
            ),
            SizedBox(height: 20),
            Text(
              '$username t\'a invité à',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '$eventName',
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  backgroundColor: Colors.black
              ),
            ),
            SizedBox(height: 20),
            // Formatage de la date
            if (eventData['date'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.calendar_today),
                  SizedBox(width: 8), // Espacement entre l'icône et le texte
                  Expanded( // Ajouté pour éviter tout débordement de texte
                    child: Text(
                      eventData['date'] != null
                          ? 'Date : ${_formatDate((eventData['date'] as Timestamp).toDate())} de ${eventData['startTime'] ?? 'N/A'} à ${eventData['endTime'] ?? 'N/A'}'
                          : 'Date : N/A',
                      overflow: TextOverflow.ellipsis, // En cas de débordement de texte, celui-ci sera tronqué avec des points de suspension
                    ),
                  ),
                ],
              ),

            ] else ...[
              Text('Date : N/A'),
            ],
            SizedBox(height: 10),
            Row( // Utiliser un widget Row pour les icônes et le texte sur la même ligne
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.place),
                SizedBox(width: 8), // Espacement entre l'icône et le texte
                Text('Lieu : ${eventData['location'] ?? 'N/A'}'),
              ],
            ),
            SizedBox(height: 20), // Espacement avant le texte "Description"
            Row( // Envelopper le texte "Description :" dans un widget Row
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left, // Aligner le texte à gauche
                ),
              ],
            ),
            SizedBox(height: 10), // Espacement entre le titre et le contenu de la description
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10), // Padding intérieur pour le conteneur
              alignment: Alignment.topLeft, // Aligner le texte à gauche
              constraints: BoxConstraints(
                minHeight: 50, // Hauteur minimale pour le conteneur
                maxHeight: 150, // Hauteur maximale pour le conteneur, vous pouvez ajuster cela en fonction de vos besoins
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Couleur de fond du conteneur, à changer selon votre préférence
                borderRadius: BorderRadius.circular(5), // Bordures arrondies
              ),
              child: SingleChildScrollView( // SingleChildScrollView permet le défilement du texte s'il est trop long
                child: Text(
                  eventData['description'] ?? 'Pas de description fournie.', // Affichage de la description ou d'un message par défaut
                  style: TextStyle(
                    fontSize: 16, // Taille de police pour la description
                  ),
                ),
              ),
            ),

            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding( // Ajout d'un padding pour donner de l'espace autour des boutons
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black, // couleur de fond du bouton
                          onPrimary: Colors.white, // couleur du texte et de l'icône
                          minimumSize: Size(150, 50), // taille minimale du bouton
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // bouton arrondi
                          ),
                        ),
                        onPressed: () {
                          // Code pour accepter l'invitation
                          acceptEvent(eventData['eventId']);
                          FirebaseFirestore.instance
                              .collection('invitations')
                              .doc(invitationData.id) // utilisez l'ID de l'invitation
                              .update({
                            'status': 'accepted',
                          }).then((_) {
                            Navigator.of(context).pop(); // Retourne à l'écran précédent après la mise à jour
                          }).catchError((error) {
                            // Gestion des erreurs ici
                          });
                        },
                        child: Row( // Row pour le texte et l'icône sur la même ligne
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Go!'),
                            SizedBox(width: 5), // espace entre le texte et l'icône
                            Icon(Icons.check), // icône de vérification
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.white, // couleur de fond du bouton
                          onPrimary: Colors.black, // couleur du texte
                          minimumSize: Size(150, 50), // taille minimale du bouton
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // bouton arrondi
                            side: BorderSide(color: Colors.black), // bordure noire pour le bouton
                          ),
                        ),
                        onPressed: () {
                          // Code pour décliner l'invitation
                          declineEvent(eventData['eventId']);
                          FirebaseFirestore.instance
                              .collection('invitations')
                              .doc(invitationData.id) // utilisez l'ID de l'invitation
                              .update({
                            'status': 'declined',
                          }).then((_) {
                            Navigator.of(context).pop(); // Retourne à l'écran précédent après la mise à jour
                          }).catchError((error) {
                            // Gestion des erreurs ici
                          });
                        },
                        child: Text(
                          'BLITZ',
                          style: TextStyle(
                            backgroundColor: Colors.black,
                            color: Colors.white,
                            fontSize: 25,

                            fontWeight: FontWeight.w500,
                          ),
                        ), // texte du bouton
                      ),
                    ],
                  ),
                ),
              ),
            ),
SizedBox(height: 30,)
          ],
        ),
      ),
    );
  }
}

