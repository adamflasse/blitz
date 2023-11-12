import 'package:blytzwow/mainPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:email_validator/email_validator.dart';
// Importer les autres widgets et packages nécessaires ici...

class RegistrationFlow extends StatefulWidget {
  @override
  _RegistrationFlowState createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  int _currentPage = 0;
  PageController _pageController = PageController();

  // Stockage des informations de l'utilisateur
  String email = '';
  String password = '';
  String confirmedPassword = '';
  String username = '';
  // Ajoutez d'autres informations nécessaires ici...

  // Cette fonction est appelée lorsque l'utilisateur termine chaque étape
  void goToNextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }

  }

  void goToPreviousPage() {
    if ( _currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    };
  }

  void updateEmail(String email) {
    setState(() {
      this.email = email;
    });
    goToNextPage();
  }

  void updatePassword(String password) {
    setState(() {
      this.password = password;
    });
    // Ne passez à l'étape suivante que si le mot de passe est valide...
    if (password.length >= 6) {
      goToNextPage();
    }
  }

  void updateConfirmedPassword(String password) {
    setState(() {
      this.confirmedPassword = password;
    });
    // Vérifiez que le mot de passe confirmé correspond au mot de passe original
    if (password == this.password) {
      goToNextPage();
    }
  }

  void updateUsername(String username) {
    setState(() {
      this.username = username;
    });
    goToNextPage();
  }

  // Ajoutez des méthodes similaires pour d'autres mises à jour...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _currentPage > 0 ? IconButton(onPressed: () {
          goToPreviousPage();
        }, icon: Icon(Icons.arrow_back_ios_new, color: Colors.white)) : null,
        title: Text('BLITZ', style: TextStyle(backgroundColor: Colors.white, color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6.0),
          child: ProgressBar(_currentPage),
        ),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: () { Navigator.pop(context);}, icon: Icon(Icons.close, color: Colors.white))],
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Désactive le défilement manuel
        children: <Widget>[
          EmailScreen(updateEmail: updateEmail),
          PasswordScreen(updatePassword: updatePassword),
          ConfirmPasswordView (updatePassword: updateConfirmedPassword, originalPassword: password,),
          UsernameScreen(updateUsername: updateUsername),
          ProfilePhotoScreen(
            email: email,
            password: password,
            username: username, onPhotoSelected: (String ) {},
            // Ajoutez d'autres champs si nécessaire
          ),
        ],
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
      ),
    );
  }
}

class RegistrationManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ... vos autres méthodes de gestion d'état et de navigation ...

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    required File imageFile,
  }) async {
    try {
      // Créer un utilisateur avec email et mot de passe
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload de la photo de profil dans Firebase Storage
      final ref = _storage.ref().child('user_profile_pictures').child(userCredential.user!.uid + '.jpg');
      await ref.putFile(imageFile);

      final imageUrl = await ref.getDownloadURL(); // Obtenir l'URL de l'image chargée

      // Stocker des informations supplémentaires dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'profile_picture_url': imageUrl,
        // Ajoutez d'autres champs si nécessaire
      });

    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs liées à l'authentification
      if (e.code == 'weak-password') {
        print('Le mot de passe fourni est trop faible.');
        // Vous pouvez utiliser des throw pour renvoyer l'erreur et la gérer dans votre UI
      } else if (e.code == 'email-already-in-use') {
        print('Un compte existe déjà pour cet email.');
        // Vous pouvez utiliser des throw pour renvoyer l'erreur et la gérer dans votre UI
      }
    } catch (e) {
      // Autres erreurs
      print(e);
      // Vous pouvez utiliser des throw pour renvoyer l'erreur et la gérer dans votre UI
    }
  }
}

class ProgressBar extends StatelessWidget {
  final int currentPage;

  ProgressBar(this.currentPage);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double barWidth = constraints.maxWidth / 5; // Comme il y a 5 pages/steps

        return Container(
          height: 4.0,
          child: Row(
            children: [
              Container(
                height: 4.0,
                width: currentPage >= 0 ? barWidth : 0,
                color: currentPage >= 0 ? Colors.black : Colors.white,
              ),
              Container(
                height: 4.0,
                width: currentPage >= 1 ? barWidth : 0,
                color: currentPage >= 1 ? Colors.black : Colors.white,
              ),
              // Continuez pour les autres pages
            ],
          ),
        );
      },
    );
  }
}



// Définissez vos widgets pour EmailScreen, PasswordScreen, ConfirmPasswordScreen, UsernameScreen, et ProfilePhotoScreen...
// Chacun de ces écrans doit accepter une fonction de rappel pour mettre à jour l'état dans RegistrationFlow et passer à la page suivante.
class EmailScreen extends StatelessWidget {
  final Function(String) updateEmail;
  EmailScreen({required this.updateEmail});


  final TextEditingController _emailController = TextEditingController();

  bool Validate(String email) {
    bool isvalid = EmailValidator.validate(email);
    return isvalid;
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,

            children: [
              SizedBox(
                height: size.height / 40,
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width/ 1.1,
                child: Text("Inscription (1/5)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),),
          Container(
            alignment: Alignment.centerLeft,
            width: size.width / 1.1,
            child: Text("Pour commencer, nous avons besoin de ton email.", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w400 ),),),

              SizedBox(
                height:size.height / 60
              ),



              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.mail),
                  prefixIconColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.focused)
                      ? Colors.black
                      : Colors.grey),
                  labelText: 'Email',
                  hintText: 'Entrez votre email',
                  focusColor: Colors.black,

                ),

              ),
              SizedBox(
                height: size.height / 15,
              ),
            GestureDetector(
              onTap: () {
                if (Validate(_emailController.text) == true){
                  updateEmail(_emailController.text);
                };
              },
              child: Container(
                height: size.height / 20,
                width: size.width / 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black

                ),
                child: Text("Continuer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),

              ),
            ),



            ],
          ),
        ),
      ),
    );
  }
}

class PasswordScreen extends StatefulWidget {
  final Function(String) updatePassword;
  PasswordScreen({required this.updatePassword});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Form(
      key: _formKey,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height / 40,
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width/ 1.1,
                child: Text("Inscription (2/5)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text("C'est le moment de choisir un mot de passe.", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w400 ),),),

              SizedBox(
                  height:size.height / 60
              ),
              TextFormField(

                controller: _passwordController,
                keyboardType: TextInputType.text,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  prefixIconColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.focused)
                      ? Colors.black
                      : Colors.grey),
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe',
                  focusColor: Colors.black,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Le mot de passe doit comporter au moins 6 caractères.';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: size.height / 15,
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    widget.updatePassword(_passwordController.text);
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
                  child: Text("Continuer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmPasswordView extends StatefulWidget {
  final Function(String) updatePassword;
  final String originalPassword;
  ConfirmPasswordView({required this.updatePassword, required this.originalPassword});

  @override
  _ConfirmPasswordViewState createState() => _ConfirmPasswordViewState();
}

class _ConfirmPasswordViewState extends State<ConfirmPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Form(
      key: _formKey,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height / 40,
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width/ 1.1,
                child: Text("Inscription (3/5)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text("Maintenant, confirme-le. Juste pour être sûr", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w400 ),),),

              SizedBox(
                  height:size.height / 60
              ),
              TextFormField(
                validator:(value) {
                  if (value != widget.originalPassword) {
                    return 'Les mots de passe ne correspondent pas.';
                  }
                  return null;
                } ,

                controller: _passwordController,
                keyboardType: TextInputType.text,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  prefixIconColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.focused)
                      ? Colors.black
                      : Colors.grey),
                  labelText: 'Mot de passe',
                  hintText: 'Confirme ton mot de passe',
                  focusColor: Colors.black,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),

              ),
              SizedBox(
                height: size.height / 15,
              ),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    widget.updatePassword(_passwordController.text);
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
                  child: Text("Continuer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







class UsernameScreen extends StatefulWidget {
  final Function(String) updateUsername;
  UsernameScreen({required this.updateUsername});

  @override
  _UsernameScreenState createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isCheckingUsername = false; // Nouvel état pour suivre si une vérification est en cours
  final _formKey = GlobalKey<FormState>();

  Future<bool> isUsernameTaken(String username) async {

    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty; // retourne true si le nom d'utilisateur existe déjà
  }

  void _validateAndSubmit() async {
    if (_usernameController.text.isEmpty) {
      // Vous pouvez vouloir afficher une erreur ou un message d'alerte ici
      return;
    }

    setState(() {
      _isCheckingUsername = true; // la vérification est en cours
    });

    bool usernameTaken = await isUsernameTaken(_usernameController.text);

    setState(() {
      _isCheckingUsername = false; // la vérification est terminée
    });

    if (usernameTaken) {
      // Ici, vous pourriez vouloir afficher une boîte de dialogue/alerte/snackbar indiquant que le nom d'utilisateur est déjà pris.
    } else {
      widget.updateUsername(_usernameController.text);
      // Continuer vers l'étape suivante ou toute autre logique que vous avez après la mise à jour du nom d'utilisateur
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Form(
      key: _formKey,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height / 40,
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width/ 1.1,
                child: Text("Inscription (4/5)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text("Choisis ton alias", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w400 ),),),

              SizedBox(
                  height:size.height / 60
              ),
              TextFormField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_2_rounded),
                  prefixIconColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.focused)
                      ? Colors.black
                      : Colors.grey),
                  labelText: 'Nom d\'utilisateur',
                  hintText: 'Entrez votre nom d\'utilisateur',
                  focusColor: Colors.black
                ),
                // La validation est gérée dans _validateAndSubmit
              ),
              SizedBox(
                height: size.height / 15,
              ),
              GestureDetector(
                onTap: _isCheckingUsername ? null : _validateAndSubmit, // désactivez le bouton lors de la vérification
                child: Container(
                  height: size.height / 20,
                  width: size.width / 2,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.black

                  ),
                  child: Text("Continuer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),

                ),
              ),
              if (_isCheckingUsername) CircularProgressIndicator(color: Colors.black,), // affiche un indicateur de progression lors de la vérification
            ],
          ),
        ),
      ),
    );
  }
}






class ProfilePhotoScreen extends StatefulWidget {
  final String email;
  final String password;
  final String username;
  final Function(String) onPhotoSelected;

  ProfilePhotoScreen({
    required this.email,
    required this.password,
    required this.username,
    required this.onPhotoSelected,
  });

  @override
  _ProfilePhotoScreenState createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _permissionDenied = false;
  final RegistrationManager registrationManager = RegistrationManager();

  Future<void> _selectImage() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
        _permissionDenied = false;
      });
      widget.onPhotoSelected(selectedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            if (_imageFile == null) ...[
              SizedBox(height: size.height / 40),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text(
                  "Inscription (5/5)",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text(
                  "Sélectionne une photo de profil",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: size.height / 60),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ] else ...[
              SizedBox(height: size.height / 40),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text(
                  "Parfait!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                width: size.width / 1.1,
                child: Text(
                  "Appuie sur \"Terminer\" si la photo te plait. Si tu changes d'avis, tu pourras la changer plus tard.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: size.height / 60),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(File(_imageFile!.path)),
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            if (_permissionDenied)
              Text(
                'L\'accès aux photos est nécessaire pour choisir une photo de profil.',
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _selectImage,
              child: Container(
                height: size.height / 20,
                width: size.width / 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.black,
                ),
                child: Text(
                  "Choisir une photo",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Ici, vous implémenteriez la logique pour finaliser la création de compte
                    registrationManager.registerUser(email: widget.email, password: widget.password, username: widget.username, imageFile: File(_imageFile!.path));
                    widget.onPhotoSelected(_imageFile!.path);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => MainPage()));

                  },
                  child: Text('Terminer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
