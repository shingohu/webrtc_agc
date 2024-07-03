import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webrtc_agc/webrtc_agc.dart';
import 'package:webrtc_ns/webrtc_ns.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WebRtc AGC'),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                    onPressed: () {
                      WebrtcAgc.init(16000);
                      WebrtcNS.init(16000);
                    },
                    child: Text("初始化")),
                TextButton(
                    onPressed: () async {
                      ByteData byteData =
                          await rootBundle.load("assets/test.pcm");
                      Uint8List bytes = byteData.buffer.asUint8List();
                      bytes = WebrtcNS.process(
                          WebrtcAgc.process(WebrtcNS.process(bytes)));
                      File? file = await _createCacheAudioFile("test");
                      if (file != null) {
                        file.writeAsBytes(bytes);
                        print(file.path);
                      }
                    },
                    child: Text("自动增益处理")),
                TextButton(
                    onPressed: () {
                      WebrtcAgc.destroy();
                      WebrtcNS.destroy();
                    },
                    child: Text("销毁")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///创建PCM缓存
  Future<File?> _createCacheAudioFile(String prefix) async {
    DateTime time = DateTime.now();
    String fileName =
        prefix + "_" + time.millisecondsSinceEpoch.toString() + ".pcm";
    String? path = (await getApplicationDocumentsDirectory()).path + '/audio';

    File file = File(path + "/" + fileName);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}
