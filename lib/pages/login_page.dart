//import 'package:chatapp/pages/home_page.dart';
import 'package:chatapp/pages/main_page.dart';
import 'package:chatapp/pages/register_page.dart';
import 'package:chatapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/widgets/input_text_widget.dart';
import 'package:chatapp/widgets/my_button.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  void login() async {
    String emailText = email.text.trim();
    String passwordText = password.text.trim();
    if (emailText.isEmpty || passwordText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhận đầy đủ thông tin.')),
      );
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithEmail(emailText, passwordText);
      
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } else if (!success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Đăng nhập thất bại.'),
            content: Text(authProvider.errorMessage ?? 'Có lỗi xảy ra'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, size: 100),
                SizedBox(height: 20),
                TextInput(controllertext: email, text: 'Email'),
                SizedBox(height: 15),
                TextInput(
                  controllertext: password,
                  text: 'Password',
                  isPassword: true,
                ),
                SizedBox(height: 15),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : MyButton(text: 'Login', onTap: login);
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản? ",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      ), // Quay lại trang Login
                      child: Text(
                        "Đăng ký ngay",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
