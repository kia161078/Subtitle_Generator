import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtitle/screens/premium_screen.dart';
import 'package:subtitle/screens/setting_screen.dart';
import 'package:video_player/video_player.dart';
import 'history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubtitleScreen extends StatefulWidget {
  const SubtitleScreen({super.key});

  @override
  State<SubtitleScreen> createState() => _SubtitleScreenState();
}

class _SubtitleScreenState extends State<SubtitleScreen> {
  File? _selectedVideo;
  String _selectedLang = 'fa';
  bool _isLoading = false;
  String _statusMessage = '';
  int _currentIndex = 0;
  List<String> _historyList = [];

  final String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> checkAndProcessSubtitle({
  required BuildContext context,
  required int videoDurationInSeconds,
  required VoidCallback onAllowedToProceed,
}) async {
  if (_selectedVideo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a video from your device first!'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    

    DocumentSnapshot<Map<String, dynamic>> docSnapshot;
    try {
      docSnapshot = await userDocRef.get().timeout(const Duration(seconds: 5));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to server. Check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isPremium = false;
    int subtitleCount = 0;

    if (docSnapshot.exists) {
      isPremium = docSnapshot.data()?['isPremium'] ?? false;
      subtitleCount = docSnapshot.data()?['subtitleCount'] ?? 0;
    } else {
      await userDocRef.set({
        'email': user.email,
        'subtitleCount': 0,
        'isPremium': false,
      }, SetOptions(merge: true));
    }

    if (isPremium) {
      setState(() => _isLoading = false);
      onAllowedToProceed();
      return;
    }

    if (videoDurationInSeconds > 60) {
      setState(() => _isLoading = false);
      _redirectToPremium(context, 'Videos longer than 1 minute require a Premium account.');
      return;
    }

    if (subtitleCount >= 3) {
      setState(() => _isLoading = false);
      _redirectToPremium(context, 'You have reached the free limit of 3 subtitles. Upgrade to Premium.');
      return;
    }

    await userDocRef.update({
      'subtitleCount': subtitleCount + 1,
    });

    setState(() => _isLoading = false);
    onAllowedToProceed();
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}

void _redirectToPremium(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.orangeAccent),
  );
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PremiumScreen()),
  );
}

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList = prefs.getStringList('subtitle_history') ?? [];
    });
  }

  Future<void> _saveToHistory(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList.insert(0, fileName);
    });
    await prefs.setStringList('subtitle_history', _historyList);
  }

  Future<void> _deleteHistoryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList.removeAt(index);
    });
    await prefs.setStringList('subtitle_history', _historyList);
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList.clear();
    });
    await prefs.remove('subtitle_history');
  }

  int _videoDurationSeconds = 0;

  Future<void> _pickVideo() async {
    try {
      PlatformFile? file = await FilePicker.pickFile(
        type: FileType.video,
      );
  
      if (file != null && file.path != null) {
        
        final controller = VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        final duration = controller.value.duration.inSeconds;
        await controller.dispose(); 
  
        setState(() {
          _selectedVideo = File(file.path!);
          _videoDurationSeconds = duration;
          _statusMessage = 'Video selected: ${file.name} (${duration}s)';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting video: $e';
      });
    }
  }

  Future<void> _generateSubtitleDirectly() async {
    if (_selectedVideo == null) {
      setState(() {
        _statusMessage = 'Please select a video first!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading and processing directly ... ';
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3.5-flash-lite',
        apiKey: geminiApiKey,
      );

      final videoBytes = await _selectedVideo!.readAsBytes();

      final prompt = TextPart(
        "You are an expert professional video transcriber, translator, and subtitle maker. "
        "Listen to this video/audio, transcribe the spoken words accurately, translate them into '$_selectedLang', "
        "and format the output strictly as a valid .srt subtitle file with precise timestamps "
        "(e.g., 00:00:01,000 --> 00:00:04,500). "
        "Do not include any extra conversational text or markdown code blocks outside the srt structure, "
        "just return the raw srt content.",
      );

      final videoPart = DataPart('video/mp4', videoBytes);

      final response = await model.generateContent([
        Content.multi([prompt, videoPart])
      ]);

      final srtContent = response.text;

      if (srtContent == null || srtContent.isEmpty) {
        throw Exception('No response received.');
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String fileName = 'subtitle_${DateTime.now().millisecondsSinceEpoch}_$_selectedLang.srt';
      String srtPath = '${directory?.path}/$fileName';
      
      File srtFile = File(srtPath);
      await srtFile.writeAsString(srtContent);

      await _saveToHistory(fileName);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Subtitle generated successfully!\nSaved in the Download folder:\n$fileName';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'AI processing error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1430),
        appBar: AppBar(
          title: const Text('WTSub'),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 52, 42, 96),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          elevation: 8,
          shadowColor: const Color(0xFFBC13FE).withOpacity(0.6),
          toolbarHeight: 70,
        ),
        body: _getSelectedScreen(),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 52, 42, 96),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBC13FE).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF00F0FF),
              unselectedItemColor: Colors.white60,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Setting',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star_rounded),
                  label: 'Premium',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 
  Widget _getSelectedScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return HistoryScreen(
          historyList: _historyList,
          onDeleteItem: _deleteHistoryItem,
          onClearAll: _clearAllHistory,
        );
      case 2:
        return const SettingScreen();
      case 3:
        return const PremiumScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickVideo,
            icon: const Icon(Icons.video_library, color: Color.fromARGB(255, 52, 42, 96)),
            label: const Text('Pick Video from Device', style: TextStyle(color: Color.fromARGB(255, 52, 42, 96))),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Subtitle Language: ', style: TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                dropdownColor: const Color.fromARGB(255, 52, 42, 96),
                value: _selectedLang,
                items: const [
                  DropdownMenuItem(value: 'fa', child: Text('Farsi (FA)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'en', child: Text('English (EN)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'es', child: Text('Spanish (ES)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'de', child: Text('German (DE)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'it', child: Text('Italian (IT)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'ru', child: Text('Russian (RU)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'tr', child: Text('Turkish (TR)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'ar', child: Text('Arabic (AR)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'hi', child: Text('Indian (HI)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'zh', child: Text('Chinese (ZH)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'fr', child: Text('French (FR)', style: TextStyle(color: Colors.white))),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedLang = value!;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 52, 42, 96),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              elevation: 8,
              shadowColor: const Color(0xFFBC13FE).withOpacity(0.6),
            ),
            onPressed: _isLoading ? null : () {
              
              checkAndProcessSubtitle(
                context: context,
                videoDurationInSeconds: _videoDurationSeconds, 
                onAllowedToProceed: () {
                  _generateSubtitleDirectly();
                },
              );
            },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Generate Subtitle', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 30),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

