import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'file_utils.dart' if (dart.library.html) 'web_file_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ExhaleApp());
}

class ExhaleApp extends StatelessWidget {
  const ExhaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exhale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A35FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const ExhaleScreen(),
    );
  }
}

class ExhaleScreen extends StatefulWidget {
  const ExhaleScreen({super.key});

  @override
  State<ExhaleScreen> createState() => _ExhaleScreenState();
}

class _ExhaleScreenState extends State<ExhaleScreen> with SingleTickerProviderStateMixin {
  // Audio recorder and player
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  bool _isWebPlatform = false;
  
  // Animation controllers
  late AnimationController _poofAnimationController;
  bool _showPoofAnimation = false;
  double _buttonScale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _isWebPlatform = kIsWeb;
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    if (!_isWebPlatform) {
      _initRecorder();
      _initPlayer();
    }
    
    _poofAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _poofAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showPoofAnimation = false;
        });
        _poofAnimationController.reset();
      }
    });
  }

  @override
  void dispose() {
    if (!_isWebPlatform) {
      _recorder.closeRecorder();
      _player.closePlayer();
    }
    _poofAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    _player.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  Future<void> _startRecording() async {
    if (_isWebPlatform) {
      // For web, we'll just simulate the recording experience
      setState(() {
        _isRecording = true;
        _buttonScale = 1.05; // Scale up the button when recording
      });
      return;
    }
    
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }

    try {
      _recordingPath = await FileUtils.getTemporaryPath('exhale_recording.aac');
      
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _buttonScale = 1.05; // Scale up the button when recording
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    if (_isWebPlatform) {
      // For web, we'll just simulate the experience
      setState(() {
        _isRecording = false;
        _buttonScale = 1.0; // Reset button scale
      });
      
      // Simulate a short delay before showing the animation
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showPoofAnimation = true;
        });
        _poofAnimationController.forward();
      });
      
      return;
    }
    
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _buttonScale = 1.0; // Reset button scale
      });

      // Auto-playback once
      await _playRecording();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_isWebPlatform || _recordingPath == null || _isPlaying) return;

    try {
      setState(() {
        _isPlaying = true;
      });

      await _player.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _showPoofAnimation = true;
          });
          _poofAnimationController.forward();
          _deleteRecording();
        },
      );
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      debugPrint('Error playing recording: $e');
    }
  }

  Future<void> _deleteRecording() async {
    if (_isWebPlatform || _recordingPath == null) return;

    try {
      final deleted = await FileUtils.deleteFile(_recordingPath!);
      if (deleted) {
        _recordingPath = null;
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // App title
                  const Text(
                    'EXHALE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  const Text(
                    'Speak your mind, let it go',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  if (_isWebPlatform)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'Note: Full audio functionality is only available on mobile devices. This is a demo mode.',
                          style: TextStyle(color: Colors.amber, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  
                  const Spacer(flex: 3),
                  
                  // Mic button
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      width: 120 * _buttonScale,
                      height: 120 * _buttonScale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A35FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6A35FF).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 50 * _buttonScale,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hint text
                  Text(
                    _isRecording ? 'Release to vent' : 'Hold to vent',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const Spacer(flex: 4),
                ],
              ),
            ),
            
            // Poof animation overlay
            if (_showPoofAnimation)
              Center(
                child: Lottie.asset(
                  'assets/animations/poof.json',
                  controller: _poofAnimationController,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
