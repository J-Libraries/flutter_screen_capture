// import 'dart:async' show Timer;
// import 'dart:io' show File, Directory, FileSystemEntity, Platform;
// import 'dart:typed_data' show ByteData;
// import 'dart:ui' show ImageByteFormat;
//
// import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart' show FFmpegKit;
// import 'package:ffmpeg_kit_flutter_new/return_code.dart' show ReturnCode;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart' show GlobalKey;
// import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
// import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
// import 'package:permission_handler/permission_handler.dart' show Permission, PermissionActions, PermissionStatusGetters;
// import 'package:share_plus/share_plus.dart' show XFile, SharePlus, ShareParams;
// import 'package:path/path.dart' as p;
// import 'dart:developer' as developer;
//
// typedef SetStateCallback = void Function();
// typedef ProcessingStatusCallback = void Function(bool isProcessing);
//
// class ScreenRecorderController {
//   int _frameCount = 0;
//   bool _isRecording = false;
//   late Timer _recordingTimer;
//   bool isFrameCaptured = false;
//   ReturnCode? returnCode;
//
//   final GlobalKey repaintBoundaryKey = GlobalKey();
//   final void Function(int)? updateFrameCount;
//
//   bool get isRecording => _isRecording;
//   final String videoExportPath;
//   final int fps;
//   final bool shareVideo;
//   final String shareMessage;
//   final bool showLogs;
//
//   ScreenRecorderController({required this.videoExportPath, this.fps = 4, this.shareVideo = false, this.shareMessage = '', this.updateFrameCount, this.showLogs = false});
//
//   void startRecording({setState}) async {
//     if(Platform.isAndroid)
//       {
//         final status = await Permission.videos.request();
//         if (!status.isGranted) return;
//       }
//     else if(Platform.isIOS)
//       {
//         final status = await Permission.photos.request();
//         if (!status.isGranted) return;
//       }
//
//
//     _isRecording = true;
//     final intervalDuration = 1000 ~/ fps;
//     if(setState != null) {
//       setState();
//     }
//
//     final dir = await getTemporaryDirectory();
//     _recordingTimer = Timer.periodic( Duration(milliseconds: intervalDuration), (_) async {
//       if (!_isRecording) return;
//
//       try {
//         final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
//         if (boundary is! RenderRepaintBoundary) {
//           return;
//         }
//         var image = await boundary.toImage(pixelRatio: 2.0);
//         ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
//         if (byteData == null) return;
//
//         if(_isRecording)
//           {
//             final filePath = '${dir.path}/frame_${_frameCount.toString().padLeft(4, '0')}.png';
//             final file = File(filePath);
//             await file.writeAsBytes(byteData.buffer.asUint8List());
//             if(!isFrameCaptured) {
//               isFrameCaptured = true;
//             }
//             if(updateFrameCount != null) {
//               updateFrameCount!(_frameCount);
//             }
//             if(showLogs) {
//
//               developer.log('✅ Frame saved: $filePath - ${await file.length()} bytes');
//             }
//           }
//         _frameCount++;
//       } catch (e) {
//         developer.log('Error capturing frame: $e');
//       }
//
//     });
//   }
//   Future<void> stopRecording({ setState, ProcessingStatusCallback? isProcessing, }) async {
//     _isRecording = false;
//     isProcessing?.call(true);
//     if(setState != null) {
//       setState();
//     }
//     _recordingTimer.cancel();
//
//     if (!isFrameCaptured) return;
//
//     final dir = await getTemporaryDirectory();
//     final cmd = "-framerate 10 -i ${dir.path}/frame_%04d.png "
//         "-vf scale=trunc(iw/2)*2:trunc(ih/2)*2 "
//         "-c:v libx264 -pix_fmt yuv420p $videoExportPath";
//
//     final session = await FFmpegKit.execute(cmd);
//     returnCode = await session.getReturnCode();
//     // final output = await session.getOutput();
//     // final logs = await session.getAllLogs();
//     // developer.log("🎬 FFmpeg output:\n$output");
//     // developer.log("📋 FFmpeg logs:");
//     // logs.forEach((log) => print(log.getMessage()));
//
//     if (ReturnCode.isSuccess(returnCode)) {
//       developer.log("✅ Video created at $videoExportPath");
//     } else {
//       developer.log("❌ FFmpeg failed with return code: $returnCode");
//     }
//
//     final directory = await getTemporaryDirectory();
//     _deleteAllImagesInDirectory(directory.path);
//
//     _frameCount = 0;
//     isFrameCaptured = false;
//
//     if(setState != null) {
//       setState();
//     }
//     developer.log("🎥 Video saved to: $videoExportPath");
//     isProcessing?.call(false);
//   }
//   Future<void> cancelRecording({setState})async{
//     _isRecording = false;
//     if(setState != null) {
//       setState();
//     }
//     _recordingTimer.cancel();
//
//     if (!isFrameCaptured) return;
//     final directory = await getTemporaryDirectory();
//     _deleteAllImagesInDirectory(directory.path);
//
//     _frameCount = 0;
//     isFrameCaptured = false;
//
//     if(setState != null) {
//       setState();
//     }
//   }
//   Future<void> share({setState}) async{
//     if (ReturnCode.isSuccess(returnCode)) {
//       developer.log("✅ Video created at $videoExportPath");
//       if(shareVideo) {
//         ShareParams params = ShareParams(
//           files: [XFile(videoExportPath)],
//           text: shareMessage,
//         );
//         await SharePlus.instance.share(params);
//       }
//     } else {
//
//       developer.log("❌ FFmpeg failed with return code: $returnCode");
//     }
//
//     if(setState != null) {
//       setState();
//     }
//   }
//   Future<void> _deleteAllImagesInDirectory(String directoryPath) async{
//     final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic'];
//     try{
//       final dir = Directory(directoryPath);
//
//       if (await dir.exists()) {
//         final List<FileSystemEntity> entities = await dir.list(recursive: false).toList();
//
//         int deleteCount = 0;
//         for (FileSystemEntity entity in entities) {
//           if (entity is File) {
//             String fileExtension = p.extension(entity.path).toLowerCase();
//             if (imageExtensions.contains(fileExtension)) {
//               try {
//                 await entity.delete();
//                 deleteCount++;
//                 print('Deleted image: ${entity.path}');
//               } catch (e) {
//                 print('Error deleting file ${entity.path}: $e');
//                 // Optionally, rethrow or collect errors
//               }
//             }
//           }
//         }
//         print('Deletion complete. $deleteCount image(s) deleted from $directoryPath.');
//       }
//       else {
//         print('Directory not found: $directoryPath');
//       }
//     } catch (e) {
//       print('Error accessing directory $directoryPath or listing files: $e');
//       // Handle specific exceptions if needed
//     }
//   }
// }

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:developer' as developer;
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

typedef SetStateCallback = void Function();
typedef ProcessingStatusCallback = void Function(bool isProcessing);

class ScreenRecorderController {
  int _frameCount = 0;
  bool _isRecording = false;
  Timer? _recordingTimer;

  String? _pipe;        // Path returned by ffmpeg-kit
  IOSink? _pipeSink;    // Writable sink for frames

  ReturnCode? returnCode;

  final GlobalKey repaintBoundaryKey = GlobalKey();
  final void Function(int)? updateFrameCount;

  bool get isRecording => _isRecording;
  final String videoExportPath;
  final int fps;
  final bool shareVideo;
  final String shareMessage;
  final bool showLogs;

  int _width = 0;
  int _height = 0;

  ScreenRecorderController({
    required this.videoExportPath,
    this.fps = 10,
    this.shareVideo = false,
    this.shareMessage = '',
    this.updateFrameCount,
    this.showLogs = false,
  });

  /// Start recording: sets up ffmpeg pipe and begins pushing frames.
  Future<void> startRecording({SetStateCallback? setState}) async {
    if (_isRecording) return;

    _isRecording = true;
    _frameCount = 0;
    if (setState != null) setState();

    // Wait until first frame is fully painted
    await WidgetsBinding.instance.endOfFrame;

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      developer.log('❌ No RenderRepaintBoundary found');
      return;
    }

    final image = await boundary.toImage(pixelRatio: 2.0);
    _width = image.width;
    _height = image.height;

    // Create ffmpeg pipe
    _pipe = await FFmpegKitConfig.registerNewFFmpegPipe();
    _pipeSink = File(_pipe!).openWrite();

    // ffmpeg command
    final command = [
      '-y',
      '-f', 'rawvideo',
      '-pix_fmt', 'rgba',
      '-s', '${_width}x$_height',
      '-r', fps.toString(),
      '-i', _pipe!,
      '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p',
      videoExportPath,
    ].join(' ');

    // Run ffmpeg in background
    FFmpegKit.executeAsync(command, (session) async {
      returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        developer.log("✅ Video created at $videoExportPath");
      } else {
        developer.log("❌ FFmpeg failed with code: $returnCode");
      }
    });

    // Capture frames periodically
    final interval = Duration(milliseconds: 1000 ~/ fps);
    _recordingTimer = Timer.periodic(interval, (_) => _captureFrame());

    developer.log("🎥 Recording started with size: $_width x $_height");
  }

  /// Stop recording: closes ffmpeg pipe and finalizes the video.
  Future<void> stopRecording({
    SetStateCallback? setState,
    ProcessingStatusCallback? isProcessing,
  }) async {
    if (!_isRecording) return;

    _isRecording = false;
    if (setState != null) setState();
    isProcessing?.call(true);

    _recordingTimer?.cancel();

    await _pipeSink?.flush();
    await _pipeSink?.close();

    _pipe = null;
    _pipeSink = null;

    _frameCount = 0;
    isProcessing?.call(false);

    developer.log("🎬 Recording stopped");
  }

  /// Cancel without saving
  Future<void> cancelRecording({SetStateCallback? setState}) async {
    if (!_isRecording) return;

    _isRecording = false;
    _recordingTimer?.cancel();

    await _pipeSink?.close();
    _pipe = null;
    _pipeSink = null;

    _frameCount = 0;
    if (setState != null) setState();

    developer.log("🛑 Recording canceled");
  }

  /// Internal: capture a single frame and push to ffmpeg pipe
  Future<void> _captureFrame() async {
    if (!_isRecording || _pipeSink == null) return;

    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      _pipeSink!.add(byteData.buffer.asUint8List());
      _frameCount++;

      if (updateFrameCount != null) updateFrameCount!(_frameCount);
      if (showLogs) developer.log("✅ Frame $_frameCount pushed");
    } catch (e) {
      developer.log("⚠️ Error capturing frame: $e");
    }
  }
}
