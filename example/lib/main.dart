//
// Copyright 2020-2023 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:flutter_voice_processor_example/vu_meter_painter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final int frameLength = 512;
  final int sampleRate = 16000;
  final int volumeHistoryCapacity = 5;
  final double dbOffset = 50.0;

  final List<double> _volumeHistory = [];
  double _smoothedVolumeValue = 0.0;
  bool _isButtonDisabled = false;
  bool _isProcessing = false;
  String? _errorMessage;
  VoiceProcessor? _voiceProcessor;
  final record = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _initVoiceProcessor();
    _initRecorder();
  }

  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }

  void _initRecorder() async {}

  void _initVoiceProcessor() async {
    _voiceProcessor = VoiceProcessor.instance;
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isButtonDisabled = true;
    });

    _voiceProcessor?.addFrameListener(_onFrame);
    _voiceProcessor?.addErrorListener(_onError);
    try {
      if (await _voiceProcessor?.hasRecordAudioPermission() ?? false) {
        await _voiceProcessor?.start(frameLength, sampleRate);
        bool? isRecording = await _voiceProcessor?.isRecording();
        setState(() {
          _isProcessing = isRecording!;
        });
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final file = File('$path/file.wav');
        // Start recording with flutter_sound
        await record.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: sampleRate,
            bitRate: 96000,
            numChannels: 1,
          ),
          path: file.path,
        );
      } else {
        setState(() {
          _errorMessage = "Recording permission not granted";
        });
      }
    } on PlatformException catch (ex) {
      setState(() {
        _errorMessage = "Failed to start recorder: " + ex.toString();
      });
    } finally {
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  Future<void> _stopProcessing() async {
    setState(() {
      _isButtonDisabled = true;
    });

    try {
      await _voiceProcessor?.stop();
      // Stop recording with flutter_sound
      await record.stop();
    } on PlatformException catch (ex) {
      setState(() {
        _errorMessage = "Failed to stop recorder: " + ex.toString();
      });
    } finally {
      bool? isRecording = await _voiceProcessor?.isRecording();
      setState(() {
        _isButtonDisabled = false;
        _isProcessing = isRecording!;
      });
    }
  }

  void _toggleProcessing() async {
    if (_isProcessing) {
      await _stopProcessing();
    } else {
      await _startProcessing();
    }
  }

  double _calculateVolumeLevel(List<int> frame) {
    double rms = 0.0;
    for (int sample in frame) {
      rms += pow(sample, 2);
    }
    rms = sqrt(rms / frame.length);

    double dbfs = 20 * log(rms / 32767.0) / log(10);
    double normalizedValue = (dbfs + dbOffset) / dbOffset;
    return normalizedValue.clamp(0.0, 1.0);
  }

// Add a timer variable at the class level
  Timer? _volumeCheckTimer;

  void _onFrame(List<int> frame) {
    double volumeLevel = _calculateVolumeLevel(frame);
    print(volumeLevel);
    if (_volumeHistory.length == volumeHistoryCapacity) {
      _volumeHistory.removeAt(0);
    }
    _volumeHistory.add(volumeLevel);

    setState(() {
      _smoothedVolumeValue =
          _volumeHistory.reduce((a, b) => a + b) / _volumeHistory.length;
    });

    // Check if volume is below the threshold
    if (volumeLevel < 0.2) {
      // If the timer is not running, start it
      _volumeCheckTimer ??= Timer(Duration(seconds: 2), () {
        // If the timer completes, stop the recording
        _stopProcessing();
      });
    } else {
      // If the volume is above the threshold, cancel the timer
      _volumeCheckTimer?.cancel();
      _volumeCheckTimer = null;
    }
  }

  void _onError(VoiceProcessorException error) {
    setState(() {
      _errorMessage = error.message;
    });
  }

  Future<void> _playAudio() async {
    try {
      // Assuming you're saving the file in the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final file = File('$path/file.wav');

      if (await file.exists()) {
        final _recorder = FlutterSound();
        await _recorder.thePlayer.openPlayer();
        await _recorder.thePlayer.startPlayer(fromURI: file.path);
      } else {
        setState(() {
          _errorMessage = "No audio file found to play.";
        });
      }
    } on PlatformException catch (ex) {
      setState(() {
        _errorMessage = "Failed to play audio: " + ex.toString();
      });
    }
  }

  Color picoBlue = Color.fromRGBO(55, 125, 255, 1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Processor'),
        ),
        body: Column(children: [
          buildVuMeter(context),
          buildStartButton(context),
          buildPlayButton(context), // Add this line

          buildErrorMessage(context)
        ]),
      ),
    );
  }

  buildPlayButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing || _errorMessage != null ? null : _playAudio,
      child: Text("Play", style: TextStyle(fontSize: 20)),
    );
  }

  buildVuMeter(BuildContext context) {
    return Expanded(
        flex: 2,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Container(
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                    painter: VuMeterPainter(_smoothedVolumeValue, picoBlue),
                    size: Size(constraints.maxWidth * 0.95, 50)));
          },
        ));
  }

  buildStartButton(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: picoBlue,
        shape: CircleBorder(),
        textStyle: TextStyle(color: Colors.white));

    return Expanded(
      flex: 2,
      child: Container(
          child: SizedBox(
              width: 150,
              height: 150,
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: _isButtonDisabled || _errorMessage != null
                    ? null
                    : _toggleProcessing,
                child: Text(_isProcessing ? "Stop" : "Start",
                    style: TextStyle(fontSize: 30)),
              ))),
    );
  }

  buildErrorMessage(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(30),
            decoration: _errorMessage == null
                ? null
                : BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(5)),
            child: _errorMessage == null
                ? null
                : Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )));
  }
}
