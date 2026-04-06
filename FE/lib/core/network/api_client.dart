import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../storage/session_storage.dart';
import 'api_response.dart';

class ApiClient {
  static Uri _buildUri(String path) {
    String cleanPath = path;
    if (cleanPath.startsWith('/api/')) {
      cleanPath = cleanPath.substring(4); // hilangkan /api
    } else if (cleanPath == '/api') {
      cleanPath = '';
    }
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    return Uri.parse('${AppConstants.baseUrl}/api$cleanPath');
  }

  static Future<ApiResponse> get(String path) async {
    final token = await SessionStorage.getToken();

    final response = await http.get(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal terhubung ke server (Kode: ${response.statusCode})');
    }
  }

  static Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionStorage.getToken();

    final response = await http.post(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal memproses data server (Kode: ${response.statusCode})');
    }
  }

  static Future<ApiResponse> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionStorage.getToken();

    final response = await http.put(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal memperbarui data (Kode: ${response.statusCode})');
    }
  }

  static Future<ApiResponse> delete(String path, {Map<String, dynamic>? body}) async {
    final token = await SessionStorage.getToken();

    final response = await http.delete(
      _buildUri(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal menghapus data (Kode: ${response.statusCode})');
    }
  }

  /// Upload file (foto izin/profil/logo) ke backend.
  /// Returns ApiResponse dengan data.url = path file di server.
  static Future<ApiResponse> uploadFile(File file) async {
    final token = await SessionStorage.getToken();

    final uri = _buildUri('/upload');
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal mengunggah file (Kode: ${response.statusCode})');
    }
  }

  /// Multipart POST untuk endpoint khusus (misal: bayar gaji)
  static Future<ApiResponse> postMultipart(String path, {Map<String, File>? files, Map<String, String>? fields}) async {
    final token = await SessionStorage.getToken();
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (var entry in files.entries) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    try {
      final decoded = jsonDecode(response.body);
      return ApiResponse.fromJson(decoded);
    } catch (_) {
      return ApiResponse(status: false, message: 'Gagal mengirim data (Kode: ${response.statusCode})');
    }
  }
}
