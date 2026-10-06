
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
const RegisterScreen ({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();

}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _bornDate = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return (
    Scaffold(
      appBar: AppBar( title: const Text("Registro"), centerTitle: true),
        body: SafeArea(
      ),
    );
  }
}