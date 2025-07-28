import 'package:flutter/material.dart';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';
import 'package:flutter_screen_capture/screen_recording_controller.dart' show ScreenRecorderController;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:uuid/uuid.dart' show Uuid;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: RecorderExample());
  }
}

class RecorderExample extends StatefulWidget {
  const RecorderExample({super.key});

  @override
  State<RecorderExample> createState() => _RecorderExampleState();
}

class _RecorderExampleState extends State<RecorderExample> {
  bool isPathLoaded = true;
  String videoExportPath = '';
  late ScreenRecorderController recorderController;

  loadVideoExportPathAndInitController()async{
    final tempDirectory = await getTemporaryDirectory();
    videoExportPath = '${tempDirectory.path}/${Uuid().v4()}.mp4';
    recorderController = ScreenRecorderController(videoExportPath: videoExportPath, fps:  8, shareMessage: "Hey this is the recorded video", shareVideo: true);
    setState(() {
      isPathLoaded = true;
    });
  }
  @override
  void initState() {
    loadVideoExportPathAndInitController();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Recorder Demo')),
      body: isPathLoaded ?
      Container(
        decoration: recorderController.isRecording ? BoxDecoration(border: Border.all(color: Colors.red, width: 4),) : null,
        child: Column(
          children: [
            Expanded(
              child: FlutterScreenCapture(
                controller: recorderController,
                child: Center(
                  child: Text(
                    "Recording Test!",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    recorderController.startRecording(setState: () =>  setState(() {}));
                  },
                  child: const Text("Start"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await recorderController.stopRecordingAndExport(setState: () => setState(() {}));
                  },
                  child: const Text("Stop & Share"),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ) : Center(child: CircularProgressIndicator()),
    );
  }
}
