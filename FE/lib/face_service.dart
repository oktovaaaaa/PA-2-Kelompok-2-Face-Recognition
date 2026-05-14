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
    final inputImage = InputImage.fromFilePath(path);
    final faces = await detector.processImage(inputImage);
    final bytes = await File(path).readAsBytes();
    
    // Jika deteksi wajah gagal di foto yang baru diambil, kirim gambar asli sebagai fallback
    if (faces.isEmpty) {
      return base64Encode(bytes);
    }

    img.Image? raw = img.decodeImage(bytes);
    if (raw == null) return base64Encode(bytes);

    Face f = faces.first;
    try {
      img.Image cropped = img.copyCrop(
        raw,
        x: f.boundingBox.left.toInt(),
        y: f.boundingBox.top.toInt(),
        width: f.boundingBox.width.toInt(),
        height: f.boundingBox.height.toInt(),
      );
      img.Image resized = img.copyResize(cropped, width: 112, height: 112);
      return base64Encode(img.encodeJpg(resized));
    } catch (e) {
      // Jika crop gagal (misal koordinat out of bounds), kirim gambar asli
      return base64Encode(bytes);
    }
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
