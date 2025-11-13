import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'create_account.dart';
import 'dashboard.dart';
import 'forgot_password.dart';
import 'diary_home.dart';
import 'todo_list_screen.dart';
import 'firebase_options.dart';
import 'weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Personal App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return const DashboardScreen();
            }
            return const LoginPage();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        LoginPage.id: (context) => const LoginPage(),
        CreateAccountPage.id: (context) => const CreateAccountPage(),
        DashboardScreen.id: (context) => const DashboardScreen(),
        ForgotPasswordPage.id: (context) => const ForgotPasswordPage(),
        DiaryHomePage.id: (context) => const DiaryHomePage(),
        TodoListScreen.id: (context) => const TodoListScreen(),
        WeatherScreen.id: (context) => const WeatherScreen(),
      },
    );
  }
}
