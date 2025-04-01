
import 'package:bladi_go_client/pages/Home.dart';
import 'package:bladi_go_client/pages/notification.dart';
import 'package:bladi_go_client/pages/signin.dart';
import 'package:bladi_go_client/provider/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Optionally, show an error screen or exit the app
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Checks if the user is logged in and returns their data if available.
  Future<Map<String, dynamic>?> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        return null;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Délai de connexion dépassé.'),
          );

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final id = userData['userId'];
          if (id == null || id is! String || id.trim().isEmpty) {
            await prefs.remove('userId');
            return null;
          }
          return userData;
        }
      }

      await prefs.remove('userId');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error in checkLoginStatus: ${e.message}');
      throw Exception('Erreur Firestore: ${e.message}');
    } on Exception catch (e) {
      debugPrint('Error in checkLoginStatus: $e');
      throw Exception('Erreur: $e');
    } catch (e) {
      debugPrint('Unexpected error in checkLoginStatus: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Add the navigatorKey here
        debugShowCheckedModeBanner: false,
        initialRoute: '/', // Use initialRoute instead of home
        routes: {
          '/':
              (context) => FutureBuilder<Map<String, dynamic>?>(
                future: checkLoginStatus(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Color.fromRGBO(
                            84,
                            131,
                            250,
                            1,
                          ), // Match app theme
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!;
                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );
                    userProvider.setUserId(userData['userId']);
                    return const Home();
                  }

                  return const Signin();
                },
              ),
          '/notification_screen': (context) => const NotificationScreen(),
        },
      ),
    );
  }
}
