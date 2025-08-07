import 'dart:async' show Timer;
import 'dart:io' show File, Directory, FileSystemEntity, Platform;
import 'dart:typed_data' show ByteData;
import 'dart:ui' show ImageByteFormat;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart' show FFmpegKit;
import 'package:ffmpeg_kit_flutter_new/return_code.dart' show ReturnCode;
import 'package:flutter/material.dart' show GlobalKey, debugPrint;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:permission_handler/permission_handler.dart' show Permission, PermissionActions, PermissionStatusGetters;
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:path/path.dart' as p;

class ScreenRecorderController {
  int _frameCount = 0;
  bool _isRecording = false;
  late Timer _recordingTimer;
  bool isFrameCaptured = false;

  final GlobalKey repaintBoundaryKey = GlobalKey();
  final void Function(int)? updateFrameCount;

  bool get isRecording => _isRecording;
  final String videoExportPath;
  final int fps;
  final bool shareVideo;
  final String shareMessage;
  ScreenRecorderController({required this.videoExportPath, this.fps = 4, this.shareVideo = false, this.shareMessage = '', this.updateFrameCount});

  void startRecording({setState}) async {
    if(Platform.isAndroid)
      {
        final status = await Permission.videos.request();
        if (!status.isGranted) return;
      }
    else if(Platform.isIOS)
      {
        final status = await Permission.photos.request();
        if (!status.isGranted) return;
      }


    _isRecording = true;
    final intervalDuration = 1000 ~/ fps;
    if(setState != null) {
      setState();
    }

    final dir = await getTemporaryDirectory();
    _recordingTimer = Timer.periodic( Duration(milliseconds: intervalDuration), (_) async {
      if (!_isRecording) return;

      try {
        final boundary = repaintBoundaryKey.currentContext?.findRenderObject();
        if (boundary is! RenderRepaintBoundary) {
          return;
        }
        var image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
        if (byteData == null) return;

        if(_isRecording)
          {
            final filePath = '${dir.path}/frame_${_frameCount.toString().padLeft(4, '0')}.png';
            final file = File(filePath);
            await file.writeAsBytes(byteData.buffer.asUint8List());
            if(!isFrameCaptured) {
              isFrameCaptured = true;
            }
            if(updateFrameCount != null) {
              updateFrameCount!(_frameCount);
            }
            debugPrint('✅ Frame saved: $filePath - ${await file.length()} bytes');
          }
        _frameCount++;
      } catch (e) {
        debugPrint('Error capturing frame: $e');
      }

    });
  }
  Future<void> stopRecordingAndExport({setState}) async {
    _isRecording = false;
    if(setState != null) {
      setState();
    }
    _recordingTimer.cancel();

    if (!isFrameCaptured) return;

    final dir = await getTemporaryDirectory();
    final cmd = "-framerate 10 -i ${dir.path}/frame_%04d.png "
        "-vf scale=trunc(iw/2)*2:trunc(ih/2)*2 "
        "-c:v libx264 -pix_fmt yuv420p $videoExportPath";

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();
    // final output = await session.getOutput();
    // final logs = await session.getAllLogs();
    // debugPrint("🎬 FFmpeg output:\n$output");
    // debugPrint("📋 FFmpeg logs:");
    // logs.forEach((log) => print(log.getMessage()));

    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint("✅ Video created at $videoExportPath");
    } else {
      debugPrint("❌ FFmpeg failed with return code: $returnCode");
    }

    final directory = await getTemporaryDirectory();
    deleteAllImagesInDirectory(directory.path);

    _frameCount = 0;
    isFrameCaptured = false;

    if(setState != null) {
      setState();
    }
    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint("✅ Video created at $videoExportPath");
      if(shareVideo) {
        await Share.shareXFiles(
        [XFile(videoExportPath)],
        text: shareMessage,
      );
      }
    } else {
      debugPrint("❌ FFmpeg failed with return code: $returnCode");
    }

    if(setState != null) {
      setState();
    }
    debugPrint("🎥 Video saved to: $videoExportPath");
  }
  Future<void> deleteAllImagesInDirectory(String directoryPath) async{
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic'];
    try{
      final dir = Directory(directoryPath);

      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list(recursive: false).toList();

        int deleteCount = 0;
        for (FileSystemEntity entity in entities) {
          if (entity is File) {
            String fileExtension = p.extension(entity.path).toLowerCase();
            if (imageExtensions.contains(fileExtension)) {
              try {
                await entity.delete();
                deleteCount++;
                print('Deleted image: ${entity.path}');
              } catch (e) {
                print('Error deleting file ${entity.path}: $e');
                // Optionally, rethrow or collect errors
              }
            }
          }
        }
        print('Deletion complete. $deleteCount image(s) deleted from $directoryPath.');
      }
      else {
        print('Directory not found: $directoryPath');
      }
    } catch (e) {
      print('Error accessing directory $directoryPath or listing files: $e');
      // Handle specific exceptions if needed
    }
  }
}
