import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class HomeController {
  late GoogleSignIn googleSignIn;
  GoogleSignInAccount? googleSignInAccount;
  Future<void> signin() async {
    try {
      googleSignIn = GoogleSignIn(
        scopes: [
          // drive.DriveApi.driveAppdataScope,
          drive.DriveApi.driveFileScope
        ],
      );

      googleSignInAccount = await googleSignIn.signIn();

      print("User account $googleSignInAccount");
    } catch (e) {
      print(e.toString());
    }
  }

  Future<String?> _getFolderId(drive.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "Date-Records";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        // await showMessage(context, "Sign-in first", "Error");
        print('error');
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      var folder = new drive.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> signOut() async {
    googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    print('signed out');
  }

  Future<drive.DriveApi?> getDriveApi(GoogleSignInAccount googleUser) async {
    drive.DriveApi? driveApi;
    try {
      Map<String, String> headers = await googleUser.authHeaders;
      GoogleAuthClient client = GoogleAuthClient(headers);
      driveApi = drive.DriveApi(client);
    } catch (e) {
      debugPrint(e.toString());
    }
    return driveApi;
  }

  Future<drive.File?> uploadDriveFile({
    required drive.DriveApi driveApi,
    required io.File file,
    String? driveFileId,
  }) async {
    try {
      String? folderId = await _getFolderId(driveApi);
      drive.File fileMetadata = drive.File();
      fileMetadata.name = path.basename(file.absolute.path);

      late drive.File response;
      if (driveFileId != null) {
        /// [driveFileId] not null means we want to update existing file
        response = await driveApi.files.update(
          fileMetadata,
          driveFileId,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        );
      } else {
        /// [driveFileId] is null means we want to create new file
        fileMetadata.parents = ['appDataFolder'];
        response = await driveApi.files.create(
          fileMetadata,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        );
      }
      return response;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<drive.File?> getDriveFile(
      drive.DriveApi driveApi, String filename) async {
    try {
      drive.FileList fileList = await driveApi.files.list(
          spaces: 'appDataFolder', $fields: 'files(id, name, modifiedTime)');
      List<drive.File>? files = fileList.files;
      drive.File? driveFile =
          files?.firstWhere((element) => element.name == filename);
      return driveFile;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final _client = new http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
