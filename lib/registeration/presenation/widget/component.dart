import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../business_logic/auth_cubit/sign_up_cubit.dart';

void showToast({
  required String msg,
  required ToastStates state,
}) =>
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 5,
      backgroundColor: chooseToastColor(state),
      textColor: Colors.white,
      fontSize: 16.0,
    );

Color chooseToastColor(ToastStates state) {
  switch (state) {
    case ToastStates.SUCCESS:
      return Colors.green;
    case ToastStates.ERROR:
      return Colors.red;
    case ToastStates.WARNING:
      return Colors.amber;
  }
}

enum ToastStates { SUCCESS, ERROR, WARNING }


Widget buildTextFormField(
    String labelText,
    TextEditingController controller,
    TextInputType keyboardType,
    String hintText,
    String? Function(String?) validator, {
      bool obscureText = false,
      Color textColor = Colors.white,
      Color hintColor = Colors.white54,
      Color iconColor = Colors.white70,
    }) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    style: TextStyle(color: textColor),
    decoration: InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: textColor),
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: textColor.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: textColor,
        ),
      ),
      prefixIcon: Icon(
        Icons.person, // Adjust this icon as needed based on the field context
        color: iconColor,
      ),
    ),
    validator: validator,
  );
}


String generateRandomPassword() {
  var random = Random.secure();
  var values = List<int>.generate(6, (i) => random.nextInt(255));
  return base64Url.encode(values);
}
