import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class FaceService {
  // URL Python Face Service
  // PENTING: Ganti dengan IP komputer yang menjalankan Python service
  // Untuk Android Emulator: gunakan 10.0.2.2
  // Untuk Physical Device: gunakan IP lokal komputer (cek dengan ipconfig/ifconfig)
  static const String pythonBaseUrl = 'http://10.124.88.112:5001';

  static const String endpointValidateFace = '/validate-face';
  static const String endpointEnrollFace = '/enroll-base64';

  static const Duration timeoutDuration =
      Duration(seconds: 30); // Increase timeout

  /// Normalize base64 string - remove whitespace and newlines
  String _normalizeBase64(String base64String) {
    // Remove any whitespace, newlines, and ensure clean base64
    return base64String.replaceAll(RegExp(r'\s'), '');
  }

  /// Resize and compress image to reduce payload size
  Future<Uint8List> _resizeAndCompressImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        print('[FaceService] Failed to decode image');
        return bytes; // Return original if decode fails
      }

      print(
          '[FaceService] Original image size: ${image.width}x${image.height}');

      // Resize image to max 800px width/height while maintaining aspect ratio
      img.Image resized;
      if (image.width > 800 || image.height > 800) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 800);
        } else {
          resized = img.copyResize(image, height: 800);
        }
        print('[FaceService] Resized to: ${resized.width}x${resized.height}');
      } else {
        resized = image;
      }

      // Compress as JPEG with quality 85
      final compressed = img.encodeJpg(resized, quality: 85);
      print(
          '[FaceService] Compressed size: ${compressed.length} bytes (original: ${bytes.length} bytes)');

      return Uint8List.fromList(compressed);
    } catch (e) {
      print('[FaceService] Error resizing image: $e');
      // Return original bytes if resize fails
      return await imageFile.readAsBytes();
    }
  }

  /// Validate face image - cek apakah ada wajah yang valid
  Future<FaceValidationResult> validateFace(File imageFile) async {
    try {
      print('[FaceService] Starting face validation...');

      // Resize and compress image first to reduce payload size
      final bytes = await _resizeAndCompressImage(imageFile);
      String base64Image = base64Encode(bytes);

      // Normalize base64 to ensure clean string
      base64Image = _normalizeBase64(base64Image);

      print(
          '[FaceService] Image converted to base64, size: ${bytes.length} bytes');
      print(
          '[FaceService] Sending POST request to: $pythonBaseUrl$endpointValidateFace');

      final response = await http
          .post(
            Uri.parse('$pythonBaseUrl$endpointValidateFace'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(timeoutDuration);

      print('[FaceService] Response status: ${response.statusCode}');
      print('[FaceService] Response body: ${response.body}');

      final jsonData = jsonDecode(response.body);

      // Python returns: {"valid": true, "faces_detected": 1, "message": "..."}
      // or: {"success": true, "face_valid": true, "face_count": 1}
      final isValid = jsonData['valid'] == true ||
          jsonData['face_valid'] == true ||
          jsonData['success'] == true;
      final faceCount =
          jsonData['faces_detected'] ?? jsonData['face_count'] ?? 0;

      if (response.statusCode == 200 && isValid) {
        print('[FaceService] Face validation SUCCESS!');
        return FaceValidationResult(
          success: true,
          faceValid: true,
          faceCount: faceCount,
          base64Image: base64Image, // Simpan untuk digunakan di enroll
        );
      } else {
        print('[FaceService] Face validation FAILED');
        return FaceValidationResult(
          success: false,
          faceValid: false,
          error: jsonData['error'] ??
              jsonData['message'] ??
              'Face validation failed',
        );
      }
    } catch (e) {
      print('[FaceService] Exception during face validation: $e');
      return FaceValidationResult(
        success: false,
        faceValid: false,
        error: 'Connection error: $e',
      );
    }
  }

  /// Enroll face - daftarkan wajah ke Python service
  Future<FaceEnrollResult> enrollFace({
    required int userId,
    required String name,
    required String base64Image,
  }) async {
    try {
      print('[FaceService] Starting face enrollment...');
      print('[FaceService] User ID: $userId, Name: $name');
      print(
          '[FaceService] Sending POST request to: $pythonBaseUrl$endpointEnrollFace');

      // Normalize base64 to ensure clean string
      final cleanBase64 = _normalizeBase64(base64Image);
      print('[FaceService] Base64 image length: ${cleanBase64.length}');

      final response = await http
          .post(
            Uri.parse('$pythonBaseUrl$endpointEnrollFace'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'name': name,
              'image': cleanBase64,
            }),
          )
          .timeout(timeoutDuration);

      print('[FaceService] Enroll response status: ${response.statusCode}');
      print('[FaceService] Enroll response body: ${response.body}');

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        return FaceEnrollResult(
          success: true,
          filename: jsonData['filename'],
          message: jsonData['message'] ?? 'Face enrolled successfully',
        );
      } else {
        return FaceEnrollResult(
          success: false,
          error: jsonData['error'] ?? 'Face enrollment failed',
        );
      }
    } catch (e) {
      print('[FaceService] Exception during face enrollment: $e');
      return FaceEnrollResult(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }

  /// Check if Python face service is available
  Future<bool> isServiceAvailable() async {
    try {
      print('[FaceService] Checking service availability...');
      print('[FaceService] Sending GET request to: $pythonBaseUrl/health');

      final response = await http
          .get(Uri.parse('$pythonBaseUrl/health'))
          .timeout(const Duration(seconds: 5));

      print('[FaceService] Health check status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('[FaceService] Health check response: $jsonData');
        return jsonData['success'] == true;
      }
      return false;
    } catch (e) {
      print('[FaceService] Health check failed: $e');
      return false;
    }
  }
}

/// Result dari validasi wajah
class FaceValidationResult {
  final bool success;
  final bool faceValid;
  final int faceCount;
  final String? error;
  final String? base64Image; // Untuk disimpan dan digunakan di enroll

  FaceValidationResult({
    required this.success,
    required this.faceValid,
    this.faceCount = 0,
    this.error,
    this.base64Image,
  });
}

/// Result dari enrollment wajah
class FaceEnrollResult {
  final bool success;
  final String? filename; // Nama file .pkl yang dihasilkan
  final String? message;
  final String? error;

  FaceEnrollResult({
    required this.success,
    this.filename,
    this.message,
    this.error,
  });
}
