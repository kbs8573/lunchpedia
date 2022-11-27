import 'package:flutter/material.dart';

var theme = ThemeData(
    appBarTheme: AppBarTheme(
        backgroundColor: Color(0xfff77e21),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        actionsIconTheme: IconThemeData(color: Colors.black)),
    fontFamily: 'GmarketSans',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xfff77e21), selectedItemColor: Colors.black));

var myPageTheme = ThemeData(
    appBarTheme: AppBarTheme(
        backgroundColor: Color(0xffd61c4e),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white)),
    fontFamily: 'GmarketSans',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(0xffd61c4e), selectedItemColor: Colors.white));
