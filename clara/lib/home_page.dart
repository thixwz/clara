import 'package:clara/app_colors.dart';
import 'package:clara/api_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui'; 
import 'dart:io';
import 'models/chat_model.dart';

class Report {
  final String id;
  final String patientName;
  final String diagnosis;
  final String bloodPressure;
  final DateTime date;
  final String? filePath;
  Report({required this.id, required this.patientName, required this.diagnosis, required this.bloodPressure, required this.date, this.filePath});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  if (!Hive.isBoxOpen('chats')) {
    await Hive.openBox<Chat>('chats');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1117), // Pure black like ChatGPT
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E1117), // Pure black like ChatGPT
          elevation: 0,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Controllers for page sliding
  late PageController _mainPageController;
  double _currentPageValue = 0.0;
  
  // Settings panel controller
  bool _isSettingsPanelOpen = false;
  
  late Box<Chat> _chatBox;
  List<Chat> _chats = [];
  final TextEditingController _askController = TextEditingController();
  
  final List<Report> _reports = [
    Report(
      id: const Uuid().v4(),
      patientName: 'John Doe',
      diagnosis: 'Hypertension',
      bloodPressure: '120/80 mmHg',
      date: DateTime(2024, 6, 1),
      filePath: null,
    ),
    Report(
      id: const Uuid().v4(),
      patientName: 'Jane Smith',
      diagnosis: 'Diabetes',
      bloodPressure: '130/85 mmHg',
      date: DateTime(2024, 5, 28),
      filePath: null,
    ),
  ];
  
  int _currentReportIndex = 0;
  late PageController _reportPageController;
  OverlayEntry? _plusMenuOverlay;
  
  // Separate keys for home and history pages to avoid conflicts
  final GlobalKey _homePlusButtonKey = GlobalObjectKey("homePlusButtonKey");
  final GlobalKey _historyPlusButtonKey = GlobalObjectKey("historyPlusButtonKey");
  final LayerLink _homePlusButtonLayerLink = LayerLink();
  final LayerLink _historyPlusButtonLayerLink = LayerLink();
  
  AnimationController? _menuAnimationController;
  Animation<double>? _menuScaleAnimation;
  late AnimationController _footerController;
  late Animation<Offset> _footerOffsetAnimation;
  String? _selectedFileName;
  String? _selectedFileExtension;
  String? _selectedFilePath;

  // Removed ApiService instance, now using static methods
  final String _userId = 'arvinth';
  String? _sessionId;

  // Animation controllers for welcome text - improved for smoother transitions
  late AnimationController _textAnimationController;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textPositionAnimation;
  int _currentTextIndex = 0;
  
  // Welcome messages that will animate
  final List<String> _welcomeMessages = [
    'How can I help you today?',
    'Ask Clara...',
    'How could Clara assist today?',
    'What would you like to know?',
    'Let Clara analyze your documents',
  ];

  // Settings panel animation controller
  late AnimationController _settingsPanelController;
  late Animation<Offset> _settingsPanelAnimation;

  @override
  void initState() {
    super.initState();
    // Main page controller for left/right sliding - more responsive
    _mainPageController = PageController(
      initialPage: 0, // Start at the main page
      viewportFraction: 1.0,
    );
    
    // Make the PageController more responsive with higher-frequency updates
    _mainPageController.addListener(() {
      setState(() {
        _currentPageValue = _mainPageController.page ?? 0.0;
      });
    });
    
    _reportPageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _chatBox = Hive.box<Chat>('chats');
    _loadChats();
    
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _footerOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _footerController, curve: Curves.easeOut));
    
    // Setup improved welcome text animation for smoother transitions
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _textOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_textAnimationController);
    
    _textPositionAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3))
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_textAnimationController);
    
    // Settings panel animation
    _settingsPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _settingsPanelAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _settingsPanelController,
      curve: Curves.easeOut,
    ));
    
    // Start the animated welcome text
    _animateWelcomeText();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _footerController.forward();
    });
  }

  void _animateWelcomeText() {
    _textAnimationController.forward();
    
    // Add status listener for continuous sequence
    _textAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _welcomeMessages.length;
        });
        // Reset and start next animation immediately for smooth transition
        _textAnimationController.reset();
        _textAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainPageController.dispose();
    _reportPageController.dispose();
    _askController.dispose();
    _footerController.dispose();
    _menuAnimationController?.dispose();
    _textAnimationController.dispose();
    _settingsPanelController.dispose();
    super.dispose();
  }

  void _toggleSettingsPanel() {
    setState(() {
      _isSettingsPanelOpen = !_isSettingsPanelOpen;
      if (_isSettingsPanelOpen) {
        _settingsPanelController.forward();
      } else {
        _settingsPanelController.reverse();
      }
    });
  }

  Future<void> _pickAndCreateReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    
    // Upload file to backend
    if (file.path != null) {
      try {
        final uploadResult = await ApiService.uploadFile(File(file.path!), userId: _userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded to Clara (${uploadResult["type"] ?? "file"})')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
    
    final newReport = Report(
      id: const Uuid().v4(),
      patientName: file.name,
      diagnosis: 'File Uploaded',
      bloodPressure: 'N/A',
      date: DateTime.now(),
    );

    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ReportDetailPage(report: newReport, isLatest: true, filePath: file.path),
      ),
    );

    setState(() {
      _reports.insert(0, newReport);
      _currentReportIndex = 0;
      if (_reportPageController.hasClients) {
        _reportPageController.jumpToPage(0);
      }
    });
  }

  void _openReportDetail(Report report, bool isLatest) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ReportDetailPage(report: report, isLatest: isLatest, filePath: report.filePath),
      ),
    );
  }

  void _openChat(Chat chat) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ChatPage(chat: chat, userId: _userId),
      ),
    );
  }

  void _loadChats() {
    setState(() {
      _chats = _chatBox.values.toList().reversed.toList();
    });
  }

  void _saveChat(Chat chat) {
    _chatBox.add(chat);
    _loadChats();
  }

  void _showPlusMenu(bool isHomePage) {
    final GlobalKey plusButtonKey = isHomePage ? _homePlusButtonKey : _historyPlusButtonKey;
    final LayerLink plusButtonLayerLink = isHomePage ? _homePlusButtonLayerLink : _historyPlusButtonLayerLink;
    
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _menuScaleAnimation = CurvedAnimation(
      parent: _menuAnimationController!,
      curve: Curves.ease,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = plusButtonKey.currentContext;
      if (context == null) return;
      _plusMenuOverlay = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _plusMenuOverlay?.remove();
                  _plusMenuOverlay = null;
                  _menuAnimationController?.dispose();
                },
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            CompositedTransformFollower(
              link: plusButtonLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -165),
              child: FadeTransition(
                opacity: _menuScaleAnimation!,
                child: ScaleTransition(
                  scale: _menuScaleAnimation!,
                  alignment: Alignment.bottomLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Material(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        elevation: 10,
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlusMenuItem(
                                icon: Icons.photo_camera,
                                text: 'Photo OCR',
                                onTap: () async {
                                  _plusMenuOverlay?.remove();
                                  _plusMenuOverlay = null;
                                  _menuAnimationController?.dispose();
                                  final picker = ImagePicker();
                                  final photo = await picker.pickImage(source: ImageSource.camera);
                                  if (photo != null) {
                                    setState(() {
                                      _selectedFileName = photo.name;
                                      _selectedFileExtension = photo.name.split('.').length > 1 ? photo.name.split('.').last : '';
                                      _selectedFilePath = photo.path;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Photo captured:  [${photo.path}')),
                                    );
                                    
                                    // Upload file to backend
                                    if (_selectedFilePath != null && _selectedFilePath!.isNotEmpty) {
                                      try {
                                        final result = await ApiService.uploadFile(File(_selectedFilePath!), userId: _userId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Uploaded to Clara (${result["type"] ?? "file"})')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Upload failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                              const Divider(height: 1, color: Colors.white12, indent: 16, endIndent: 16),
                              _PlusMenuItem(
                                icon: Icons.image,
                                text: 'Image OCR',
                                onTap: () async {
                                  _plusMenuOverlay?.remove();
                                  _plusMenuOverlay = null;
                                  _menuAnimationController?.dispose();
                                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                  if (result != null && result.files.isNotEmpty) {
                                    setState(() {
                                      _selectedFileName = result.files.first.name;
                                      _selectedFileExtension = result.files.first.extension ?? '';
                                      _selectedFilePath = result.files.first.path;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Image selected:  [${result.files.first.name}')),
                                    );
                                    
                                    // Upload file to backend
                                    if (_selectedFilePath != null && _selectedFilePath!.isNotEmpty) {
                                      try {
                                        final uploadResult = await ApiService.uploadFile(File(_selectedFilePath!), userId: _userId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Uploaded to Clara (${uploadResult["type"] ?? "file"})')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Upload failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                              const Divider(height: 1, color: Colors.white12, indent: 16, endIndent: 16),
                              _PlusMenuItem(
                                icon: Icons.attach_file,
                                text: 'Document',
                                onTap: () async {
                                  _plusMenuOverlay?.remove();
                                  _plusMenuOverlay = null;
                                  _menuAnimationController?.dispose();
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
                                  );
                                  if (result != null && result.files.isNotEmpty) {
                                    setState(() {
                                      _selectedFileName = result.files.first.name;
                                      _selectedFileExtension = result.files.first.extension ?? '';
                                      _selectedFilePath = result.files.first.path;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Document selected:  [${result.files.first.name}')),
                                    );
                                    
                                    // Upload file to backend
                                    if (_selectedFilePath != null && _selectedFilePath!.isNotEmpty) {
                                      try {
                                        final uploadResult = await ApiService.uploadFile(File(_selectedFilePath!), userId: _userId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Uploaded to Clara (${uploadResult["type"] ?? "file"})')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Upload failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      Overlay.of(context).insert(_plusMenuOverlay!);
      _menuAnimationController?.forward();
    });
  }

 void _createAndOpenChat(String question) async {
  if (question.trim().isEmpty) return;
  // If a file is selected, process it accordingly
  if (_selectedFileName != null && _selectedFileName!.isNotEmpty && _selectedFilePath != null) {
    final isDocument = ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'].contains(_selectedFileExtension?.toLowerCase());
    if (isDocument) {
      // Add as report and open report page
      final newReport = Report(
        id: const Uuid().v4(),
        patientName: _selectedFileName!,
        diagnosis: 'File Uploaded',
        bloodPressure: 'N/A',
        date: DateTime.now(),
      );
      setState(() {
        _reports.insert(0, newReport);
        _currentReportIndex = 0;
        _selectedFileName = null;
        _selectedFileExtension = null;
        _selectedFilePath = null;
      });
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ReportDetailPage(report: newReport, isLatest: true, filePath: _selectedFilePath),
        ),
      );
      return;
    } else {
      // Add as chat with image reader
      final newChat = Chat(
        id: const Uuid().v4(),
        question: question,
        answer: '', // Will show image reader
        timestamp: DateTime.now(),
      );
      _saveChat(newChat);
      _askController.clear();
      final filePath = _selectedFilePath;
      setState(() {
        _selectedFileName = null;
        _selectedFileExtension = null;
        _selectedFilePath = null;
      });
      await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ChatPage(chat: newChat, imagePath: filePath, userId: _userId),
        ),
      );
      _loadChats();
      return;
    }
  }
  
  // Normal chat flow - create chat with placeholder answer
  final newChat = Chat(
    id: const Uuid().v4(),
    question: question,
    answer: 'Thinking...', // Temporary placeholder
    timestamp: DateTime.now(),
  );
  _saveChat(newChat);
  _askController.clear();

  // Get response from API
  String answer = 'Thinking...';
  try {
    final res = await ApiService.chat(question, userId: _userId);
    answer = res.answer;
    _sessionId = res.sessionId;
  } catch (e) {
    answer = "Sorry, I couldn't get a response.";
  }

  // Update chat with real answer
  newChat.answer = answer;
  _saveChat(newChat);
  _loadChats();

  // Navigate to chat page
  await Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (context) => ChatPage(chat: newChat, userId: _userId),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      centerTitle: true,
      title: const Text(
        'Clara',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: 1.1,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: Container(),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: _toggleSettingsPanel,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            // Switch to history page
            _mainPageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuad,
            );
          },
        ),
      ],
    ),


    
    body: Stack(
      children: [
        PageView(
          controller: _mainPageController,
          physics: const PageScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          onPageChanged: (index) {
            setState(() {
              _currentPageValue = index.toDouble();
            });
          },
          children: [
  Stack(
    children: [
      // Your home page content here
      // For example, your animated welcome text and input bar
      Center(
        child: FadeTransition(
          opacity: _textOpacityAnimation,
          child: SlideTransition(
            position: _textPositionAnimation,
            child: Text(
              _welcomeMessages[_currentTextIndex],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      _buildInputBar(isHomePage: true),
    ],
  ),
  Stack(
    children: [
      _buildHistoryPage(context),
      _buildInputBar(isHomePage: false),
    ],
  ),
],
        ),

        // The state indicator on top left
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _currentPageValue < 0.5 ? 'Home' : 'History',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        
        // Settings panel and other overlays...
        if (_isSettingsPanelOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleSettingsPanel,
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
        
        if (_isSettingsPanelOpen)
          Positioned.fill(
            child: SlideTransition(
              position: _settingsPanelAnimation,
              child: Row(
                children: [
                  // Settings panel takes partial screen width
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85, 
                    child: _buildSettingsPanel(context),
                  ),
                  // Empty space for the rest of the screen
                  Expanded(child: GestureDetector(
                    onTap: _toggleSettingsPanel,
                    child: Container(color: Colors.transparent),
                  )),
                ],
              ),
            ),
          ),
          
        // >>>>>>>>>> STATE INDICATOR MOVED TO THE VERY END <<<<<<<<<<
        // >>>>>>>>>> THIS MAKES IT APPEAR ON TOP OF EVERYTHING <<<<<<<<<<
        
      ],
    ),
  );
}
// Tab button builder

// Updated input bar builder that takes a parameter for which page it's on
Widget _buildInputBar({required bool isHomePage}) {
  // Use different keys and layer links based on which page we're on
  final GlobalKey plusButtonKey = isHomePage ? _homePlusButtonKey : _historyPlusButtonKey;
  final LayerLink plusButtonLayerLink = isHomePage ? _homePlusButtonLayerLink : _historyPlusButtonLayerLink;
  
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: SlideTransition(
      position: _footerOffsetAnimation,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Input bar – glassmorphic with plus button inside
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color.fromARGB(255, 146, 224, 57).withOpacity(0.2),
                          width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedFileName != null && _selectedFileName!.isNotEmpty)
                            _buildFilePreview(context),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Plus button now with unique key per page
                                CompositedTransformTarget(
                                  link: plusButtonLayerLink,
                                  child: Container(
                                    key: plusButtonKey,
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add, color: AppColors.textPrimary),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        if (_plusMenuOverlay == null) {
                                          _showPlusMenu(isHomePage);
                                        } else {
                                          _plusMenuOverlay?.remove();
                                          _plusMenuOverlay = null;
                                          _menuAnimationController?.dispose();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 56,
                                      maxHeight: 120,
                                    ),
                                    child: Scrollbar(
                                      child: TextField(
                                        controller: _askController,
                                        decoration: const InputDecoration(
                                            border: InputBorder.none, hintText: 'Ask Clara...'),
                                        style: TextStyle(color: AppColors.textPrimary),
                                        minLines: 1,
                                        maxLines: 6,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Slightly enlarge the arrow button and ensure it stays centred.
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _createAndOpenChat(_askController.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Settings Panel (left side) - redesigned with user at bottom
Widget _buildSettingsPanel(BuildContext context) {
  return Container(
    color: const Color(0xFF0E1117), // Pure black like ChatGPT
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button and title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSettingsPanel,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          // Settings items
          _buildSettingsTile(Icons.language, 'Language', 'English (US)'),
          _buildSettingsTile(Icons.dark_mode, 'Theme', 'Dark'),
          _buildSettingsTile(Icons.notifications_outlined, 'Notifications', 'On'),
          _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy', null),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', null),
          _buildSettingsTile(Icons.info_outline, 'About Clara', null),
          
          const Spacer(),
          
          // User profile moved to bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 25,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Free account',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // App version
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Clara v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Settings tile widget
  Widget _buildSettingsTile(IconData icon, String text, String? value) {
    return InkWell(
      onTap: () {
        // Implement settings action
        _toggleSettingsPanel();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // History Page - improved with minimal spacing and better report cards
  Widget _buildHistoryPage(BuildContext context) {
    return Container(
      color: const Color.fromARGB(0, 31, 51, 37), // Pure black like ChatGPT
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56), // Account for AppBar
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                  onPressed: _pickAndCreateReport,
                ),
              ],
            ),
          ),
          
          // Reports section with improved cards
          SizedBox(
            height: 190,
            child: _reports.isEmpty
                ? Center(
                    child: Text(
                      'No reports yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                : PageView.builder(
                    controller: _reportPageController,
                    itemCount: _reports.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentReportIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final isLatest = index == 0;
                      
                      // Improved card design - more minimalist and bold
                      return GestureDetector(
  onTap: () => _openReportDetail(report, isLatest),
  child: Card(
    color: isLatest ? const Color(0xFFFFE787) : const Color.fromARGB(255, 100, 122, 59), // <-- THIS LINE
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row with icon
                                Row(
                                  children: [
                                    // Status indicator for latest
                                    if (isLatest)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'LATEST',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Icon(
                                      Icons.file_present,
                                      color: isLatest ? Colors.black.withOpacity(0.7) : Colors.white70,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Patient name - bold and prominent
                                Text(
                                  report.patientName,
                                  style: TextStyle(
                                    color: isLatest ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Diagnosis - secondary emphasis
                                Row(
                                  children: [
                                    Icon(
                                      Icons.medical_information,
                                      size: 16,
                                      color: isLatest ? Colors.black.withOpacity(0.6) : Colors.white60,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        report.diagnosis,
                                        style: TextStyle(
                                          color: isLatest ? Colors.black.withOpacity(0.8) : Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Date at bottom
                                Text(
                                  '${report.date.day.toString().padLeft(2, '0')}/${report.date.month.toString().padLeft(2, '0')}/${report.date.year}',
                                  style: TextStyle(
                                    color: isLatest ? Colors.black.withOpacity(0.6) : Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          if (_reports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_reports.length, (index) {
                  final isActive = _currentReportIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Recent Chats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_chats.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      // Add confirmation dialog and clear logic
                    },
                  ),
              ],
            ),
          ),
          
          // Chat history
          _chats.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 120),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _openChat(chat),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.question ?? '',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.answer ?? '',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${chat.timestamp.day.toString().padLeft(2, '0')}/${chat.timestamp.month.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: AppColors.textSecondary.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(_selectedFileExtension?.toLowerCase());

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), // Padding around the preview
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff4F3A3D).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedFilePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.insert_drive_file,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFileName = null;
                  _selectedFileExtension = null;
                  _selectedFilePath = null;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PlusMenuItem({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}      

// Rest of your code remains the same (ChatPage, ReportDetailPage, etc.)

class ChatPage extends StatefulWidget {
  final Chat chat;
  final String? imagePath;
  final String userId;
  const ChatPage({Key? key, required this.chat, this.imagePath, required this.userId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late List<_Message> _messages;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _footerController;
  late Animation<Offset> _footerOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _messages = [
      _Message(text: widget.chat.question, isUser: true, timestamp: widget.chat.timestamp),
      if (widget.imagePath != null)
        _Message(text: '', isUser: false, timestamp: widget.chat.timestamp, imagePath: widget.imagePath),
      if (widget.imagePath == null)
        _Message(text: widget.chat.answer, isUser: false, timestamp: widget.chat.timestamp),
    ];

    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _footerOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _footerController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      _footerController.forward();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: q, isUser: true, timestamp: DateTime.now()));
      _messages.add(_Message(text: '…', isUser: false, timestamp: DateTime.now()));
    });
    _chatController.clear();

    try {
      final res = await ApiService.chat(q, userId: widget.userId);
      setState(() {
        _messages.removeLast();
        _messages.add(_Message(text: res.answer, isUser: false, timestamp: DateTime.now()));
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(_Message(text: 'Sorry, I could not get a response. ($e)', isUser: false, timestamp: DateTime.now()));
      });
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatHeader(BuildContext context, Color color, Color textColor) {
    const headerHeight = 180.0;
    return Container(
      height: headerHeight,
      color: color,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0), // For app bar that is transparent
                child: Text(
                  widget.chat.question,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.15), offset: Offset(0, 2))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              '${widget.chat.timestamp.day.toString().padLeft(2, '0')}/${widget.chat.timestamp.month.toString().padLeft(2, '0')}/${widget.chat.timestamp.year}',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withOpacity(0.15), offset: Offset(0, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isDarkMode = true;
    final List<Color> solidColors = [
      const Color(0xFFE4EB9C), // Mindaro
      const Color(0xFFD6E8F4), // Dulled white/light blue
      const Color(0xFF9A3B3B), // Auburn/Dull Red
      const Color(0xFFF5EFE6), // Vanilla Cream
      const Color(0xFFAE944F), // Mustard Brown
      const Color(0xFFEDFF00), // Pantone-like yellow
    ];
    final headerColor = solidColors[widget.chat.id.hashCode % solidColors.length];
    final headerTextColor = headerColor.computeLuminance() > 0.5 ? const Color(0xFF111E26) : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: headerTextColor),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          ListView(
              controller: _scrollController,
            padding: EdgeInsets.zero,
              reverse: true,
            children: [
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 180 - 24), // Header height - overlap
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        ..._messages.reversed.map((msg) {
                if (msg.imagePath != null && msg.imagePath!.isNotEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(msg.imagePath!),
                            width: 220,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ),
                  );
                }
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                                left: msg.isUser ? 40 : 12,
                                right: msg.isUser ? 12 : 40,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                                color: msg.isUser ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                                  color: msg.isUser ? Colors.black : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
                        }).toList(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildChatHeader(context, headerColor, headerTextColor),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _footerOffsetAnimation,
                    child: SafeArea(
                      top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Container(
                              decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
                              ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                    minHeight: 48,
                                        maxHeight: 120,
                                      ),
                                      child: Scrollbar(
                                        child: TextField(
                                          controller: _chatController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Ask Clara...',
                                          hintStyle: TextStyle(color: Colors.white54)),
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                          minLines: 1,
                                          maxLines: 6,
                                          keyboardType: TextInputType.multiline,
                                          textInputAction: TextInputAction.newline,
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(width: 8),
                                  Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                width: 42,
                                height: 42,
                                  decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                  icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                                  padding: EdgeInsets.zero,
                                      onPressed: () => _sendMessage(_chatController.text),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  _Message({required this.text, required this.isUser, required this.timestamp, this.imagePath});
}

class ReportDetailPage extends StatefulWidget {
  final Report report;
  final bool isLatest;
  final String? filePath;
  const ReportDetailPage({Key? key, required this.report, required this.isLatest, this.filePath}) : super(key: key);

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> with SingleTickerProviderStateMixin {
  final TextEditingController _askController = TextEditingController();
  final List<Map<String, String>> _qaList = [];
  late AnimationController _footerController;
  late Animation<Offset> _footerOffsetAnimation;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _footerOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _footerController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _footerController.forward();
    });
  }

  @override
  void dispose() {
    _footerController.dispose();
    _askController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAsk() {
    final question = _askController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _qaList.add({'q': question, 'a': 'Answer for "$question" goes here.'});
      _askController.clear();
    });
    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper to get a header image (placeholder for now)
  Widget _buildHeader(BuildContext context, Color color, Color textColor) {
    const headerHeight = 220.0;
    return Container(
      height: headerHeight,
      color: color,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0), // For app bar that is transparent
                child: Text(
                  widget.report.patientName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.15), offset: Offset(0, 2))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              '${widget.report.date.day.toString().padLeft(2, '0')}/${widget.report.date.month.toString().padLeft(2, '0')}/${widget.report.date.year}',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 8.0, color: Colors.black.withOpacity(0.15), offset: Offset(0, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Replace _buildStatsGrid and _StatCard with a dynamic, stateless, overflow-safe version
  Widget _buildStatsGrid(BuildContext context, List<Map<String, dynamic>> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: stats.map((stat) => _StatCard(
          label: stat['label'] as String,
          value: stat['value'] as String,
          unit: stat['unit'] as String? ?? '',
          icon: stat['icon'] as IconData? ?? Icons.analytics,
          color: stat['color'] as Color? ?? Colors.blueAccent,
        )).toList(),
      ),
    );
  }

  Widget _buildQAList(BuildContext context) {
    if (_qaList.isEmpty) {
      return const SizedBox.shrink();
    }
    const isDarkMode = true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: _qaList.map((qa) {
          return Column(
            children: [
              // Question bubble
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4, left: 40),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    qa['q']!,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
              ),
              // Answer bubble
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8, right: 40),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    qa['a']!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isDarkMode = true;
    final List<Color> solidColors = [
      const Color(0xFFE4EB9C), // Mindaro
      const Color(0xFFD6E8F4), // Dulled white/light blue
      const Color(0xFF9A3B3B), // Auburn/Dull Red
      const Color(0xFFF5EFE6), // Vanilla Cream
      const Color(0xFFAE944F), // Mustard Brown
      const Color(0xFFEDFF00), // Pantone-like yellow
    ];
    final headerColor = solidColors[widget.report.id.hashCode % solidColors.length];
    final headerTextColor = headerColor.computeLuminance() > 0.5 ? const Color(0xFF111E26) : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: headerTextColor),
        title: const Text(''),
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  // The content area, starting below the header with an overlap
                  Container(
                    margin: const EdgeInsets.only(top: 220 - 24), // Header height - overlap
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24 + 16), // Overlap area + original padding
                        _ReportSection(
                          title: 'Assessment',
                          value:
                              'Based on the provided document, ${widget.report.patientName} shows signs of ${widget.report.diagnosis}. Key indicators have been analyzed to generate the following summary and metrics. Further consultation with a specialist is recommended.',
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        _buildStatsGrid(context, [
                          {'label': 'Blood Pressure', 'value': widget.report.bloodPressure, 'unit': 'mmHg', 'icon': Icons.favorite_border, 'color': Colors.pinkAccent},
                          {'label': 'Diagnosis', 'value': widget.report.diagnosis, 'unit': '', 'icon': Icons.medical_information, 'color': Colors.lightBlueAccent},
                          {'label': 'Patient Name', 'value': widget.report.patientName, 'unit': '', 'icon': Icons.person, 'color': Colors.greenAccent},
                          {'label': 'Date', 'value': '${widget.report.date.year}-${widget.report.date.month.toString().padLeft(2, '0')}-${widget.report.date.day.toString().padLeft(2, '0')}', 'unit': '', 'icon': Icons.calendar_today, 'color': Colors.orangeAccent},
                        ]),
                        const SizedBox(height: 16),
                        _buildQAList(context),
                        const SizedBox(height: 120), // Padding for floating bar
                      ],
                    ),
                  ),
                  // The header itself
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeader(context, headerColor, headerTextColor),
                  ),
                ],
              ),
            ],
          ),
          // Floating ask bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _footerOffsetAnimation,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.2),
                            width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                    maxHeight: 120,
                                  ),
                                  child: Scrollbar(
                                    child: TextField(
                                      controller: _askController,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Ask about this report...',
                                        hintStyle: TextStyle(color: Colors.white54),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                      ),
                                      minLines: 1,
                                      maxLines: 6,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                                  padding: EdgeInsets.zero,
                                  onPressed: _onAsk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final String value;
  final bool isDarkMode;
  const _ReportSection({required this.title, required this.value, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color.withOpacity(0.15);
    final textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              Icon(icon, color: textColor, size: 24),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(unit, style: TextStyle(color: textColor.withOpacity(0.8))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}