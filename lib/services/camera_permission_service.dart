import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class CameraPermissionService {
  Future<bool> isCameraPermissionGranted();
}

class DefaultCameraPermissionService implements CameraPermissionService {
  const DefaultCameraPermissionService();

  @override
  Future<bool> isCameraPermissionGranted() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.camera.status;
      return status.isGranted;
    }
    return true;
  }
}

class FakeCameraPermissionService implements CameraPermissionService {
  const FakeCameraPermissionService({this.granted = false});

  final bool granted;

  @override
  Future<bool> isCameraPermissionGranted() async => granted;
}
