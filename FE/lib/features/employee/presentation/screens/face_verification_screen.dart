import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../face_service.dart';

enum FaceAction { neutral, lookLeft, lookRight, lookUp, lookDown, blink, mouthOpen, done }

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> with TickerProviderStateMixin {
  late CameraController _ctrl;
  final _faceService = FaceService();
  
  List<FaceAction> _actions = [];
  int _currentStepIndex = 0;
  bool _isProcessing = false;
  String _hint = "Posisikan wajah di tengah";
  double _progress = 0.0;
  bool _isInitialized = false;
  bool _cooldown = false;

  @override
  void initState() {
    super.initState();
    // 4 Random gestures + Neutral at the end
    final list = [
      FaceAction.lookLeft, 
      FaceAction.lookRight, 
      FaceAction.lookUp, 
      FaceAction.lookDown, 
      FaceAction.blink, 
      FaceAction.mouthOpen
    ];
    list.shuffle();
    _actions = [...list.take(3), FaceAction.neutral, FaceAction.done];
    _setup();
  }

  _setup() async {
    final cameras = await availableCameras();
    CameraDescription? frontCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    frontCamera ??= cameras.isNotEmpty ? cameras.first : null;

    if (frontCamera == null) return;

    _ctrl = CameraController(
      frontCamera, 
      ResolutionPreset.high, 
      enableAudio: false, 
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888
    );

    try {
      await _ctrl.initialize();
      await _faceService.init();
      if (mounted) setState(() => _isInitialized = true);
      _startLiveDetection();
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _startLiveDetection() {
    _ctrl.startImageStream((image) async {
      if (_isProcessing || _cooldown || _actions[_currentStepIndex] == FaceAction.done) return;
      _isProcessing = true;
      try {
        final faces = await _faceService.detector.processImage(
          _faceService.getInputImageFromCameraImage(image, _ctrl.description)
        );
        if (faces.isNotEmpty) {
          _checkGesture(faces.first);
        } else {
          setState(() => _hint = "Wajah tidak terdeteksi");
        }
      } catch (e) {}
      _isProcessing = false;
    });
  }

  void _checkGesture(Face face) async {
    final currentAction = _actions[_currentStepIndex];
    bool success = false;
    
    // Debug Log untuk membantu analisa
    debugPrint("Face Angles -> Y: ${face.headEulerAngleY?.toStringAsFixed(2)}, X: ${face.headEulerAngleX?.toStringAsFixed(2)}");

    switch (currentAction) {
      case FaceAction.neutral: 
        if (face.headEulerAngleY!.abs() < 10 && face.headEulerAngleX!.abs() < 10) success = true; 
        break;
      case FaceAction.lookLeft: 
        if (face.headEulerAngleY! > 30) success = true; 
        break;
      case FaceAction.lookRight: 
        if (face.headEulerAngleY! < -30) success = true; 
        break;
      case FaceAction.lookUp: 
        if (face.headEulerAngleX! > 20) success = true; 
        break;
      case FaceAction.lookDown: 
        if (face.headEulerAngleX! < -20) success = true; 
        break;
      case FaceAction.blink: 
        if ((face.leftEyeOpenProbability ?? 1.0) < 0.1) success = true; 
        break;
      case FaceAction.mouthOpen:
        final mb = face.landmarks[FaceLandmarkType.bottomMouth];
        final ml = face.landmarks[FaceLandmarkType.leftMouth];
        final mr = face.landmarks[FaceLandmarkType.rightMouth];
        if (mb != null && ml != null && mr != null) {
          if ((mb.position.y - (ml.position.y + mr.position.y) / 2) / face.boundingBox.height > 0.12) success = true;
        }
        break;
      default: break;
    }
    
    if (success) {
      setState(() {
        _cooldown = true; // Aktifkan cooldown
        _currentStepIndex++;
        _progress = _currentStepIndex / (_actions.length - 1);
        if (_actions[_currentStepIndex] == FaceAction.done) {
          _hint = "Memindai Wajah Berhasil!";
          _ctrl.stopImageStream();
          _finalizeVerification();
        } else {
          _hint = _getHint(_actions[_currentStepIndex]);
        }
      });
      
      // Tunggu 1 detik agar user bisa reset posisi wajah
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _cooldown = false);
    } else {
      setState(() => _hint = _getHint(currentAction));
    }
  }

  void _finalizeVerification() async {
    try {
      final f = await _ctrl.takePicture();
      final b64 = await _faceService.getFaceBase64(f.path);
      if (mounted) Navigator.pop(context, b64);
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  String _getHint(FaceAction a) {
    switch (a) {
      case FaceAction.lookLeft: return "Menoleh ke Kiri";
      case FaceAction.lookRight: return "Menoleh ke Kanan";
      case FaceAction.lookUp: return "Menghadap ke Atas";
      case FaceAction.lookDown: return "Menghadap ke Bawah";
      case FaceAction.blink: return "Kedipkan Mata";
      case FaceAction.mouthOpen: return "Buka Mulut";
      case FaceAction.neutral: return "Hadap ke Depan";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCamReady = false;
    try {
      isCamReady = _ctrl.value.isInitialized;
    } catch (_) {}

    if (!_isInitialized || !isCamReady) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Text("VERIFIKASI WAJAH", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
          const Spacer(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 360, height: 360, child: CustomPaint(painter: VerificationTicksPainter(_progress))),
                Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12, width: 2)),
                  child: ClipOval(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _ctrl.value.previewSize!.height,
                        height: _ctrl.value.previewSize!.width,
                        child: CameraPreview(_ctrl),
                      ),
                    ),
                  ),
                ),
                if (_cooldown)
                  Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            _hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATALKAN", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    _faceService.dispose(); 
    super.dispose(); 
  }
}

class VerificationTicksPainter extends CustomPainter {
  final double progress;
  VerificationTicksPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..strokeCap = StrokeCap.round;
    const totalTicks = 60;
    for (int i = 0; i < totalTicks; i++) {
      final angle = (i * 2 * math.pi) / totalTicks - (math.pi / 2);
      final isCompleted = (i / totalTicks) < progress;
      paint.color = isCompleted ? const Color(0xFF2563EB) : Colors.black.withOpacity(0.1);
      paint.strokeWidth = isCompleted ? 4 : 2;
      final innerR = radius - 25;
      final outerR = radius - 5;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle)), 
        Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle)), 
        paint
      );
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
