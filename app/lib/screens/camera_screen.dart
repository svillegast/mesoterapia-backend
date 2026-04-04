import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import '../models/face_analysis.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  final _api = ApiService();
  bool _analyzing = false;
  String? _error;

  Future<void> _captureAndAnalyze(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final analysis = await _api.analyzePhoto(File(picked.path));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultsScreen(analysis: analysis)),
      );
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo / título
              const Icon(Icons.face_retouching_natural, size: 72, color: Color(0xFF7B61FF)),
              const SizedBox(height: 16),
              const Text(
                'Análisis Facial IA',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Emprender · Mesoterapia Sin Agujas',
                style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
              ),

              const SizedBox(height: 48),

              // Instrucciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Para mejores resultados:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 8),
                    _Tip(icon: Icons.wb_sunny_outlined, text: 'Buena iluminación frontal'),
                    _Tip(icon: Icons.face, text: 'Rostro centrado, mirada al frente'),
                    _Tip(icon: Icons.do_not_touch_outlined, text: 'Sin maquillaje si es posible'),
                    _Tip(icon: Icons.open_with, text: 'Distancia 30-50 cm de la cámara'),
                  ],
                ),
              ),

              const Spacer(),

              // Error
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),

              // Botones de captura
              if (_analyzing)
                Column(
                  children: const [
                    SpinKitPulse(color: Color(0xFF7B61FF), size: 60),
                    SizedBox(height: 16),
                    Text('Analizando rostro...', style: TextStyle(color: Color(0xFF9E9E9E))),
                  ],
                )
              else ...[
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: 'Tomar foto ahora',
                  primary: true,
                  onTap: () => _captureAndAnalyze(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Elegir de galería',
                  primary: false,
                  onTap: () => _captureAndAnalyze(ImageSource.gallery),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7B61FF)),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13)),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(label),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary ? const Color(0xFF7B61FF) : const Color(0xFF2A2A2A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
