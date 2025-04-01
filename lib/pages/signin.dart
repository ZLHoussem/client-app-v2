import 'package:flutter/material.dart';
import 'package:bladi_go_client/service/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';          
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:bladi_go_client/widget/auth_ui/auth_logo.dart';
import 'package:bladi_go_client/widget/auth_ui/login_button.dart';
import 'package:bladi_go_client/widget/auth_ui/remember_me_checkbox.dart';
import 'package:bladi_go_client/widget/auth_ui/signup_link.dart';
import 'package:bladi_go_client/widget/auth_ui/form/email_input.dart';
import 'package:bladi_go_client/widget/auth_ui/form/password_input.dart';
import 'package:bladi_go_client/widget/title.dart'; 

class Signin extends StatefulWidget {
  const Signin({super.key});
  static const String route = '/login';
  @override
  State<Signin> createState() => _SigninState();
}
class _SigninState extends State<Signin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  bool _rememberPassword = true; 
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }
  Future<void> _loadLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString('lastEmail');
      if (mounted) {
        if (lastEmail != null && lastEmail.isNotEmpty) {
          setState(() {
            _emailController.text = lastEmail;
            _rememberPassword = true; 
          });
        } else {
           setState(() {
             _rememberPassword = false;
           });
        }
      }
    } catch (e) {
      print("Error loading last email: $e");
      if (mounted) { 
         _showToast("Erreur lors du chargement de l'email", isError: true);
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; 
    }
    await AuthService.handleLogin(
      context: context,
      formKey: _formKey, 
      emailController: _emailController,
      passwordController: _passwordController,
      rememberPassword: _rememberPassword,
      setLoading: (loading) {
        if (mounted) _isLoadingNotifier.value = loading;
      },
      showToast: _showToast,
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: const TitleApp(text: 'Se connecter', retour: false),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(), 
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthLogo(screenHeight: screenHeight ), 
                  const SizedBox(height: 30),
                  EmailInputWidget(
                    emailController: _emailController,
                    focusNode: _emailFocusNode,
                    nextFocusNode: _passwordFocusNode,
                  ),
                PasswordInputWidgetInternal(
                    labelText: "Mot de Passe",
                    passwordController: _passwordController,
                    focusNode: _passwordFocusNode,
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RememberMeCheckbox(
                    value: _rememberPassword,
                    onChanged: (bool? value) {
                      if (value != null) {
                        setState(() => _rememberPassword = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      return LoginButton(
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleLogin,
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      return SignupLink(isLoading: isLoading);
                    }
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}