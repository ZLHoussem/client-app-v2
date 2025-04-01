import 'package:bladi_go_client/api/firebase_api.dart';
import 'package:bladi_go_client/service/auth_service.dart';
import 'package:bladi_go_client/widget/auth_ui/auth_logo.dart';
import 'package:bladi_go_client/widget/auth_ui/login_link.dart';
import 'package:bladi_go_client/widget/auth_ui/register_button.dart';
import 'package:bladi_go_client/widget/auth_ui/form/email_input.dart';
import 'package:bladi_go_client/widget/auth_ui/form/name_input.dart';
import 'package:bladi_go_client/widget/auth_ui/form/password_input.dart';
import 'package:bladi_go_client/widget/auth_ui/form/phone_input.dart';
import 'package:bladi_go_client/widget/title.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vpasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _vpasswordFocusNode = FocusNode();

  final FirebaseApi _firebaseApi = FirebaseApi();

  String _fullPhoneNumber = '';

  bool _isPasswordVisible = false;
  bool _isVPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vpasswordController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _vpasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleRegistration() {
    FocusScope.of(context).unfocus();

    AuthService.handleRegistration(
      context: context,
      formKey: _formKey,
      nameController: _nameController,
      emailController: _emailController,
      passwordController: _passwordController,
      fullPhoneNumber: _fullPhoneNumber,
      firebaseApi: _firebaseApi,
      setLoading: (loading) {
        if (mounted) {
          setState(() => _isLoading = loading);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const TitleApp(text: "S'inscrire", retour: true),
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
                  AuthLogo(screenHeight: screenHeight),
                  const SizedBox(height: 20),
                  NameInputWidget(
                    nameController: _nameController,
                    focusNode: _nameFocusNode,
                  ),
                  CustomPhoneField(
                    focusNode: _phoneFocusNode,
                    controller: _phoneController,
                    onChanged: (phone) {
                      if (mounted) setState(() => _fullPhoneNumber = phone);
                    },
                    onCountryChanged: (country) {
                      print('Selected country: $country');
                      if (mounted) {
                         _fullPhoneNumber = _fullPhoneNumber.isNotEmpty
                            ? '${_fullPhoneNumber.split(_phoneController.text)[0]}${_phoneController.text}'
                            : '';
                         setState(() {});
                       }
                    },
                  ),
                  EmailInputWidget(
                    emailController: _emailController,
                    focusNode: _emailFocusNode,
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
                  PasswordInputWidgetInternal(
                    labelText: "Confirmer Mot de Passe",
                    passwordController: _vpasswordController,
                    focusNode: _vpasswordFocusNode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                    isPasswordVisible: _isVPasswordVisible,
                    onToggleVisibility: () => setState(
                      () => _isVPasswordVisible = !_isVPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RegisterButton(
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleRegistration,
                  ),
                  const SizedBox(height: 10),
                  const LoginLink(),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
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
