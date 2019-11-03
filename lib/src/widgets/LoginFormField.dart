import 'package:flutter/material.dart';

class LoginFormField extends StatelessWidget {
  final IconData icon;
  final bool isObscured;
  final String label;
  final TextEditingController controller;
  LoginFormField(
      {this.icon, this.isObscured = false, this.label, this.controller});
  build(_) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: TextField(
        controller: controller,
        autocorrect: false,
        cursorColor: Color.fromRGBO(255, 255, 255, 0.7),
        obscureText: isObscured,
        style: Theme.of(_).primaryTextTheme.body2,
        decoration: InputDecoration(
            labelText: label,
            labelStyle: Theme.of(_).inputDecorationTheme.labelStyle,
            prefixIcon: Icon(icon, color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white60)),
            focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromRGBO(255, 255, 255, 0.9))),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white60))),
      ),
    );
  }
}
