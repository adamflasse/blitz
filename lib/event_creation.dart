import 'package:blytzwow/invitescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Pour le formatage de la date et de l'heure






class EventCreationFlow extends StatefulWidget {
  @override
  _EventCreationFlowState createState() => _EventCreationFlowState();
}

class _EventCreationFlowState extends State<EventCreationFlow> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final int _numPages = 6; // Nombre total de pages dans le processus de création

  // Variables pour stocker les informations de l'événement
  String? _eventName;
  DateTime? _eventDate;
  List<TimeOfDay>? _eventTimes;
  String? _eventLocation;
  String? _eventDescription;





  void _goToPreviousPage() {
    _controller.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    setState(() {
      _currentPage --;
    });
  }

  // Méthode pour aller à la page suivante dans le PageView
  void _goToNextPage() {
    if (_currentPage < _numPages - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.ease,
      );
      print(_eventLocation);

      setState(() {
        _currentPage ++;
      });
    } else {
      _completeEventCreation();
    }
  }

  // Méthode appelée lorsque toutes les informations de l'événement ont été fournies
  void _completeEventCreation() {
    // Ici, vous pouvez traiter ou stocker les informations de l'événement, comme les envoyer à une base de données ou à une API.
    // Puis, naviguez vers la page de récapitulation ou toute autre page suivante dans votre application.
    print("Événement créé: $_eventName, $_eventDate, $_eventTimes, $_eventLocation, $_eventDescription");
  }
  Future<void> _saveEventToFirebase() async {
    // Obtenez une instance de Firestore et FirebaseAuth
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;

    // Vérifier si un utilisateur est actuellement connecté.
    User? currentUser = auth.currentUser;
    if (currentUser == null) {
      // Gérer le cas où aucun utilisateur n'est connecté
      print("Aucun utilisateur n'est actuellement connecté.");
      return;
    }

    // Créer un nouvel ID d'événement unique
    DocumentReference eventRef = firestore.collection('events').doc();

    // Convertir les objets TimeOfDay en String pour le stockage.
    String startTimeStr = "${_eventTimes?[0].hour}:${_eventTimes?[0].minute}";
    String endTimeStr = "${_eventTimes?[1].hour}:${_eventTimes?[1].minute}";

    String formatTimeString(String time) {
      // Expression régulière pour vérifier si la chaîne est dans le format "h:mm" ou "hh:mm"
      final RegExp timeFormatRegex = RegExp(r"^(?:[01]?[0-9]|2[0-3]):[0-5][0-9]$");

      // Si la chaîne correspond au format, retournez la chaîne telle quelle
      if (timeFormatRegex.hasMatch(time)) {
        return time;
      }

      // Si la chaîne ne correspond pas au format, ajoutez un '0' à la fin
      return time + '0';
    }

    // Préparer les données d'événement
    Map<String, dynamic> eventToSave = {
      'eventId': eventRef.id, // L'ID unique de l'événement
      'adminId': currentUser.uid, // L'ID de l'utilisateur actuel
      'name': _eventName,
      'date': _eventDate,
      'startTime': formatTimeString(startTimeStr),
      'endTime': formatTimeString(endTimeStr),
      'location': _eventLocation,
      'description': _eventDescription,
    };

    // Enregistrer les données dans la collection 'events'
    try {
      await eventRef.set(eventToSave);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => UserInvitePage2(eventRef.id)));
      // Ici, vous pouvez gérer les succès, par exemple, afficher un message de succès ou naviguer vers une autre page.
    } catch (e) {
      // Gérer les erreurs lors de l'enregistrement des données
      print("Une erreur s'est produite lors de l'ajout de l'événement: $e");
      // Vous pouvez gérer les erreurs ici, par exemple, afficher une barre de messages avec l'erreur.
    }
  }

  DateTime convertTimeOfDayToDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _currentPage > 0 ? IconButton(onPressed: () {
          _goToPreviousPage();
        }, icon: Icon(Icons.arrow_back_ios_new, color: Colors.black)) : null,
        actions: [IconButton(onPressed: () { Navigator.pop(context);}, icon: Icon(Icons.close, color: Colors.black))],


        title: Text('BLITZ', style: TextStyle(backgroundColor: Colors.black, color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),


        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 6, // Nous avons 6 étapes, donc diviser par 6 pour obtenir la progression
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      ),
      body: PageView(
        controller: _controller,
        physics: NeverScrollableScrollPhysics(), // Désactiver le balayage pour éviter que l'utilisateur ne navigue manuellement
        children: <Widget>[
          EventNamePage(
            onNameSubmitted: (value) {
              setState(() {
                _eventName = value;


              });
              _goToNextPage();

            },
          ),
          EventDatePage(
            onDateSelected: (value) {
              setState(() {
                _eventDate = value;

              });
              _goToNextPage();
            },
          ),
          EventTimePage(
            onTimeSelected: (value) {
              setState(() {
                _eventTimes = value;

              });
              _goToNextPage();
            },
          ),
          EventLocationPage(
            onLocationSubmitted: (value) {
              setState(() {
                _eventLocation = value;

              });
              _goToNextPage();
            },
          ),
          EventDescriptionPage(
            onDescriptionSubmitted: (value) {
              setState(() {
                _eventDescription = value;

              });
              _goToNextPage();
            },
          ),
          // Page de récapitulation
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),

              child: Column(
                children: [
                  // Vérifiez si nous avons des valeurs non null pour tous les paramètres requis.
                  if (_eventName != null &&
                      _eventDate != null &&
                      _eventTimes != null &&
                      _eventTimes!.length > 1 && // assurez-vous qu'il y a au moins deux temps spécifiés
                      _eventLocation != null &&
                      _eventDescription != null)
                    EventValidationPage(
                      title: _eventName!, // le '!' indique que la valeur n'est pas null
                      description: _eventDescription!,
                      location: _eventLocation!,
                      startTime: convertTimeOfDayToDateTime(_eventDate!, _eventTimes![0]),
                      endTime: convertTimeOfDayToDateTime(_eventDate!, _eventTimes![1]),
                    ),
                  ElevatedButton(
                    onPressed: _saveEventToFirebase, // Appel de la fonction de complétion
                    child: Text('Inviter des amis'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),


    );
  }
}

// Vous aurez besoin de cette dépendance pour formater les dates





class EventValidationPage extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  EventValidationPage({
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  String formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month < 10 ? '0${dateTime.month}' : dateTime.month.toString();
    final day = dateTime.day < 10 ? '0${dateTime.day}' : dateTime.day.toString();
    final hour = dateTime.hour < 10 ? '0${dateTime.hour}' : dateTime.hour.toString();
    final minute = dateTime.minute < 10 ? '0${dateTime.minute}' : dateTime.minute.toString();

    return '$day/$month/$year $hour:$minute'; // dd/mm/yyyy hh:mm
  }

  @override
  Widget build(BuildContext context) {
    DateTime adjustedEndTime = this.endTime;
    if (this.endTime.isBefore(this.startTime)) {
      adjustedEndTime = this.endTime.add(Duration(days: 1));
    }

    return  Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // sets the column's size to minimum
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tu valides?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Alors invite tes amis à y participer!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Nom: ${this.title}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12),
                      Text(
                        'Lieu: ${this.location}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Début: ${formatDateTime(this.startTime)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Fin: ${formatDateTime(adjustedEndTime)}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Description:", style: TextStyle(fontSize: 18),),
                          SizedBox(width: 8),

                          Text(
                            this.description,
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20), // Instead of Spacer, just give some space before the button
        
        
                    ],
        
        
        
            )
        


    );
  }
}




class EventNamePage extends StatefulWidget {
  final ValueChanged<String> onNameSubmitted;
  EventNamePage({required this.onNameSubmitted});

  @override
  State<EventNamePage> createState() => _EventNamePageState();
}

class _EventNamePageState extends State<EventNamePage> {
  final _formKey = GlobalKey<FormState>();

  // Étape 1: Créer un TextEditingController.
  final myController = TextEditingController();

  // Étape 2: Créer un FocusNode.
  final FocusNode myFocusNode = FocusNode();

  @override
  void dispose() {
    // Nettoyer le controller et le focus node quand le widget est disposé.
    myController.dispose();
    myFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    // Ici, nous vérifions si le formulaire est valide.
    if (_formKey.currentState!.validate()) {
      // Si le formulaire est valide, récupérer la valeur actuelle du TextFormField.
      final currentText = myController.text;
      // On peut maintenant passer cette valeur à la méthode onNameSubmitted.
      widget.onNameSubmitted(currentText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: size.height / 40), // Espacement pour aérer l'interface
                  Text(
                    'Donne un nom à cet événement',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8), // Espacement
                  Text(
                    'Donne un nom qui fera dire "Wow, je dois absolument y aller!"',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20), // Espacement
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.edit),
                      labelText: 'Nom de l\'événement',
                      hintText: 'Entrez le nom qui fera sensation',
                    ),
                    controller: myController, // Associer le TextEditingController.
                    focusNode: myFocusNode,
                    // Pas de gestionnaire onFieldSubmitted ici car nous gérons la soumission via le bouton
                  ),
                  SizedBox(
                    height: size.height / 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      myFocusNode.unfocus();
                      _submitForm();
                    }, // désactivez le bouton lors de la vérification
                    child: Container(
                      height: size.height / 20,
                      width: size.width / 2,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.black
                      ),
                      child: Text("Suivant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventDatePage extends StatelessWidget {
  final ValueChanged<DateTime> onDateSelected;
  EventDatePage({required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: size.height /40),  // Espacement pour aérer l'interface
            Text(
              'Choisis une date',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),  // Espacement
            Text(
              'Quand est-ce que ça a lieu ? ',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      // Cette ligne assure la bonne copie des styles actuels, mais permet de modifier certains aspects spécifiques.
                      data: Theme.of(context).copyWith(
                        // Changer les couleurs de fond et des autres éléments du sélecteur ici
                        colorScheme: ColorScheme.light(
                          primary: Colors.white, // Couleur de la tête
                          onPrimary: Colors.black, // Couleur du texte de la tête
                          surface: Colors.black26, // Couleur de fond du dialogue
                          onSurface: Colors.white, // Couleur du texte principal dans le dialogue
                          secondary: Colors.white,

                        ),
                        // Autres styles de dialogue comme la forme, l'élévation, etc. peuvent également être ajustés
                        dialogTheme: DialogTheme(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12))
                          ),
                        ),
                      ),
                      child: child ?? Container(),
                    );
                  },
                );
                if (selectedDate != null) {
                  onDateSelected(selectedDate);
                }
              },
              child: Container(
                height: size.height / 20,
                width: size.width / 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black

                ),
                child: Center(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(Icons.event, color: Colors.white,),
                      ),
                      SizedBox(width: 10,),
                      Text("Choisir une date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),
                    ],
                  ),
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventTimePage extends StatefulWidget {
  final ValueChanged<List<TimeOfDay>> onTimeSelected;
  EventTimePage({required this.onTimeSelected});

  @override
  _EventTimePageState createState() => _EventTimePageState();
}

class _EventTimePageState extends State<EventTimePage> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();

  }

  Future<void> _selectTime() async {
    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // Cette ligne assure la bonne copie des styles actuels, mais permet de modifier certains aspects spécifiques.
          data: Theme.of(context).copyWith(
            // Changer les couleurs de fond et des autres éléments du sélecteur ici
            colorScheme: ColorScheme.light(
              primary: Colors.white, // Couleur de la tête
              onPrimary: Colors.black, // Couleur du texte de la tête
              surface: Colors.black26, // Couleur de fond du dialogue
              onSurface: Colors.white, // Couleur du texte principal dans le dialogue
              secondary: Colors.white,

            ),
            // Autres styles de dialogue comme la forme, l'élévation, etc. peuvent également être ajustés
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
              ),
            ),
          ),
          child: child ?? Container(),
        );
      },
    );
    if (newStartTime != null) {
      setState(() {
        _startTime = newStartTime;
        _endTime = TimeOfDay.now().replacing(hour: _startTime.hour + 1);
      });
    }

    final TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // Cette ligne assure la bonne copie des styles actuels, mais permet de modifier certains aspects spécifiques.
          data: Theme.of(context).copyWith(
            // Changer les couleurs de fond et des autres éléments du sélecteur ici
            colorScheme: ColorScheme.light(
              primary: Colors.white, // Couleur de la tête
              onPrimary: Colors.black, // Couleur du texte de la tête
              surface: Colors.black26, // Couleur de fond du dialogue
              onSurface: Colors.white, // Couleur du texte principal dans le dialogue
              secondary: Colors.white,

            ),
            // Autres styles de dialogue comme la forme, l'élévation, etc. peuvent également être ajustés
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12))
              ),
            ),
          ),
          child: child ?? Container(),
        );
      },
    );
    if (newEndTime != null) {
      setState(() {
        _endTime = newEndTime;
      });
    }

    widget.onTimeSelected([_startTime, _endTime]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: size.height /40),  // Espacement pour aérer l'interface
            Text(
              'Choisis une heure',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),  // Espacement
            Text(
              "Définis l'heure de début et de fin" ,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                height: size.height / 20,
                width: size.width / 3,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black

                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(Icons.watch_later_outlined, color: Colors.white,),
                      ),
                      SizedBox(width: 10,),
                      Text("Choisir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),
                    ],
                  ),
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventLocationPage extends StatefulWidget {
  final ValueChanged<String> onLocationSubmitted;
  EventLocationPage({required this.onLocationSubmitted});

  @override
  _EventLocationPageState createState() => _EventLocationPageState();
}

class _EventLocationPageState extends State<EventLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final myController = TextEditingController(); // Contrôleur pour récupérer la valeur actuelle du champ de texte

  @override
  void dispose() {
    myController.dispose(); // N'oubliez pas de vous débarrasser du contrôleur quand il n'est plus nécessaire
    super.dispose();
  }

  void _submitLocation() {
    if (_formKey.currentState!.validate()) {
      // Si le formulaire est valide, récupérer la valeur actuelle du TextFormField.
      final currentLocation = myController.text;
      // On peut maintenant passer cette valeur à la méthode onLocationSubmitted.
      widget.onLocationSubmitted(currentLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: size.height / 40), // Espacement pour aérer l'interface
                Text(
                  'Donne une localisation',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8), // Espacement
                Text(
                  "N'hésite pas à fournir une adresse complète",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20), // Espacement
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    labelText: 'Lieu de l\'événement',
                    hintText: 'Entrez le lieu de l\'événement',
                  ),
                  controller: myController, // Associer le TextEditingController.
                  // Pas de gestionnaire onFieldSubmitted ici car nous gérons la soumission via le bouton
                ),
                SizedBox(
                  height: size.height / 15,
                ),
                GestureDetector(
                  onTap: () {
                    // Désactivez le clavier virtuel et soumettez la localisation
                    FocusScope.of(context).unfocus();
                    _submitLocation();
                  },
                  child: Container(
                    height: size.height / 20,
                    width: size.width / 2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black
                    ),
                    child: Text("Suivant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class EventDescriptionPage extends StatefulWidget {
  final ValueChanged<String> onDescriptionSubmitted;
  EventDescriptionPage({required this.onDescriptionSubmitted});

  @override
  _EventDescriptionPageState createState() => _EventDescriptionPageState();
}

class _EventDescriptionPageState extends State<EventDescriptionPage> {
  final _formKey = GlobalKey<FormState>(); // clé pour interagir avec le formulaire
  final _controller = TextEditingController();
  final int _maxChars = 200;

  @override
  void initState() {
    super.initState();
    // Écoutez les changements de texte pour reconstruire le widget avec le compteur de texte mis à jour.
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Assurez-vous de désallouer le contrôleur lorsque le widget est supprimé de l'arbre des widgets.
    _controller.dispose();
    super.dispose();
  }

  void _submitDescription() {
    if (_formKey.currentState!.validate()) {
      // Si le formulaire est valide, récupérer la valeur actuelle du TextFormField.
      final currentDescription = _controller.text;
      // On peut maintenant passer cette valeur à la méthode onDescriptionSubmitted.
      widget.onDescriptionSubmitted(currentDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Form(
        key: _formKey, // ne pas oublier d'associer la clé au formulaire
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: size.height / 40), // Espacement pour aérer l'interface
                Text(
                  'Décris cet événement',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8), // Espacement
                Text(
                  "N'oublie pas la petite touche de fun!",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    TextFormField(
                      controller: _controller,
                      maxLines: 4, // null signifie que c'est extensible à l'infini, mais il est également contrôlé par son parent.
                      keyboardType: TextInputType.multiline,
                      maxLength: _maxChars, // cela active le compteur de caractères en haut à droite
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxChars), // cela limite réellement les caractères d'entrée
                      ],
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.edit),
                        labelText: 'Description',
                        hintText: 'Entrez votre description ici',
                        // retire le compteur de caractères par défaut
                        counterText: '',
                      ),
                      validator: (value) { // Ajout d'une validation simple
                        if (value == null || value.isEmpty) {
                          return 'Décris au moins un minimum ton évênemen';
                        }
                        return null;
                      },
                    ),
                    Text(
                      '${_controller.text.length}/$_maxChars', // affiche le compteur de caractères personnalisé
                      style: TextStyle(
                        color: (_maxChars - _controller.text.length) < 10 // change la couleur lorsqu'il reste moins de 10 caractères
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: size.height / 15,
                ),
                GestureDetector(
                  onTap: () {
                    // Désactivez le clavier virtuel et soumettez la description
                    FocusScope.of(context).unfocus();
                    _submitDescription();
                  },
                  child: Container(
                    height: size.height / 20,
                    width: size.width / 2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black
                    ),
                    child: Text("Suivant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
