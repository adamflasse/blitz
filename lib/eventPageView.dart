import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventPageView extends StatefulWidget {
  @override
  _EventPageViewState createState() => _EventPageViewState();
}

class _EventPageViewState extends State<EventPageView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User currentUser;
  late ScrollController _scrollController;
  late Set<String> _eventIds; // Ensemble pour stocker les identifiants des événements et éviter les doublons.
  late List<QueryDocumentSnapshot> _events; // Liste pour stocker les événements de l'utilisateur.

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser!;
    _scrollController = ScrollController();
    _eventIds = Set<String>();
    _events = [];
    _fetchUserEvents();
  }

  Future<void> _fetchUserEvents() async {
    try {
      QuerySnapshot querySnapshot;

      // Fonction pour ajouter des événements à la liste sans doublons.
      void addEventsToList(QuerySnapshot snapshot) {
        for (final doc in snapshot.docs) {
          final eventId = doc.id; // ou utilisez une clé unique de votre choix.
          // Si l'ID de l'événement n'est pas encore dans l'ensemble, ajoutez l'événement à la liste.
          if (!_eventIds.contains(eventId)) {
            _eventIds.add(eventId);
            _events.add(doc);
          }
        }
      }

      // Récupérer les événements où l'utilisateur est l'administrateur.
      querySnapshot = await _firestore.collection('events')
          .where('adminId', isEqualTo: currentUser.uid)
          .orderBy('date', descending: true)
          .get();
      addEventsToList(querySnapshot);

      // Récupérer les événements où l'utilisateur est un participant accepté.
      querySnapshot = await _firestore.collection('events')
          .where('acceptedUsers', arrayContains: currentUser.uid)
          .orderBy('date', descending: true)
          .get();
      addEventsToList(querySnapshot);

      // Récupérer les événements où l'utilisateur est un participant ayant refusé.
      querySnapshot = await _firestore.collection('events')
          .where('declinedUsers', arrayContains: currentUser.uid)
          .orderBy('date', descending: true)
          .get();
      addEventsToList(querySnapshot);

      // Tri des événements par date de l'événement du plus ancien au plus récent.
      _events.sort((a, b) => (b.data() as Map<String, dynamic>)['date'].compareTo((a.data() as Map<String, dynamic>)['date']));

      setState(() {});

      // Faire défiler vers l'événement le plus récent (premier dans la liste après le tri).
      if (_events.isNotEmpty) {
        _scrollToCurrentEvent();
      }
    } catch (e) {
      // Gérer les erreurs lors de l'exécution des requêtes Firestore.
      // Vous pouvez afficher un message d'erreur à l'utilisateur ou effectuer d'autres actions appropriées.
      print("Une erreur s'est produite lors de la récupération des événements: $e");
    }
  }

  void _scrollToCurrentEvent() {
    var scrollPosition = _events.length * 100.0;
    _scrollController.animateTo(
      scrollPosition,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Événements'),
      ),
      body: (_events.isEmpty)
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        controller: _scrollController,
        itemCount: _events.length,
        itemBuilder: (context, index) {
          var event = _events[index].data() as Map<String, dynamic>;
          return ListTile(
            title: Text(event['name']),
            subtitle: Text(event['date'].toDate().toString()),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
