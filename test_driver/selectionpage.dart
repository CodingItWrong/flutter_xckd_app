import 'package:flutter_driver/driver_extension.dart';
import 'package:xckd_app/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(
    const MaterialApp(
      home: app.SelectionPage(),
    ),
  );
}
