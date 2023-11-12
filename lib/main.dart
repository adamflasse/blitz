import 'package:blytzwow/RegistrationFlow.dart';
import 'package:blytzwow/loginscreen.dart';
import 'package:blytzwow/mainPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: AuthenticationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginView(); // L'utilisateur n'est pas connecté, montrez LoginView
          }
          return MainPage(); // L'utilisateur est connecté, montrez MainPage
        }

        // En attente de la fin de la vérification de l'état de la connexion
        return Scaffold(
          body: Center(
            child: Column(
              children: [

                Text('Bienvenue', style: TextStyle( color: Colors.black, fontSize: 27, fontWeight: FontWeight.w700)),
                SizedBox(
                  height: size.height/20,
                ),
                Text('sur', style: TextStyle( color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                SizedBox(
                  height: size.height/20,
                ),
                Text('BLITZ', style: TextStyle(backgroundColor: Colors.black, color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                SizedBox(
                  height: size.height/10,
                ),
                CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Accéder à l'instance FirebaseAuth
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Si firebaseUser n'est pas null, alors l'utilisateur est actuellement connecté.
    if (firebaseUser != null) {
      return MainPage(); // l'utilisateur est connecté, retourner la MainPage
    } else {
      return LoginView(); // l'utilisateur est déconnecté, retourner la LoginView
    }
  }
}

