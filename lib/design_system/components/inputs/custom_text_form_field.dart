import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: label,
        obscureText: isPassword,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(icon, color: CupertinoColors.systemGrey),
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
