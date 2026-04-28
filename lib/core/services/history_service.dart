import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/backup_models.dart';

class HistoryService {
  static const String _importHistoryKey = 'import_history';
  static const String _exportHistoryKey = 'export_history';
  static const int _maxHistoryRecords = 50;

  Future<List<ImportHistoryRecord>> getImportHistory() async {
    final history = await _loadHistory(_importHistoryKey);
    return history.map((m) => ImportHistoryRecord.fromJson(m)).toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  Future<List<ExportHistoryRecord>> getExportHistory() async {
    final history = await _loadHistory(_exportHistoryKey);
    return history.map((m) => ExportHistoryRecord.fromJson(m)).toList()
      ..sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
  }

  Future<void> addImportRecord(ImportHistoryRecord record) async {
    await _addRecord(_importHistoryKey, record.toJson());
  }

  Future<void> addExportRecord(ExportHistoryRecord record) async {
    await _addRecord(_exportHistoryKey, record.toJson());
  }

  Future<void> deleteImportRecord(String id) async {
    await _deleteRecord(_importHistoryKey, id);
  }

  Future<void> deleteExportRecord(String id) async {
    await _deleteRecord(_exportHistoryKey, id);
  }

  Future<void> clearImportHistory() async {
    await _clearHistory(_importHistoryKey);
  }

  Future<void> clearExportHistory() async {
    await _clearHistory(_exportHistoryKey);
  }

  Future<List<Map<String, dynamic>>> _loadHistory(String key) async {
    try {
      final file = await _getHistoryFile(key);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveHistory(String key, List<Map<String, dynamic>> history) async {
    final file = await _getHistoryFile(key);
    await file.writeAsString(jsonEncode(history));
  }

  Future<void> _addRecord(String key, Map<String, dynamic> record) async {
    final history = await _loadHistory(key);
    history.insert(0, record);
    if (history.length > _maxHistoryRecords) {
      history.removeRange(_maxHistoryRecords, history.length);
    }
    await _saveHistory(key, history);
  }

  Future<void> _deleteRecord(String key, String id) async {
    final history = await _loadHistory(key);
    history.removeWhere((r) => r['id'] == id);
    await _saveHistory(key, history);
  }

  Future<void> _clearHistory(String key) async {
    final file = await _getHistoryFile(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _getHistoryFile(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, '${key}.json'));
  }

  Future<String?> getLatestBackupPath() async {
    final history = await getExportHistory();
    if (history.isEmpty) return null;
    final latest = history.first;
    if (!latest.success) return null;
    
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    final filePath = p.join(backupDir.path, latest.fileName);
    
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  Future<File?> getBackupFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    final filePath = p.join(backupDir.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<List<File>> getAllBackupFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    
    if (!await backupDir.exists()) return [];
    
    final files = <File>[];
    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.endsWith('.zip')) {
        files.add(entity);
      }
    }
    
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<bool> deleteBackupFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    final filePath = p.join(backupDir.path, fileName);
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}