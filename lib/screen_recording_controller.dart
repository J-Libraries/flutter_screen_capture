import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:typed_data' show ByteData;
import 'dart:ui' show ImageByteFormat;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart' show FFmpegKit;
import 'package:ffmpeg_kit_flutter_new/return_code.dart' show ReturnCode;
import 'package:flutter/material.dart' show GlobalKey, debugPrint;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:permission_handler/permission_handler.dart' show Permission, PermissionActions, PermissionStatusGetters;
import 'package:share_plus/share_plus.dart' show Share, XFile;

class ScreenRecorderController {
  int _frameCount = 0;
  bool _isRecording = false;
  late Timer _recordingTimer;
  final List<String> _capturedFramesPath = [];

  final GlobalKey repaintBoundaryKey = GlobalKey();

  bool get isRecording => _isRecording;
  final String videoExportPath;
  final int fps;
  final bool shareVideo;
  final String shareMessage;
  ScreenRecorderController({required this.videoExportPath, this.fps = 4, this.shareVideo = false, this.shareMessage = ''});

  void startRecording({setState}) async {
    final status = await Permission.videos.request();
    if (!status.isGranted) return;

    _isRecording = true;
    const frameInterval = Duration(milliseconds: 40);
    if(setState != null) {
      setState();
    }

    _recordingTimer = Timer.periodic(frameInterval, (_) async {
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
            final dir = await getTemporaryDirectory();
            final filePath = '${dir.path}/frame_${_frameCount.toString().padLeft(4, '0')}.png';
            final file = File(filePath);
            await file.writeAsBytes(byteData.buffer.asUint8List());
            _capturedFramesPath.add(filePath);
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

    if (_capturedFramesPath.isEmpty) return;

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

    for (var frame in _capturedFramesPath) {
      File(frame).deleteSync(recursive: true);
    }
    _capturedFramesPath.clear();
    _frameCount = 0;

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
}