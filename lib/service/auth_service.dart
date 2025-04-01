// lib/services/auth_service.dart

import 'package:bcrypt/bcrypt.dart';
import 'package:bladi_go_client/api/firebase_api.dart'; // Needed for initNotifications
import 'package:bladi_go_client/models/user_model.dart'; // Needed for UserModel
import 'package:bladi_go_client/pages/home.dart'; // Needed for navigation
import 'package:bladi_go_client/provider/user.dart'; // Needed for UserProvider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Needed for BuildContext, ScaffoldMessenger, etc.
import 'package:provider/provider.dart'; // Needed for context.read
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Hashes a password using bcrypt.
  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Verifies a password against a hashed password.
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      print("Error verifying password: $e");
      return false;
    }
  }

  /// Checks if an email is already in use in Firestore.
  static Future<bool> isEmailTaken(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if email is taken: $e");
      return true; // Default to true on error to be safe? Or handle differently.
    }
  }

  /// Persists the user ID in shared preferences.
  static Future<void> persistUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
    } catch (e) {
      print("Error persisting user ID: $e");
      // Handle error appropriately (e.g., log, show message)
    }
  }

  /// Removes the persisted user ID from shared preferences.
  static Future<void> removePersistedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
    } catch (e) {
      print("Error removing persisted user ID: $e");
      // Handle error appropriately
    }
  }


  /// --- Handles the entire user registration flow ---
  static Future<void> handleRegistration({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required String fullPhoneNumber,
    required FirebaseApi firebaseApi,
    required Function(bool) setLoading,
  }) async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      print("Form validation failed.");
      return;
    }

    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text;
    final trimmedPhone = fullPhoneNumber.trim();

    if (trimmedPhone.isEmpty || !trimmedPhone.startsWith('+') || trimmedPhone.length < 8) {
      // Use ScaffoldMessenger directly for consistency within the service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone invalide ou incomplet.')),
      );
      return;
    }

    setLoading(true);
    bool emailExists = false;
    try {
      emailExists = await AuthService.isEmailTaken(email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la vérification de l\'email.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setLoading(false);
      return;
    }

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cette adresse e-mail est déjà utilisée.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setLoading(false);
      return;
    }

    try {
      final hashedPassword = AuthService.hashPassword(password);
      // Consider using Firestore's auto-generated ID or Firebase Auth UID
      // Using timestamp is less robust for uniqueness guarantees.
      final docRef = FirebaseFirestore.instance.collection('users').doc();
      final userId = docRef.id; // Use Firestore's generated ID

      final user = UserModel(
        userId: userId, // Use the generated doc ID
        name: name,
        phone: trimmedPhone,
        email: email,
        password: hashedPassword,
        createdAt: DateTime.now().toIso8601String(),
      );

      await docRef.set(user.toMap()); // Use the reference to set data

      // Update Provider & Persist ID
      // Check if context is still valid before using it after an await
       if (!context.mounted) return; // Check if widget is still in tree
      context.read<UserProvider>().setUserId(user.userId);
      await AuthService.persistUserId(user.userId);

      // Initialize Notifications
       if (!context.mounted) return; // Check again before next async gap
      await firebaseApi.initNotifications(context);

      // Show Success Feedback and Navigate
      if (!context.mounted) return; // Check before UI operations
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
        (route) => false,
      );

    } catch (e, s) {
      print("Error during user creation or subsequent steps: $e\n$s");
       if (!context.mounted) return; // Check before showing snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création du compte: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // Ensure loading state is always turned off
      // Check context validity if setLoading modifies state of a widget
      // associated with the original context. Usually safe if it's a simple bool flag.
       setLoading(false);
    }
  }

  /// --- Handles the user login flow ---
  static Future<void> handleLogin ({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required bool rememberPassword, // To decide whether to persist the userId
   // To initialize notifications on login
    required Function(bool) setLoading,
    required Function(String, {bool isError}) showToast, // Callback for feedback
  }) async {
    // 1. Validate the Form
    final isValid = formKey.currentState?.validate() ?? true;
    if (!isValid) {
      print("Login form validation failed.");
      return; // Exit if form is invalid
    }

    // 2. Get Inputs
    final email = emailController.text.trim();
    final password = passwordController.text; // Don't trim password

    setLoading(true); // Start loading indicator

    try {
      // 3. Query Firestore for the user by email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1) // We expect only one user per email
          .get();

      // 4. Check if user exists
      if (querySnapshot.docs.isEmpty) {
        // User not found
        showToast('Email ou mot de passe invalide.', isError: true);
        // No need to call setLoading(false) here, 'finally' will handle it.
        return;
      }

      // 5. User found, get data and verify password
      final userData = querySnapshot.docs.first.data();
      final storedHashedPassword = userData['password'] as String?;
      final userId = userData['userId'] as String?; // Assuming userId is stored in the doc

      // Basic check if essential data is present
      if (storedHashedPassword == null || userId == null) {
        print("Error: User data missing critical fields (password or userId) for email: $email");
        showToast('Erreur de compte. Veuillez contacter le support.', isError: true);
        return;
      }

      // 6. Verify the password using the service method
      final bool isPasswordCorrect = AuthService.verifyPassword(password, storedHashedPassword);

      if (!isPasswordCorrect) {
        // Incorrect password
        showToast('Email ou mot de passe invalide.', isError: true);
        return;
      }

      // 7. Password is Correct - Login Success
      // Check context validity before updating provider/navigating
      if (!context.mounted) return;
      context.read<UserProvider>().setUserId(userId);

      // 8. Persist or remove User ID based on 'rememberPassword'
      if (rememberPassword) {
        await AuthService.persistUserId(userId);
      } else {
        // If user explicitly doesn't want to be remembered, clear any previous persistence
        await AuthService.removePersistedUserId();
      }

      // 9. Initialize Notifications (good practice to do on login too)
      // Check context validity again if needed

      // 10. Show Success Feedback and Navigate
       if (!context.mounted) return; // Final check before UI ops
      showToast('Connexion réussie !', isError: false); // Use the success style
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
        (route) => false, // Remove all previous routes
      );

    } catch (e, s) {
      // Handle potential errors during Firestore query, etc.
      print("Error during login process: $e\n$s");
       // Check context before showing toast from catch block
       if (!context.mounted) return;
      showToast('Erreur lors de la connexion: ${e.toString()}', isError: true);
    } finally {
      // Ensure loading indicator is always turned off
      // Check context validity if setLoading modifies state of a widget
      // associated with the original context. Usually safe if it's a simple bool flag.
      setLoading(false);
    }
  }


  // Add other authentication methods here (logout, password reset linkage, etc.)
  // static Future<void> handleLogout(BuildContext context) async {
  //   try {
  //       // Clear provider state
  //       context.read<UserProvider>().clearUser();

  //       // Clear persisted user ID
  //       await removePersistedUserId();

  //       // Navigate to login screen (or initial screen)
  //       // Assuming '/login' is your login route name
  //       // Adjust if using MaterialPageRoute directly
  //       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

  //       // Optional: Show logout confirmation
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Vous avez été déconnecté.'))
  //       );
  //        // Optional: Unsubscribe from notifications if applicable
  //        // await FirebaseMessaging.instance.deleteToken(); // Example

  //   } catch (e) {
  //       print("Error during logout: $e");
  //       // Show error message if needed
  //       if (!context.mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //               content: Text('Erreur lors de la déconnexion: $e'),
  //               backgroundColor: Theme.of(context).colorScheme.error
  //           )
  //       );
  //   }
  // }

}