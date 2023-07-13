import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:test/controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // oogleSignInAccount googleSignInAccount = GoogleSignInAccount();
  final HomeController _homeController = HomeController();

  drive.DriveApi? _driveApi;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (_homeController.googleSignInAccount == null) {
                  await _homeController.signin();
                  if (_homeController.googleSignInAccount != null) {
                    _driveApi = await _homeController
                        .getDriveApi(_homeController.googleSignInAccount!);
                  }
                } else {
                  await _homeController.signOut();
                  _homeController.googleSignInAccount = null;
                  _driveApi = null;
                }
                setState(() {});
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: _driveApi != null
                  ? () async {
                      FilePicker.platform.pickFiles().then((value) {
                        if (value != null && value.files[0] != null) {
                          File selectedFile = File(value.files[0].path!);
                          final file = _homeController.uploadDriveFile(
                            driveApi: _driveApi!,
                            file: selectedFile,
                          );
                          print(file);
                        }
                      });
                    }
                  : null,
              child: Text('Save sth to drive'),
            ),
          ],
        ),
      ),
    );
  }
}
