import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema Audio V2',
      theme: ThemeData(primarySwatch: Colors.deepPurple),  // Cinematic purple theme
      home: const CinemaScreen(),
    );
  }
}

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  File? _selectedAudio;
  String _action = 'Convert to WAV';
  String _status = 'Select an audio file for cinematic enhancement.';
  bool _isProcessing = false;

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudio = File(result.files.single.path!);
        _status = 'Audio selected: ${_selectedAudio!.path.split('/').last}';
      });
    }
  }

  Future<void> _processAudio() async {
    if (_selectedAudio == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'Enhancing for cinema...';
    });

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String outputPath;
    String command;

    if (_action == 'Convert to WAV') {
      outputPath = '${directory.path}/cinema_converted_$timestamp.wav';
      command = '-i ${_selectedAudio!.path} -ar 44100 -ac 2 $outputPath';  // 44.1kHz stereo WAV
    } else {
      outputPath = '${directory.path}/cinema_boosted_$timestamp.mp3';
      command = '-i ${_selectedAudio!.path} -af "equalizer=f=80:t=q:w=1:g=8,equalizer=f=200:t=q:w=1:g=4" $outputPath';  // Cinematic bass: +8dB@80Hz, +4dB@200Hz
    }

    final session = await FFmpegKit.execute(command);

    // Optional: Print logs for debugging
    final logs = await session.getLogs();
    for (final log in logs) {
      print(log.getMessage());  // View in console
    }

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      setState(() {
        _status = 'Success! Saved to: $outputPath';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cinematic audio ready! Check documents folder.'))
      );
    } else {
      setState(() {
        _status = 'Failed: See console logs.';
      });
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Audio V2'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Pick Audio File'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            if (_selectedAudio != null) ...[
              DropdownButton<String>(
                value: _action,
                onChanged: (String? newValue) {
                  setState(() {
                    _action = newValue!;
                  });
                },
                items: <String>['Convert to WAV', 'Apply Cinema Bass Boost']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processAudio,
                icon: const Icon(Icons.movie),
                label: Text(_isProcessing ? 'Enhancing...' : 'Process for Cinema'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
