import 'dart:io';
import 'package:excel/excel.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImportPreview {
  final String type;
  final int totalRows;
  final int validRows;
  final List<String> columns;
  final List<List<String>> previewRows;
  final List<String> errors;
  final List<Map<String, String>> allRows;
  final String? tempZipDir;
  const ImportPreview({
    required this.type,
    required this.totalRows,
    required this.validRows,
    required this.columns,
    required this.previewRows,
    required this.errors,
    required this.allRows,
    this.tempZipDir,
  });
}

class ImportResult {
  final int imported;
  final int failed;
  final List<String> errors;
  const ImportResult({required this.imported, required this.failed, required this.errors});
}

class DataImportService {
  final AppDatabase db;
  DataImportService(this.db);

  Future<ImportPreview> parseFile(File file, String type) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'zip') {
      return _parseZipFile(file);
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _parseExcel(file, type);
    } else if (ext == 'csv') {
      return _parseCsv(file, type);
    }
    throw ArgumentError('Unsupported file format: $ext');
  }

  Future<ImportResult> executeImport(
    ImportPreview preview, {
    void Function(double progress, String step)? onProgress,
  }) async {
    int imported = 0;
    int failed = 0;
    final errors = <String>[];
    final rows = preview.allRows;

    if (preview.type == 'all') {
      final productRows = rows.where((r) => r['__type__'] == 'products').toList();
      final customerRows = rows.where((r) => r['__type__'] == 'customers').toList();
      final total = productRows.length + customerRows.length;
      if (total == 0) {
        return ImportResult(imported: 0, failed: 0, errors: ['No data to import']);
      }

      onProgress?.call(0.1, 'Importing products…');
      for (int i = 0; i < productRows.length; i++) {
        onProgress?.call(0.1 + (i / productRows.length) * 0.5, 'Product ${i + 1}/${productRows.length}');
        try {
          await _insertProductRow(productRows[i], preview.tempZipDir);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Product ${i + 1}: $e');
        }
      }

      onProgress?.call(0.6, 'Importing customers…');
      for (int i = 0; i < customerRows.length; i++) {
        onProgress?.call(0.6 + (i / customerRows.length) * 0.4, 'Customer ${i + 1}/${customerRows.length}');
        try {
          await _insertCustomerRow(customerRows[i]);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Customer ${i + 1}: $e');
        }
      }
    } else {
      for (int i = 0; i < rows.length; i++) {
        onProgress?.call(i / rows.length, 'Importing row ${i + 1}/${rows.length}…');
        try {
          final row = rows[i];
          final rowType = row['__type__'] ?? preview.type;

          if (rowType == 'products') {
            if (preview.tempZipDir != null) {
              final imgPath = row['Image Path'] ?? row['image_path'] ?? '';
              if (imgPath.isNotEmpty) {
                final basename = p.basename(imgPath);
                final src = File(p.join(preview.tempZipDir!, 'images', basename));
                if (await src.exists()) {
                  final appDir = await getApplicationDocumentsDirectory();
                  final dest = File(p.join(appDir.path, basename));
                  await src.copy(dest.path);
                  row['Image Path'] = dest.path;
                }
              }
            }
            await _insertProductRow(row, preview.tempZipDir);
          } else if (rowType == 'customers') {
            await _insertCustomerRow(row);
          }
          imported++;
        } catch (e) {
          failed++;
          errors.add('Row ${i + 1}: $e');
        }
      }
    }

    if (preview.tempZipDir != null) {
      final dir = Directory(preview.tempZipDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }

    onProgress?.call(1.0, 'Import complete!');
    return ImportResult(imported: imported, failed: failed, errors: errors);
  }

  ImportPreview _parseExcel(File file, String type) {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    String? sheetName;
    for (final key in excel.tables.keys) {
      if (key.toLowerCase() == type.toLowerCase() ||
          (type == 'products' && key.toLowerCase().contains('product')) ||
          (type == 'customers' && key.toLowerCase().contains('customer'))) {
        sheetName = key;
        break;
      }
    }
    sheetName ??= excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.isEmpty) {
      return _emptyPreview(type);
    }

    final headerRow = sheet.rows[0];
    final columns = headerRow
        .map((c) => c?.value?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();

    final allRows = <Map<String, String>>[];
    final errors = <String>[];

    final typeTag = type == 'products' ? 'products' : 'customers';
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final map = <String, String>{'__type__': typeTag};
      for (int j = 0; j < columns.length && j < row.length; j++) {
        map[columns[j]] = row[j]?.value?.toString().trim() ?? '';
      }
      if (map.values.every((v) => v.isEmpty)) continue;
      final err = _validateRow(map, typeTag, i + 1);
      if (err != null) errors.add(err);
      allRows.add(map);
    }

    return ImportPreview(
      type: type,
      totalRows: allRows.length,
      validRows: allRows.length - errors.length,
      columns: columns,
      previewRows: allRows.take(5).map((m) => m.values.toList()).toList(),
      errors: errors,
      allRows: allRows,
    );
  }

  Future<ImportPreview> _parseZipFile(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final extDir = Directory(p.join(tempDir.path, 'import_zip_${DateTime.now().millisecondsSinceEpoch}'));
    await extDir.create(recursive: true);

    for (final file in archive) {
      if (file.isFile) {
        final f = File(p.join(extDir.path, file.name));
        await f.parent.create(recursive: true);
        await f.writeAsBytes(file.content as List<int>);
      }
    }

    final excelBytes = await _findExcelFile(extDir);
    if (excelBytes == null) {
      final legacyProducts = await _findJsonFile(extDir, 'products.json');
      if (legacyProducts != null) {
        return _parseLegacyBackup(extDir.path, legacyProducts);
      }
      await extDir.delete(recursive: true);
      throw Exception('Could not find data file in ZIP.');
    }

    final excel = Excel.decodeBytes(excelBytes);

    final allRows = <Map<String, String>>[];
    final errors = <String>[];

    _extractSheetData(excel, 'products', allRows, errors, 'products');
    _extractSheetData(excel, 'customers', allRows, errors, 'customers');
    _extractSheetData(excel, 'categories', allRows, errors, 'categories');

    if (allRows.isEmpty) {
      await extDir.delete(recursive: true);
      throw Exception('No valid data found in Excel.');
    }

    return ImportPreview(
      type: 'all',
      totalRows: allRows.length,
      validRows: allRows.length - errors.length,
      columns: ['Type', 'Name'],
      previewRows: allRows.take(5).map((m) => [m['__type__'] ?? '', m['Name'] ?? m['name'] ?? '']).toList(),
      errors: errors,
      allRows: allRows,
      tempZipDir: extDir.path,
    );
  }

  Future<List<int>?> _findExcelFile(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.xlsx')) {
        return await entity.readAsBytes();
      }
    }
    return null;
  }

  Future<String?> _findJsonFile(Directory dir, String name) async {
    final file = File(p.join(dir.path, 'data', name));
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<ImportPreview> _parseLegacyBackup(String zipDir, String jsonPath) async {
    final file = File(jsonPath);
    final json = await file.readAsString();
    final data = Map<String, dynamic>.from(_jsonDecode(json));

    final allRows = <Map<String, String>>[];
    final errors = <String>[];

    if (data.containsKey('products')) {
      final products = data['products'] as List;
      for (final p in products) {
        final map = Map<String, String>.from(p as Map);
        map['__type__'] = 'products';
        allRows.add(map);
      }
    }

    if (data.containsKey('customers')) {
      final customers = data['customers'] as List;
      for (final c in customers) {
        final map = Map<String, String>.from(c as Map);
        map['__type__'] = 'customers';
        allRows.add(map);
      }
    }

    return ImportPreview(
      type: 'all',
      totalRows: allRows.length,
      validRows: allRows.length - errors.length,
      columns: ['Type', 'Name'],
      previewRows: allRows.take(5).map((m) => [m['__type__'] ?? '', m['Name'] ?? m['name'] ?? '']).toList(),
      errors: errors,
      allRows: allRows,
      tempZipDir: zipDir,
    );
  }

  Map<String, dynamic> _jsonDecode(String json) {
    return Map<String, dynamic>.from(_jsonParse(json));
  }

  dynamic _jsonParse(String json) {
    return _doJsonParse(_tokenize(json));
  }

  List<String> _tokenize(String json) {
    final tokens = <String>[];
    var i = 0;
    while (i < json.length) {
      if (json[i] == ' ' || json[i] == '\n' || json[i] == '\t' || json[i] == '\r') {
        i++;
        continue;
      }
      if (json[i] == '"') {
        var j = i + 1;
        while (j < json.length && json[j] != '"') {
          if (json[j] == '\\') j++;
          j++;
        }
        tokens.add(json.substring(i, j + 1));
        i = j + 1;
        continue;
      }
      if (json[i] == '{' || json[i] == '}' || json[i] == '[' || json[i] == ']' ||
          json[i] == ':' || json[i] == ',' || json[i] == 'n' || json[i] == 't' || json[i] == 'f') {
        tokens.add(json[i]);
        i++;
        continue;
      }
      if (json[i] == '-' || (json[i].codeUnitAt(0) >= 48 && json[i].codeUnitAt(0) <= 57)) {
        var j = i;
        while (j < json.length && (json[j].codeUnitAt(0) >= 48 && json[j].codeUnitAt(0) <= 57 || json[j] == '.' || json[j] == '-')) {
          j++;
        }
        tokens.add(json.substring(i, j));
        i = j;
        continue;
      }
      i++;
    }
    return tokens;
  }

  dynamic _doJsonParse(List<String> tokens) {
    if (tokens.isEmpty) return null;
    return _parseValue(tokens, 0).$1;
  }

  (dynamic, int) _parseValue(List<String> tokens, int i) {
    if (i >= tokens.length) return (null, i);
    final token = tokens[i];
    if (token == '{') {
      final map = <String, dynamic>{};
      i++;
      while (i < tokens.length && tokens[i] != '}') {
        final key = _parseString(tokens[i]);
        i++;
        if (i < tokens.length && tokens[i] == ':') i++;
        final (value, newI) = _parseValue(tokens, i);
        map[key] = value;
        i = newI;
        if (i < tokens.length && tokens[i] == ',') i++;
      }
      return (map, i + 1);
    }
    if (token == '[') {
      final list = <dynamic>[];
      i++;
      while (i < tokens.length && tokens[i] != ']') {
        final (value, newI) = _parseValue(tokens, i);
        list.add(value);
        i = newI;
        if (i < tokens.length && tokens[i] == ',') i++;
      }
      return (list, i + 1);
    }
    if (token == 't') return (true, i + 1);
    if (token == 'f') return (false, i + 1);
    if (token == 'n') return (null, i + 1);
    final parsed = double.tryParse(token);
    if (parsed != null) {
      if (parsed == parsed.truncateToDouble()) {
        return (parsed.truncate(), i + 1);
      }
      return (parsed, i + 1);
    }
    return (_parseString(token), i + 1);
  }

  String _parseString(String token) {
    if (token.startsWith('"') && token.endsWith('"')) {
      return token.substring(1, token.length - 1).replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
    }
    return token;
  }

  void _extractSheetData(Excel excel, String sheetPattern, List<Map<String, String>> allRows, List<String> errors, String typeTag) {
    String? sheetName;
    for (final key in excel.tables.keys) {
      if (key.toLowerCase().contains(sheetPattern.toLowerCase())) {
        sheetName = key;
        break;
      }
    }
    if (sheetName == null) return;

    final sheet = excel.tables[sheetName]!;
    if (sheet.rows.isEmpty) return;

    final headerRow = sheet.rows[0];
    final columns = headerRow
        .map((c) => c?.value?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final map = <String, String>{'__type__': typeTag};
      for (int j = 0; j < columns.length && j < row.length; j++) {
        map[columns[j]] = row[j]?.value?.toString().trim() ?? '';
      }
      if (map.values.where((v) => v != typeTag).every((v) => v.isEmpty)) continue;
      final err = _validateRow(map, typeTag, i + 1);
      if (err != null) errors.add(err);
      allRows.add(map);
    }
  }

  ImportPreview _parseCsv(File file, String type) {
    final lines = file.readAsLinesSync();
    if (lines.isEmpty) return _emptyPreview(type);

    final columns = _splitCsvLine(lines[0]);
    final allRows = <Map<String, String>>[];
    final errors = <String>[];

    final typeTag = type == 'products' ? 'products' : 'customers';
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = _splitCsvLine(line);
      final map = <String, String>{'__type__': typeTag};
      for (int j = 0; j < columns.length && j < parts.length; j++) {
        map[columns[j]] = parts[j].trim();
      }
      final err = _validateRow(map, typeTag, i + 1);
      if (err != null) errors.add(err);
      allRows.add(map);
    }

    return ImportPreview(
      type: type,
      totalRows: allRows.length,
      validRows: allRows.length - errors.length,
      columns: columns,
      previewRows: allRows.take(5).map((m) => m.values.toList()).toList(),
      errors: errors,
      allRows: allRows,
    );
  }

  Future<void> _insertProductRow(Map<String, String> row, String? tempZipDir) async {
    final name = _field(row, ['Name', 'name', 'Item Name']);
    if (name.isEmpty) throw Exception('Name is required');
    final price = double.tryParse(_field(row, ['Sale Price', 'Price', 'price'])) ?? 0.0;
    final costPrice = double.tryParse(_field(row, ['Cost Price', 'cost_price', 'Purchase Price'])) ?? 0.0;
    final stock = int.tryParse(_field(row, ['Stock', 'stock'])) ?? 0;
    final minStock = int.tryParse(_field(row, ['Min Stock', 'min_stock'])) ?? 0;
    final unit = _field(row, ['Unit', 'unit']).isEmpty ? 'pcs' : _field(row, ['Unit', 'unit']);

    String? imagePath;
    final imgPath = _field(row, ['Image Path', 'imagePath', 'image_path']);
    if (imgPath.isNotEmpty) {
      final basename = p.basename(imgPath);
      final appDir = await getApplicationDocumentsDirectory();
      final dest = File(p.join(appDir.path, basename));
      if (await dest.exists()) {
        imagePath = dest.path;
      }
    }

    await db.into(db.products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        costPrice: drift.Value(costPrice),
        stock: drift.Value(stock),
        minStock: drift.Value(minStock),
        unit: drift.Value(unit),
        category: drift.Value(_nullableField(row, ['Category', 'category'])),
        barcode: drift.Value(_nullableField(row, ['Barcode', 'barcode'])),
        sku: drift.Value(_nullableField(row, ['SKU', 'sku'])),
        nameNepali: drift.Value(_nullableField(row, ['Name (Nepali)', 'nameNepali'])),
        description: drift.Value(_nullableField(row, ['Description', 'description'])),
        imagePath: drift.Value(imagePath ?? _nullableField(row, ['Image Path', 'imagePath', 'image_path'])),
      ),
      mode: drift.InsertMode.insertOrIgnore,
    );
  }

  Future<void> _insertCustomerRow(Map<String, String> row) async {
    final name = _field(row, ['Name', 'name']);
    if (name.isEmpty) throw Exception('Name is required');
    final balance = double.tryParse(_field(row, ['Balance', 'balance'])) ?? 0.0;
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        name: name,
        phone: drift.Value(_nullableField(row, ['Phone', 'phone'])),
        email: drift.Value(_nullableField(row, ['Email', 'email'])),
        address: drift.Value(_nullableField(row, ['Address', 'address'])),
        panNumber: drift.Value(_nullableField(row, ['PAN', 'panNumber'])),
        balance: drift.Value(balance),
      ),
      mode: drift.InsertMode.insertOrIgnore,
    );
  }

  String? _validateRow(Map<String, String> row, String type, int rowNum) {
    if (type == 'products') {
      if (_field(row, ['Name', 'name', 'Item Name']).isEmpty) {
        return 'Row $rowNum: Name is required';
      }
    } else if (type == 'customers') {
      if (_field(row, ['Name', 'name']).isEmpty) {
        return 'Row $rowNum: Name is required';
      }
    }
    return null;
  }

  String _field(Map<String, String> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String? _nullableField(Map<String, String> row, List<String> keys) {
    final v = _field(row, keys);
    return v.isEmpty ? null : v;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  ImportPreview _emptyPreview(String type) => ImportPreview(
        type: type,
        totalRows: 0,
        validRows: 0,
        columns: [],
        previewRows: [],
        errors: ['File is empty or has no data rows'],
        allRows: [],
      );
}