import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/face_analysis.dart';
import '../services/api_service.dart';

class WhatsAppScreen extends StatefulWidget {
  final FaceAnalysis analysis;
  const WhatsAppScreen({super.key, required this.analysis});

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  final _phoneCtrl = TextEditingController();
  final _api = ApiService();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  String _cleanPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('593')) return digits;
    if (digits.startsWith('0')) return '593${digits.substring(1)}';
    return '593$digits';
  }

  Future<void> _send() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'Ingresa un número de celular válido');
      return;
    }

    setState(() { _sending = true; _error = null; });

    try {
      final ok = await _api.sendWhatsApp(
        phone: _cleanPhone(phone),
        reportImageBase64: widget.analysis.reportImageBase64,
        whatsappText: widget.analysis.whatsappText,
      );
      setState(() { _sent = ok; if (!ok) _error = 'Error al enviar. Verifica el número.'; });
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar por WhatsApp'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _SuccessView() : _FormView(
          phoneCtrl: _phoneCtrl,
          sending: _sending,
          error: _error,
          onSend: _send,
          analysis: widget.analysis,
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final bool sending;
  final String? error;
  final VoidCallback onSend;
  final FaceAnalysis analysis;

  const _FormView({
    required this.phoneCtrl,
    required this.sending,
    required this.error,
    required this.onSend,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.whatsapp, size: 56, color: Color(0xFF25D366)),
        const SizedBox(height: 16),
        const Text(
          'Enviar análisis al cliente',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'El cliente recibirá la imagen del análisis y las recomendaciones personalizadas.',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        ),
        const SizedBox(height: 28),

        // Vista previa del texto
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Text(
              analysis.whatsappText,
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Input teléfono
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Número de celular del cliente',
            labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
            hintText: '0991234567 o 593991234567',
            hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
            ),
          ),
        ),

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(sending ? 'Enviando...' : 'Enviar por WhatsApp'),
            onPressed: sending ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 80),
            const SizedBox(height: 20),
            const Text(
              '¡Análisis enviado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'El cliente recibió el reporte con las recomendaciones personalizadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Nuevo análisis'),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF7B61FF)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
}
