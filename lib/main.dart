import 'dart:io';
import 'package:flutter/material.dart';
// If using the standard package, use these imports. 
// If using your '_new' fork, change 'ffmpeg_kit_flutter' to 'ffmpeg_kit_flutter_new'
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
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
        // Using a modern color scheme seed
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

  /// Picks an audio file using the native file explorer
  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        // Caching ensures we have a valid path we can read
        allowMultiple: false, 
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudio = File(result.files.single.path!);
          _status = 'Selected: ${_selectedAudio!.path.split('/').last}';
        });
      } else {
        // User canceled the picker
        debugPrint("File picker canceled or failed.");
      }
    } catch (e) {
      setState(() {
        _status = "Error picking file: $e";
      });
    }
  }

  /// Processes the audio using FFmpeg
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

      // Ensure input path is safe for command line (wrap in quotes)
      final inputPath = _selectedAudio!.path;

      if (_selectedAction == 'Convert to WAV') {
        outputPath = '${directory.path}/cinema_converted_$timestamp.wav';
        // -y overwrites output if exists, -ar sets sample rate, -ac sets channels
        command = '-y -i "$inputPath" -ar 44100 -ac 2 "$outputPath"';
      } else {
        // Cinema Bass Boost: Strong low-end enhancement
        outputPath = '${directory.path}/cinema_boosted_$timestamp.mp3';
        // Complex filter explanation:
        // equalizer=f=80...  -> Boosts 80Hz (Bass)
        // equalizer=f=200... -> Boosts 200Hz (Lower Mids/Punch)
        command =
            '-y -i "$inputPath" -af "equalizer=f=80:t=q:w=1.5:g=8,equalizer=f=200:t=q:w=1:g=4" "$outputPath"';
      }

      debugPrint("Running FFmpeg command: $command");

      // Execute FFmpeg command
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getLogs();

      // SAFETY CHECK: Ensure the widget is still on screen before updating UI
      if (!mounted) return;

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _status = 'Success!\nSaved to:\n$outputPath';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cinematic audio processed successfully! 🎬🔊'),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Log errors for debugging
        for (var log in logs) {
          debugPrint(log.getMessage());
        }
        setState(() {
          _status = 'Processing failed. Check debug console for FFmpeg logs.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Processing failed.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Audio V2'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enhance your audio for a true cinema experience',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Pick File Button
              FilledButton.icon(
                onPressed: _isProcessing ? null : _pickAudioFile,
                icon: const Icon(Icons.audiotrack),
                label: const Text('Pick Audio File'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              // Action Selection and Process Button
              if (_selectedAudio != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAction,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: _isProcessing
                          ? null
                          : (String? newValue) {
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
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: _isProcessing ? null : _processAudio,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isProcessing ? 'Processing...' : 'Process Audio'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),

                // Status Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    _status,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Courier'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

