Here’s a full `README.md` you can use for your Flutter screen recording plugin:

---

````markdown
# screen_recorder

A Flutter plugin for recording only your app's screen (not the entire device screen) as a video, with support for red border indication and post-recording sharing to social/media apps.

---

## ✨ Features

- 📹 Record only your app’s screen
- 🔴 Red border indicator while recording
- 💾 Automatically saves video in `.mp4` format
- 📤 Share the recorded video to other apps (social/media/messaging)
- 🧩 Built-in example to demonstrate usage

---

## 🛠 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  screen_recorder:
````

Then run:

```bash
flutter pub get
```

---

## 🧪 Example

A full working demo is available in the [example/](example) folder.

```dart
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

```

---

## 📦 How It Works

* Captures each frame of your app using `RepaintBoundary`
* Combines frames into a video using `ffmpeg_kit_flutter`
* Adds a red border to indicate recording
* Allows direct sharing after recording ends

---

## 📱 Android Setup

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

Also, ensure you have the `ffmpeg_kit_flutter` dependency:

```yaml
dependencies:
  ffmpeg_kit_flutter: ^4.5.1
```

---

## 📤 Share Integration

The plugin uses platform sharing to immediately open the share sheet when recording finishes. You can customize this callback to suit your app's flow.

---

## 🚧 Limitations

* Only supports Flutter widget layer recording, not full system screen capture
* Best suited for UI tutorials, gameplay, or presentation recording
* May not capture platform views (Google Maps, WebViews, etc.)

---

## 🧾 License

MIT License © 2025

---

## 💬 Maintainer

Made with ❤️ by [Nishant Mishra](https://github.com/J-Libraries)

