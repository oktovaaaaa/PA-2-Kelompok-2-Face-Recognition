import 'dart:io';
import 'dart:convert';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class FaceService {
  late FaceDetector detector;

  Future<void> init() async {
    detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, 
        enableLandmarks: true, // AKTIFKAN LANDMARK UNTUK MULUT
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<String?> getFaceBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    // kirim gambar asli  ke server agar  di server yang melakukan cropping
    return base64Encode(bytes);
  }

  InputImage getInputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationValue = sensorOrientation;
      // Front camera on Android often needs special handling for rotation
      rotation = InputImageRotationValue.fromRawValue(rotationValue);
    }
    rotation ??= InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() => detector.close();
}
