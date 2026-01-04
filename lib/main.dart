import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';           // Correct import
import 'package:ffmpeg_kit_flutter_new/return_code.dart';        // Correct import
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinema Audio V2',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const CinemaAudioScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CinemaAudioScreen extends StatefulWidget {
  const CinemaAudioScreen({super.key});

  @override
  State<CinemaAudioScreen> createState() => _CinemaAudioScreenState();
}

class _CinemaAudioScreenState extends State<CinemaAudioScreen> {
  File? _selectedAudio;
  String _selectedAction = 'Convert to WAV';
  String _status = 'Select an audio file for cinematic enhancement.';
  bool _isProcessing = false;

  final List<String> _actions = [
    'Convert to WAV',
    'Apply Cinema Bass Boost',
  ];

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudio = File(result.files.single.path!);
        _status = 'Selected: ${_selectedAudio!.path.split('/').last}';
      });
    }
  }

  Future<void> _processAudio() async {
    if (_selectedAudio == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing audio... Please wait.';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String outputPath;
      String command;

      if (_selectedAction == 'Convert to WAV') {
        outputPath = '${directory.path}/cinema_converted_$timestamp.wav';
        command = '-i "${_selectedAudio!.path}" -ar 44100 -ac 2 "$outputPath"';
      } else {
        // Cinema Bass Boost: Strong low-end enhancement
        outputPath = '${directory.path}/cinema_boosted_$timestamp.mp3';
        command =
            '-i "${_selectedAudio!.path}" -af "equalizer=f=80:t=q:w=1.5:g=8,equalizer=f=200:t=q:w=1:g=4" "$outputPath"';
      }

      final session = await FFmpegKit.execute(command);

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _status = 'Success!\nSaved to:\n$outputPath';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cinematic audio processed successfully! 🎬🔊'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      } else {
        setState(() {
          _status = 'Processing failed. Check console logs.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Audio V2'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Enhance your audio for a true cinema experience',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _pickAudioFile,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Pick Audio File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),

            if (_selectedAudio != null) ...[
              DropdownButton<String>(
                value: _selectedAction,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(color: Colors.deepPurple, fontSize: 16),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAction = newValue!;
                  });
                },
                items: _actions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processAudio,
                icon: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.movie),
                label: Text(_isProcessing ? 'Processing...' : 'Process Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
