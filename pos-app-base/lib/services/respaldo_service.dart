import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class RespaldoService {
  final _db = DatabaseService.instance;

  Future<void> crearYCompartirRespaldo() async {
    final datos = await _db.exportarTodo();
    final jsonString = const JsonEncoder.withIndent('  ').convert(datos);

    final dir = await getApplicationDocumentsDirectory();
    final hoy = DateTime.now();
    final nombreArchivo =
        'Respaldo_${hoy.year}_${hoy.month.toString().padLeft(2, '0')}_${hoy.day.toString().padLeft(2, '0')}.json';
    final file = File('${dir.path}/$nombreArchivo');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Copia de seguridad',
      text: 'Guarda este archivo en Google Drive para no perder tu información.',
    );
  }
}
