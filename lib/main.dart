
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CinemaAudioApp());
}

class CinemaAudioApp extends StatelessWidget {
  const CinemaAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cinema Audio v2',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(backgroundColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedFile;
  String _status = 'No file selected';
  bool _isProcessing = false;

  // ✅ FFmpeg conversion & bass boost logic — inline
  Future<File?> _convertAndBoost(File inputFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputFileName = 'cinematic_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final outputFile = File('${tempDir.path}/$outputFileName');

    // FFmpeg command: bass boost + format to MP3 (192kbps, stereo, 44.1kHz)
    final arguments = [
      '-i', inputFile.path,
      '-af', 'bass=g=12',        // +12dB bass boost (cinematic effect)
      '-ar', '44100',            // sample rate
      '-ac', '2',                // stereo
      '-b:a', '192k',            // bitrate
      '-y',                      // overwrite output
      outputFile.path,
    ];

    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return outputFile;
    } else {
      final error = await session.getCommandErrorMessage() ?? 'Unknown error';
      throw Exception('FFmpeg failed: $error');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'flac', 'ogg'],
    );
    if (result?.files.single.path != null) {
      setState(() {
        _selectedFile = File(result!.files.single.path!);
        _status = 'Selected: ${_selectedFile!.path.split('/').last}';
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        Fluttertoast.showToast(msg: '⚠️ Storage permission denied');
        throw Exception('Permission denied');
      }
    }
  }

  Future<void> _processAudio() async {
    if (_selectedFile == null) {
      Fluttertoast.showToast(msg: '📁 Please select an audio file');
      return;
    }

    try {
      await _requestPermissions();
    } catch (_) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = '🎬 Applying cinematic DSP...';
    });

    try {
      final outputFile = await _convertAndBoost(_selectedFile!);
      if (outputFile != null && await outputFile.exists()) {
        setState(() {
          _status = '✅ Success! Saved to:\n${outputFile.path}';
          _isProcessing = false;
        });
        Fluttertoast.showToast(
          msg: 'Cinematic audio ready!',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        throw Exception('Output file not found');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Failed: ${e.toString()}';
        _isProcessing = false;
      });
      Fluttertoast.showToast(
        msg: 'Processing failed',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Audio v2'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cinematic Audio DSP',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bass boost + format conversion using native FFmpeg',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 40),

            // File display / picker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Input File:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile?.path.split('/').last ?? 'None',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('📂 Choose Audio File'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ? Colors.grey : Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Processing...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : const Text(
                        '🎬 Apply Cinema DSP (Bass Boost → MP3)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.startsWith('✅')
                    ? Colors.green.shade50
                    : _status.startsWith('❌')
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _status.startsWith('✅')
                      ? Colors.green
                      : _status.startsWith('❌')
                          ? Colors.red
                          : Colors.blue,
                ),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  color: _status.startsWith('✅')
                      ? Colors.green.shade800
                      : _status.startsWith('❌')
                          ? Colors.red.shade800
                          : Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '💡 Output: High-quality MP3 with +12dB bass boost\n(cinematic depth & impact)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
