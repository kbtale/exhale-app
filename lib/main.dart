// Standard imports for Flutter functionality and async operations
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Audio recording and playback
import 'package:flutter_sound/flutter_sound.dart';



// File system access for saving recordings temporarily
import 'package:path_provider/path_provider.dart';

// Runtime permissions handling (for microphone)
import 'package:permission_handler/permission_handler.dart';

// Web platform detection
import 'package:flutter/foundation.dart' show kIsWeb;

// Localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Smart imports that switch between web and mobile implementations
// This helps us handle platform differences gracefully
import 'file_utils.dart' if (dart.library.html) 'web_file_utils.dart';

void main() {
  // Make sure Flutter is properly initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock the app to portrait mode - looks better for this UI
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Fire up the app!
  runApp(const ExhaleApp());
}

/// The main app widget that sets up theming and the home screen
class ExhaleApp extends StatelessWidget {
  const ExhaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exhale',
      // Remove the debug banner - we want this to look clean
      debugShowCheckedModeBanner: false,
      
      // Set up localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
        Locale('it'), // Italian
        Locale('pt'), // Portuguese
        Locale('ja'), // Japanese
        Locale('zh'), // Chinese
        Locale('ru'), // Russian
        Locale('ar'), // Arabic
        Locale('ko'), // Korean
        Locale('nl'), // Dutch
        Locale('sv'), // Swedish
      ],
      
      // Set up our dark theme with purple accents
      theme: ThemeData(
        // Use Material 3 for modern UI components
        useMaterial3: true,
        
        // Create a dark color scheme based on our purple brand color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A35FF), // Our signature purple
          brightness: Brightness.dark,
        ),
        
        // Almost black background for that sleek look
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      
      // The main (and only) screen of our app
      home: const ExhaleScreen(),
    );
  }
}

/// The main screen widget - this is where all the action happens
class ExhaleScreen extends StatefulWidget {
  const ExhaleScreen({super.key});

  @override
  State<ExhaleScreen> createState() => _ExhaleScreenState();
}

/// The state for our main screen - handles recording, playback, and animations
class _ExhaleScreenState extends State<ExhaleScreen> with SingleTickerProviderStateMixin, TickerProviderStateMixin {
  // ----- Audio Components -----
  // The recorder that captures our voice
  late FlutterSoundRecorder _recorder;
  
  // The player that plays back what we recorded
  late FlutterSoundPlayer _player;
  
  // Tracking the recorder's initialization state
  bool _isRecorderInitialized = false;
  
  // Are we currently recording or playing?
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  
  // Where the recording is temporarily stored
  String? _recordingPath;
  
  // Flag to show if we have a recording ready to play
  bool _hasRecording = false;
  
  // Playback progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackProgress = 0.0;
  
  // ----- Animation Properties -----
  // Controls when to show the animations
  bool _showWavesAnimation = false;

  // Animation controller for the waves animation
  late AnimationController _wavesAnimationController;
  
  // Animation controller for the pulsing effect during recording
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  // ----- Platform Detection -----
  // Are we running on web? This affects how we handle audio
  bool _isWebPlatform = false;
  
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
    
    // Setup waves animation controller
    _wavesAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _wavesAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _wavesAnimationController.repeat();
      }
    });
    
    // Setup pulsing animation for recording state
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isRecording) {
          _pulseAnimationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    if (!_isWebPlatform) {
      _recorder.closeRecorder();
      _player.closePlayer();
    }
    _wavesAnimationController.dispose();
    _pulseAnimationController.dispose();
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
    
    // Listen to playback progress
    _player.onProgress!.listen((e) {
      if (mounted) {
        setState(() {
          _currentPosition = e.position;
          _totalDuration = e.duration;
          if (_totalDuration.inMilliseconds > 0) {
            _playbackProgress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isWebPlatform) {
      // For web, we'll just simulate the recording experience
      setState(() {
        _isRecording = true;
        _pulseAnimationController.forward(); // Start pulsing animation
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
        _pulseAnimationController.forward(); // Start pulsing animation
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Stop the pulsing animation
    _pulseAnimationController.stop();
    _pulseAnimationController.reset();

    if (_isWebPlatform) {
      // For web, we'll just simulate the experience
      setState(() {
        _isRecording = false;
        _hasRecording = true; // Show the play button
      });
      return;
    }
    
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _hasRecording = true; // Show the play button
      });
      
      // No longer auto-playing, user will press the play button
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _startPlayback() async {
    if (_isWebPlatform || _recordingPath == null || _isPlaying) return;

    try {
      setState(() {
        _isPlaying = true;
        _showWavesAnimation = true;
      });
      _wavesAnimationController.repeat();

      await _player.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          _stopPlayback();
        },
      );
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _stopPlayback(showAnimation: false);
    }
  }

  Future<void> _stopPlayback({bool showAnimation = true}) async {
    if (_isWebPlatform) return;

    if (_isPlaying || _isPaused) {
      await _player.stopPlayer();
    }

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _hasRecording = false;
      _showWavesAnimation = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _playbackProgress = 0.0;
    });
    _wavesAnimationController.stop();
    _wavesAnimationController.reset();
    _deleteRecording();
  }

  Future<void> _pausePlayback() async {
    if (!_isPlaying || _isPaused) return;
    try {
      await _player.pausePlayer();
      setState(() {
        _isPaused = true;
      });
      _wavesAnimationController.stop();
    } catch (e) {
      debugPrint('Error pausing playback: $e');
      _stopPlayback(showAnimation: false);
    }
  }

  Future<void> _resumePlayback() async {
    if (!_isPaused) return;
    try {
      await _player.resumePlayer();
      setState(() {
        _isPaused = false;
      });
      _wavesAnimationController.repeat();
    } catch (e) {
      debugPrint('Error resuming playback: $e');
      _stopPlayback(showAnimation: false);
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

  Widget _buildWaveAnimation() {
    const int barCount = 8;
    const double barWidth = 4.0;
    const double barSpacing = 6.0;
    
    return AnimatedBuilder(
      animation: _wavesAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(barCount, (index) {
            double delay = index * 0.15;
            double animationValue = (_wavesAnimationController.value + delay) % 1.0;
            double height = 12 + (sin(animationValue * 2 * pi) * 15);
            
            // Calculate if this bar should be "filled" based on progress
            double barProgress = index / (barCount - 1);
            bool isFilled = _playbackProgress >= barProgress;
            
            return Container(
              width: barWidth,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: barSpacing / 2),
              decoration: BoxDecoration(
                color: isFilled ? const Color(0xFF6A35FF) : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
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
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    AppLocalizations.of(context)!.appSubtitle,
                    style: const TextStyle(
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
                        child: Text(
                          AppLocalizations.of(context)!.webModeNote,
                          style: const TextStyle(color: Colors.amber, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  
                  const Spacer(flex: 3),
                  
                  // Mic button
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          width: 120 * (_isRecording ? _pulseAnimation.value : 1.0),
                          height: 120 * (_isRecording ? _pulseAnimation.value : 1.0),
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red : const Color(0xFF6A35FF),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : const Color(0xFF6A35FF)).withOpacity(0.5),
                                blurRadius: _isRecording ? 30 : 20,
                                spreadRadius: _isRecording ? 10 : 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 50 * (_isRecording ? _pulseAnimation.value : 1.0),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hint text
                  Text(
                    _isRecording ? AppLocalizations.of(context)!.tapToStopRecording : 
                    _hasRecording ? (_isPlaying ? (_isPaused ? AppLocalizations.of(context)!.paused : AppLocalizations.of(context)!.playing) : AppLocalizations.of(context)!.readyToListen) :
                    AppLocalizations.of(context)!.tapToStartRecording,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  // Fixed space for play button/playback controls - always reserve this space
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: SizedBox(
                      height: 64, // Fixed height to prevent layout shifts
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _hasRecording && !_isPlaying ? 1.0 : 0.0,
                        child: ElevatedButton.icon(
                          onPressed: _hasRecording && !_isPlaying ? _startPlayback : null,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(AppLocalizations.of(context)!.listen),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A35FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Fixed space for playback controls - always reserve this space
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: SizedBox(
                      height: 64, // Fixed height to prevent layout shifts
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isPlaying ? 1.0 : 0.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                              iconSize: 40,
                              color: Colors.white,
                              onPressed: _isPlaying ? (_isPaused ? _resumePlayback : _pausePlayback) : null,
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.stop),
                              iconSize: 40,
                              color: Colors.white,
                              onPressed: _isPlaying ? () => _stopPlayback() : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Fixed space for wave animation - always reserve this space
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                    child: SizedBox(
                      height: 60, // Fixed height to prevent layout shifts
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showWavesAnimation ? 1.0 : 0.0,
                        child: _buildWaveAnimation(),
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}
