import 'package:blytzwow/mainPage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'RegistrationFlow.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true; // déclenche l'indicateur de chargement
    });

    try {
      // Tentez de vous connecter avec email et mot de passe
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      // En cas de succès, vous pouvez naviguer vers la page principale ou toute autre page de votre application
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainPage())); // Remplacez par votre page principale
    } on FirebaseAuthException catch (e) {
      // Gérez les erreurs d'authentification appropriées
      String errorMessage = "Une erreur est survenue lors de la connexion.";
      if (e.code == 'user-not-found') {
        errorMessage = "Aucun utilisateur trouvé avec cet e-mail.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Mot de passe incorrect.";
      }
      // Montrez une Snackbar avec le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() {
        _isLoading = false; // arrête l'indicateur de chargement
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size ;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,

        title: Text('BLITZ', style: TextStyle(backgroundColor: Colors.white, color: Colors.black, fontSize: 30, fontWeight: FontWeight.w900)),
        automaticallyImplyLeading: false,

      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: size.height / 40,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: size.width/ 1.1,
                  child: Text("Connexion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),),
                Container(
                  alignment: Alignment.centerLeft,
                  width: size.width / 1.1,
                  child: Text("Connecte toi pour y retrouver tes amis", style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w400 ),),),

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
                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  GestureDetector(
                    onTap: _login,
                    child: Container(
                      height: size.height / 20,
                      width: size.width / 2,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.black

                      ),
                      child: Text("Connexion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 16),),

                    ),
                  ),
                TextButton(
                  child: Text("Pas de compte? Inscrivez-vous"),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RegistrationFlow())); // Naviguer vers l'écran d'inscription
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: size.height / 20,
          ),

          Container(
            width: size.width/ 1.2,
            alignment: Alignment.centerLeft,
            child: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: () {
              print("button pressed");

            },)
          ),
          SizedBox(
            height: size.height / 40,
          ),
          Container(
            alignment: Alignment.centerLeft,
            width: size.width/ 1.3,
            child: Text("Bienvenue", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),)
          ),
          Container(
            alignment: Alignment.centerLeft,
            width: size.width / 1.3,
            child: Text("Connecte toi pour continuer!", style: TextStyle(color: Colors.grey, fontSize: 25, fontWeight: FontWeight.w500 ),),


          ),
          SizedBox(
            height: size.height / 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: size.width,
              alignment: Alignment.center,
              child: field(size, "email", Icons.account_circle_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: size.width,
              alignment: Alignment.center,
              child: field(size, "mot de passe", Icons.lock_outline_rounded)
            ),
          ),

          SizedBox(
            height: size.height / 20,
          ),
          customButton(size),
          Text("Pas encore de compte ?", style: TextStyle(fontSize: 25),)

        ],
      ),
    );
  }

  Widget customButton (Size size) {
    return Container(
      height: size.height / 15,
      width: size.width / 1.2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black

      ),
      child: Text(" Se connecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),),

    );
  }

  Widget field(Size size, String hintText , IconData icon) {
    return Container(
      height: size.height / 15,
      width: size.width / 1.1,
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)
          )
        ),
      ),
    );
  }
}
