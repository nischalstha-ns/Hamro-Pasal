import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/services/data_import_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/drive_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA OPERATION STATE (progress tracking)
// ─────────────────────────────────────────────────────────────────────────────

enum OperationStatus { idle, running, done, error }

class DataOperationState {
  final OperationStatus status;
  final double progress; // 0.0 – 1.0
  final String currentStep;
  final List<String> logs;
  final String? error;
  final Object? resultData;

  const DataOperationState({
    this.status = OperationStatus.idle,
    this.progress = 0.0,
    this.currentStep = '',
    this.logs = const [],
    this.error,
    this.resultData,
  });

  DataOperationState copyWith({
    OperationStatus? status,
    double? progress,
    String? currentStep,
    List<String>? logs,
    String? error,
    Object? resultData,
  }) {
    return DataOperationState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      logs: logs ?? this.logs,
      error: error,
      resultData: resultData ?? this.resultData,
    );
  }
}

class DataOperationNotifier extends StateNotifier<DataOperationState> {
  DataOperationNotifier() : super(const DataOperationState());

  void _update(double progress, String step) {
    state = state.copyWith(
      status: OperationStatus.running,
      progress: progress,
      currentStep: step,
      logs: [...state.logs, step],
    );
  }

  void reset() => state = const DataOperationState();

  void _done({Object? resultData}) {
    state = state.copyWith(status: OperationStatus.done, progress: 1.0, resultData: resultData);
  }

  void _error(String message) {
    state = state.copyWith(status: OperationStatus.error, error: message);
  }

  // ─── Export ────────────────────────────────────────────────────────────────

  Future<Object?> exportExcel(AppDatabase db, ExportMode mode) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = DataExportService(db);
      final file = await service.exportToExcel(mode: mode, onProgress: _update);
      _done(resultData: file);
      return file;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  Future<Object?> exportCsv(AppDatabase db, String type) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = DataExportService(db);
      final file = await service.exportToCsv(type, onProgress: _update);
      _done(resultData: file);
      return file;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  Future<Object?> exportEverythingAsZip(AppDatabase db) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = DataExportService(db);
      final file = await service.exportEverythingAsZip(onProgress: _update);
      _done(resultData: file);
      return file;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  Future<ImportResult?> runImport(AppDatabase db, ImportPreview preview) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = DataImportService(db);
      final result = await service.executeImport(preview, onProgress: _update);
      _done(resultData: result);
      return result;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  // ─── Backup ────────────────────────────────────────────────────────────────

  Future<Object?> createLocalBackup(AppDatabase db) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = BackupService(db);
      final file = await service.createBackup(onProgress: _update);
      _done(resultData: file);
      return file;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  Future<RestoreResult?> restoreLocalBackup(AppDatabase db, dynamic backupFile) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      final service = BackupService(db);
      final result = await service.restoreBackup(backupFile, onProgress: _update);
      _done(resultData: result);
      return result;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }

  // ─── Drive ─────────────────────────────────────────────────────────────────

  Future<bool> uploadToDrive(AppDatabase db, DriveService driveService) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      _update(0.05, 'Creating local backup…');
      final backupService = BackupService(db);
      final file = await backupService.createBackup(onProgress: (p, s) => _update(p * 0.5, s));
      _update(0.55, 'Uploading to Google Drive…');
      await driveService.uploadBackup(file, onProgress: (p, s) => _update(0.55 + p * 0.45, s));
      _done();
      return true;
    } catch (e) {
      _error(e.toString());
      return false;
    }
  }

  Future<RestoreResult?> downloadAndRestoreFromDrive(
      AppDatabase db, DriveService driveService, DriveBackupEntry entry) async {
    state = const DataOperationState(status: OperationStatus.running);
    try {
      _update(0.05, 'Downloading from Google Drive…');
      final file = await driveService.downloadBackup(
        entry.id,
        entry.name,
        onProgress: (p, s) => _update(p * 0.4, s),
      );
      _update(0.45, 'Restoring data…');
      final backupService = BackupService(db);
      final result = await backupService.restoreBackup(
        file,
        onProgress: (p, s) => _update(0.45 + p * 0.55, s),
      );
      _done(resultData: result);
      return result;
    } catch (e) {
      _error(e.toString());
      return null;
    }
  }
}

final dataOperationProvider =
    StateNotifierProvider.autoDispose<DataOperationNotifier, DataOperationState>(
  (ref) => DataOperationNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// DRIVE SERVICE SINGLETON
// ─────────────────────────────────────────────────────────────────────────────

final driveServiceProvider = Provider<DriveService>((ref) => DriveService());

// ─────────────────────────────────────────────────────────────────────────────
// DRIVE AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────

class DriveAuthState {
  final bool isSignedIn;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  const DriveAuthState({
    this.isSignedIn = false,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}

class DriveAuthNotifier extends StateNotifier<DriveAuthState> {
  DriveAuthNotifier(this._driveService) : super(const DriveAuthState()) {
    _init();
  }

  final DriveService _driveService;

  Future<void> _init() async {
    final signedIn = await _driveService.isSignedIn();
    if (signedIn) {
      await _driveService.currentUser;
      state = DriveAuthState(
        isSignedIn: true,
        email: _driveService.userEmail,
        displayName: _driveService.userDisplayName,
        photoUrl: _driveService.userPhotoUrl,
      );
    }
  }

  Future<bool> signIn() async {
    final success = await _driveService.signIn();
    if (success) {
      state = DriveAuthState(
        isSignedIn: true,
        email: _driveService.userEmail,
        displayName: _driveService.userDisplayName,
        photoUrl: _driveService.userPhotoUrl,
      );
    }
    return success;
  }

  Future<void> signOut() async {
    await _driveService.signOut();
    state = const DriveAuthState();
  }
}

final driveAuthProvider = StateNotifierProvider<DriveAuthNotifier, DriveAuthState>((ref) {
  return DriveAuthNotifier(ref.watch(driveServiceProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// DRIVE BACKUPS LIST
// ─────────────────────────────────────────────────────────────────────────────

final driveBackupsProvider = FutureProvider.autoDispose<List<DriveBackupEntry>>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  final isSignedIn = await driveService.isSignedIn();
  if (!isSignedIn) return [];
  return driveService.listBackups();
});

