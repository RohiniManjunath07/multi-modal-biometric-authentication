import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import 'embedding_model_service.dart';

/// Orchestrates all face-related ML operations:
///   1. Detecting faces in a camera frame via ML Kit.
///   2. Cropping and resizing the face region to 112 × 112.
///   3. Generating the MobileFaceNet embedding.
class FaceService {
  final EmbeddingModelService _embeddingService;

  // ML Kit face detector – configured for accuracy.
  late final FaceDetector _faceDetector;

  FaceService(this._embeddingService) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
        minFaceSize: 0.10,
      ),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Processes a raw [CameraImage] (from camera plugin) and returns a
  /// 192-dimensional embedding.
  ///
  /// Throws domain [Failure] subclasses for:
  ///   * [NoFaceDetectedFailure]       – zero faces found
  ///   * [MultipleFacesDetectedFailure] – more than one face found
  ///   * [FaceDetectionFailure]        – ML Kit error
  ///   * [ModelFailure]                – TFLite inference error
  Future<List<double>> getEmbeddingFromCameraImage(
      CameraImage cameraImage, int sensorOrientation) async {
    final inputImage =
        _cameraImageToInputImage(cameraImage, sensorOrientation);

    final faces = await _detectFaces(inputImage);
    _validateFaceCount(faces);

    final face = faces.first;
    final rgbBytes = await _cropAndResizeFace(cameraImage, face);
    return _embeddingService.generateEmbedding(rgbBytes);
  }

  /// Processes a [Uint8List] (JPEG/PNG bytes) and returns a 192-D embedding.
  Future<List<double>> getEmbeddingFromImageBytes(Uint8List imageBytes) async {

  // 1️⃣ Decode image for cropping
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) {
    throw const FaceDetectionFailure('Could not decode image.');
  }

  // 2️⃣ Save image temporarily
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_face.jpg');
  await tempFile.writeAsBytes(imageBytes);

  // 3️⃣ Tell ML Kit to read the FILE (not raw bytes)
  final inputImage = InputImage.fromFilePath(tempFile.path);

  // 4️⃣ Detect faces
  final faces = await _faceDetector.processImage(inputImage);

  if (faces.isEmpty) {
    throw const NoFaceDetectedFailure();
  }
  if (faces.length > 1) {
    throw const MultipleFacesDetectedFailure();
  }

  final face = faces.first;

  // 5️⃣ Crop and generate embedding
  final cropped = _cropAndResizeDecoded(decoded, face);

  return _embeddingService.generateEmbedding(cropped);
  }

  // ── Camera image conversion ───────────────────────────────────────────

  /// Converts a [CameraImage] from the camera plugin into a
  /// [InputImage] consumable by ML Kit.
  InputImage _cameraImageToInputImage(
    CameraImage image, int sensorOrientation) {

  final rotation =
      InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;

  if (image.format.group != ImageFormatGroup.yuv420) {
    throw const FaceDetectionFailure(
        'Only YUV420 format is supported on Android.');
  }

  // Concatenate all planes into one buffer
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: ui.Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  // ── Face detection ────────────────────────────────────────────────────

  Future<List<Face>> _detectFaces(InputImage inputImage) async {
    try {
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      throw FaceDetectionFailure('ML Kit error: $e');
    }
  }

  void _validateFaceCount(List<Face> faces) {
    if (faces.isEmpty) throw const NoFaceDetectedFailure();
    if (faces.length > 1) throw const MultipleFacesDetectedFailure();
  }

  // ── Face crop & resize (camera image path) ────────────────────────────

  /// Crops the detected face from the camera's YUV/BGRA image and resizes to
  /// 112 × 112 returning raw RGB bytes.
  Future<Uint8List> _cropAndResizeFace(
      CameraImage cameraImage, Face face) async {
    // Convert CameraImage to img.Image for manipulation.
    final decoded = await compute(_convertCameraImage, cameraImage);
    if (decoded == null) {
      throw const FaceDetectionFailure(
          'Could not convert camera image for cropping.');
    }
    return _cropAndResizeDecoded(decoded, face);
  }

  /// Crops the [face] bounding box from [decoded] and resizes to 112×112 RGB.
  Uint8List _cropAndResizeDecoded(img.Image decoded, Face face) {
    final rect = face.boundingBox;

    // Clamp bounding box to image dimensions.
    final x = rect.left.toInt().clamp(0, decoded.width - 1);
    final y = rect.top.toInt().clamp(0, decoded.height - 1);
    final w =
        rect.width.toInt().clamp(1, decoded.width - x);
    final h =
        rect.height.toInt().clamp(1, decoded.height - y);

    if (w < AppConstants.minFaceSize || h < AppConstants.minFaceSize) {
      throw const NoFaceDetectedFailure(
          'Detected face is too small. Please move closer to the camera.');
    }

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final resized = img.copyResize(
      cropped,
      width: AppConstants.modelInputSize,
      height: AppConstants.modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    // Extract raw RGB bytes in row-major order.
    final bytes = Uint8List(
        AppConstants.modelInputSize * AppConstants.modelInputSize * 3);
    int offset = 0;
    for (int row = 0; row < AppConstants.modelInputSize; row++) {
      for (int col = 0; col < AppConstants.modelInputSize; col++) {
        final pixel = resized.getPixel(col, row);
        bytes[offset++] = pixel.r.toInt();
        bytes[offset++] = pixel.g.toInt();
        bytes[offset++] = pixel.b.toInt();
      }
    }
    return bytes;
  }

  // ── Dispose ───────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

// ── Isolate helper ────────────────────────────────────────────────────────

/// Converts a [CameraImage] to an [img.Image] in a background isolate.
/// Supports both YUV420 (Android) and BGRA8888 (iOS) formats.
img.Image? _convertCameraImage(CameraImage cameraImage) {
  try {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(cameraImage);
    }
    return null;
  } catch (_) {
    return null;
  }
}

img.Image _convertYUV420(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final output = img.Image(width: width, height: height);

  for (int h = 0; h < height; h++) {
    for (int w = 0; w < width; w++) {
      final yIndex = h * yPlane.bytesPerRow + w;
      final uvIndex =
          (h ~/ 2) * uvRowStride + (w ~/ 2) * uvPixelStride;

      final yVal = yBytes[yIndex];
      final uVal = uBytes[uvIndex];
      final vVal = vBytes[uvIndex];

      final r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
          .round()
          .clamp(0, 255);
      final b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

      output.setPixelRgb(w, h, r, g, b);
    }
  }
  return output;
}

img.Image _convertBGRA8888(CameraImage image) {
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}
