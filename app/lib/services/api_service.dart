import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/face_analysis.dart';

class ApiService {
  // Cambia por tu IP del servidor Contabo o localhost para desarrollo
  static const String _baseUrl = 'https://mesoterapia-backend.nwihlm.easypanel.host';

  Future<FaceAnalysis> analyzePhoto(File photo) async {
    final uri = Uri.parse('$_baseUrl/api/analyze');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return FaceAnalysis.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 422) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(body['detail'] ?? 'No se detectó rostro en la imagen.');
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }

  Future<bool> sendWhatsApp({
    required String phone,
    required String reportImageBase64,
    required String whatsappText,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/send-whatsapp');
    final response = await http.post(
      uri,
      body: {
        'phone': phone,
        'report_image_b64': reportImageBase64,
        'whatsapp_text': whatsappText,
      },
    ).timeout(const Duration(seconds: 20));

    return response.statusCode == 200;
  }
}
