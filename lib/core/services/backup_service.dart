import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  static Future<String?> getCurrentUserEmail() async {
    final account = _googleSignIn.currentUser;
    return account?.email;
  }

  static Future<bool> backupDatabase() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw Exception('Not signed in');
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Get database file
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbDir.path}/digital_khata.db');

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      // Create backup file metadata
      final driveFile = drive.File()
        ..name = 'digital_khata_backup_${DateTime.now().millisecondsSinceEpoch}.db'
        ..parents = ['appDataFolder'];

      // Upload to Google Drive
      final media = drive.Media(dbFile.openRead(), await dbFile.length());
      await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restoreDatabase() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw Exception('Not signed in');
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // List backup files
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        orderBy: 'createdTime desc',
        pageSize: 1,
        q: "name contains 'digital_khata_backup'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backup found');
      }

      final latestBackup = fileList.files!.first;

      // Download backup
      final media = await driveApi.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Save to local database
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbDir.path}/digital_khata.db');

      final sink = dbFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BackupInfo>> listBackups() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        return [];
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        orderBy: 'createdTime desc',
        q: "name contains 'digital_khata_backup'",
      );

      if (fileList.files == null) {
        return [];
      }

      return fileList.files!.map((file) {
        return BackupInfo(
          id: file.id!,
          name: file.name!,
          createdTime: file.createdTime ?? DateTime.now(),
          size: int.tryParse(file.size?.toString() ?? '0') ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteBackup(String fileId) async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        return false;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class BackupInfo {
  final String id;
  final String name;
  final DateTime createdTime;
  final int size;

  BackupInfo({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.size,
  });
}
