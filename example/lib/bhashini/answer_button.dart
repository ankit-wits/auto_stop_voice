import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/public/tau.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';
import 'package:flutter_voice_processor_example/bhashini/bhashini_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AnswerButton extends StatefulWidget {
  const AnswerButton({
    Key? key,
    required this.answer,
    required this.languageCode,
    required this.onResponseReceived, // Add this line
  }) : super(key: key);
  final String answer;
  final String languageCode;
  final Function(String) onResponseReceived; // Add this line

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton> {
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

  Color btnColor = Colors.blue;

  toggleColor() {
    if (btnColor == Colors.blue) {
      btnColor = Colors.red;
    } else {
      btnColor = Colors.blue;
    }
  }

  Future<void> _stopProcessing() async {
    setState(() {
      _isButtonDisabled = true;
      toggleColor();
    });

    try {
      await _voiceProcessor?.stop();

      // Stop recording with flutter_sound
      // Stop recording with flutter_sound
      await record.stop().then((value) async {
        final file = File(value ?? "");
        final bytes = await file.readAsBytes();
        final response = await sendRequest(
          base64Audio: base64Encode(bytes),
          sourceLanguage: widget.languageCode,
        );
        widget.onResponseReceived(
            response); // Call the callback with the response
      });
      // await _playAudio();
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

    setState(
      () {
        _smoothedVolumeValue =
            _volumeHistory.reduce((a, b) => a + b) / _volumeHistory.length;
      },
    );

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _isButtonDisabled || _errorMessage != null ? null : _toggleProcessing();
        toggleColor();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: btnColor,
        ),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${utf8.decode(widget.answer.runes.toList())}  ',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.mic,
                color: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}
