// lib/core/widgets/custom_text_field.dart
import 'package:flutter/material.dart';

// Kita menggunakan StatefulWidget agar widget ini bisa mengurus
// buka-tutup mata password-nya sendiri secara mandiri.
class CustomTextField extends StatefulWidget {
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,

      obscureText: widget.isPassword ? _isObscured : false,
      keyboardType: widget.keyboardType,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        label: Text(widget.labelText),
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyMedium,
        prefixIcon: Icon(widget.prefixIcon, color: theme.primaryColor),

        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: theme.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,

        filled: true,
        fillColor: theme.cardColor,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
