import 'package:chatapp/pages/login_page.dart';
import 'package:chatapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/widgets/input_text_widget.dart';
import 'package:chatapp/widgets/my_button.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  void register() async {
    String emailText = email.text.trim();
    String passwordText = password.text.trim();
    String confirmPasswordtext = confirm_password.text.trim();
    if (passwordText != confirmPasswordtext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lại password')),
      );
      password.clear();
      confirm_password.clear();
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.registerWithEmail(emailText, passwordText);
      
      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
        );
      } else if (!success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Đăng ký thất bại.'),
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
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.message, size: 100),
              SizedBox(height: 15),
              TextInput(controllertext: email, text: 'Email'),
              SizedBox(height: 15),
              TextInput(
                controllertext: password,
                text: 'Password',
                isPassword: true,
              ),
              SizedBox(height: 15),
              TextInput(
                controllertext: confirm_password,
                text: 'Confirm Password',
                isPassword: true,
              ),
              SizedBox(height: 15),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return authProvider.isLoading
                      ? const CircularProgressIndicator()
                      : MyButton(text: 'Register', onTap: register);
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Đã có tài khoản? ",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context), // Quay lại trang Login
                    child: Text(
                      "Đăng nhập ngay",
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
    );
  }
}
