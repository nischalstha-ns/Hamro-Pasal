import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

const _kDriveFolderName = 'HamroByapar Backups';

class DriveBackupEntry {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime createdTime;
  const DriveBackupEntry({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.createdTime,
  });
}

class DriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;

  // ─────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<bool> isSignedIn() async => _googleSignIn.isSignedIn();

  String? get userEmail => _currentUser?.email ?? _googleSignIn.currentUser?.email;
  String? get userDisplayName =>
      _currentUser?.displayName ?? _googleSignIn.currentUser?.displayName;
  String? get userPhotoUrl =>
      _currentUser?.photoUrl ?? _googleSignIn.currentUser?.photoUrl;

  Future<GoogleSignInAccount?> get currentUser async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser;
  }

  // ─────────────────────────────────────────────────────
  // UPLOAD
  // ─────────────────────────────────────────────────────

  Future<String> uploadBackup(
    File file, {
    void Function(double progress, String step)? onProgress,
  }) async {
    final api = await _getDriveApi();
    onProgress?.call(0.1, 'Connecting to Google Drive…');

    final folderId = await _getOrCreateBackupFolder(api);
    onProgress?.call(0.3, 'Uploading backup…');

    final fileSize = await file.length();
    final media = drive.Media(file.openRead(), fileSize);
    final driveFile = drive.File()
      ..name = file.uri.pathSegments.last
      ..parents = [folderId];

    final result = await api.files.create(
      driveFile,
      uploadMedia: media,
    );

    onProgress?.call(1.0, 'Upload complete! (${result.name})');
    return result.id!;
  }

  // ─────────────────────────────────────────────────────
  // LIST
  // ─────────────────────────────────────────────────────

  Future<List<DriveBackupEntry>> listBackups() async {
    final api = await _getDriveApi();
    final folderId = await _getOrCreateBackupFolder(api);

    final result = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,size,createdTime)',
    );

    return (result.files ?? []).map((f) {
      return DriveBackupEntry(
        id: f.id!,
        name: f.name!,
        sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
        createdTime: f.createdTime ?? DateTime.now(),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────
  // DOWNLOAD
  // ─────────────────────────────────────────────────────

  Future<File> downloadBackup(
    String fileId,
    String fileName, {
    void Function(double progress, String step)? onProgress,
  }) async {
    final api = await _getDriveApi();
    onProgress?.call(0.1, 'Downloading from Google Drive…');

    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$fileName');
    final sink = file.openWrite();
    await media.stream.pipe(sink);
    await sink.close();

    onProgress?.call(1.0, 'Download complete!');
    return file;
  }

  // ─────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────

  Future<void> deleteBackup(String fileId) async {
    final api = await _getDriveApi();
    await api.files.delete(fileId);
  }

  // ─────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────

  Future<drive.DriveApi> _getDriveApi() async {
    var account = _currentUser ?? await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) throw Exception('Not signed in to Google');
    _currentUser = account;
    final headers = await account.authHeaders;
    return drive.DriveApi(_AuthClient(headers));
  }

  Future<String> _getOrCreateBackupFolder(drive.DriveApi api) async {
    // Search for existing folder
    final result = await api.files.list(
      q: "name='$_kDriveFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      $fields: 'files(id,name)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }
    // Create folder
    final folder = drive.File()
      ..name = _kDriveFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }
}

/// Authenticated HTTP client using Google Sign-In headers.
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
