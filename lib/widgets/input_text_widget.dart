import 'package:flutter/material.dart';

class TextInput extends StatefulWidget {
  TextEditingController controllertext = TextEditingController();
  String text = '';
  bool isPassword;
  TextInput({
    super.key,
    required this.controllertext,
    required this.text,
    this.isPassword = false,
  });

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controllertext,
      obscureText: widget.isPassword ? _obscureText : false,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(width: 1),
        ),
        hintText: widget.text,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                  Future.delayed(const Duration(milliseconds: 2500), () {
                    if (mounted) {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    }
                  });
                },
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
              )
            : null,
      ),
    );
  }
}
