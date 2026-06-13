import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const CivicReporterApp());
}

class CivicReporterApp extends StatelessWidget {
  const CivicReporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Reporter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5276),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5276),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 60,
                    color: Color(0xFF1A5276),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Civic Reporter',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fix Your City',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 60),
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    if (_phoneController.text.length == 10) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OTPScreen(phone: _phoneController.text),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5276),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.location_on,
                      size: 45, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5276),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number to continue',
                style:
                    TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A5276),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5276),
                      ),
                    ),
                  ),
                  hintText: '9876543210',
                  hintStyle:
                      const TextStyle(color: Colors.grey),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A5276), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Having trouble? Contact Support',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  void _onOTPComplete() {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const HomeDashboard()),
      );
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color(0xFF1A5276)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5276),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to +91 ${widget.phone}',
                style: const TextStyle(
                    fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A5276),
                              width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1]
                              .requestFocus();
                        }
                        if (index == 5 &&
                            value.isNotEmpty) {
                          _onOTPComplete();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onOTPComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Verify OTP',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Resend OTP',
                    style:
                        TextStyle(color: Color(0xFF1A5276)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() =>
      _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _issues = [
    {
      'id': '#WD24-001',
      'type': 'Pothole',
      'location': 'Anna Nagar, Chennai',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'icon': Icons.warning_rounded,
      'iconColor': Colors.orange,
      'time': '2 hours ago',
    },
    {
      'id': '#WD24-002',
      'type': 'Broken Streetlight',
      'location': 'T Nagar, Chennai',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.lightbulb_outline,
      'iconColor': Colors.blue,
      'time': '5 hours ago',
    },
    {
      'id': '#WD24-003',
      'type': 'Open Drain',
      'location': 'Adyar, Chennai',
      'status': 'Resolved',
      'statusColor': Colors.green,
      'icon': Icons.water_damage,
      'iconColor': Colors.green,
      'time': '1 day ago',
    },
    {
      'id': '#WD24-004',
      'type': 'Garbage Dump',
      'location': 'Velachery, Chennai',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.delete_outline,
      'iconColor': Colors.blue,
      'time': '2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHome(),
      const MyReportsScreen(),
      const MapScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) =>
            setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1A5276),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'My Reports'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Civic Reporter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ward 42 — Chennai Corporation',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A5276),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning, Kavin! 👋',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('12', 'Total\nReported'),
                      const SizedBox(width: 12),
                      _statCard('8', 'In\nProgress'),
                      const SizedBox(width: 12),
                      _statCard('4', 'Resolved'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5276),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _quickReportBtn(Icons.warning_rounded,
                          'Pothole', Colors.orange),
                      _quickReportBtn(
                          Icons.lightbulb_outline,
                          'Streetlight',
                          Colors.blue),
                      _quickReportBtn(Icons.water_damage,
                          'Drain', Colors.teal),
                      _quickReportBtn(Icons.delete_outline,
                          'Garbage', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Reports',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A5276),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                              color: Color(0xFF2E86C1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._issues
                      .map((issue) => _issueCard(issue))
                      .toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ReportIssueScreen()),
          );
        },
        backgroundColor: const Color(0xFF1A5276),
        icon: const Icon(Icons.camera_alt,
            color: Colors.white),
        label: const Text(
          'Report Issue',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _quickReportBtn(
      IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _issueCard(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (issue['iconColor'] as Color)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(issue['icon'] as IconData,
                color: issue['iconColor'] as Color,
                size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(issue['type'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A5276))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (issue['statusColor'] as Color)
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(issue['status'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              color: issue['statusColor']
                                  as Color,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(issue['location'] as String,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text('${issue['id']} • ${issue['time']}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() =>
      _ReportIssueScreenState();
}

class _ReportIssueScreenState
    extends State<ReportIssueScreen> {
  String? _selectedCategory;
  String? _selectedSeverity;
  final TextEditingController _descController =
      TextEditingController();
  bool _isSubmitting = false;
  bool _photoAdded = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Pothole',
      'icon': Icons.warning_rounded,
      'color': Colors.orange
    },
    {
      'name': 'Streetlight',
      'icon': Icons.lightbulb_outline,
      'color': Colors.blue
    },
    {
      'name': 'Open Drain',
      'icon': Icons.water_damage,
      'color': Colors.teal
    },
    {
      'name': 'Garbage',
      'icon': Icons.delete_outline,
      'color': Colors.red
    },
    {
      'name': 'Road Damage',
      'icon': Icons.construction,
      'color': Colors.brown
    },
    {
      'name': 'Water Leak',
      'icon': Icons.water_drop,
      'color': Colors.cyan
    },
  ];

  final List<String> _severities = [
    'Low',
    'Medium',
    'High',
    'Critical'
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isSubmitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SubmissionSuccessScreen(
              category: _selectedCategory!),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report an Issue',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _photoAdded = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Photo added! Camera coming with Firebase'),
                    backgroundColor: Color(0xFF1A5276),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: _photoAdded
                      ? const Color(0xFF1A5276)
                          .withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _photoAdded
                        ? const Color(0xFF1A5276)
                        : Colors.grey.shade300,
                    width: _photoAdded ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _photoAdded
                          ? Icons.check_circle
                          : Icons.camera_alt,
                      size: 48,
                      color: _photoAdded
                          ? const Color(0xFF1A5276)
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _photoAdded
                          ? 'Photo Added ✓'
                          : 'Tap to take a photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: _photoAdded
                            ? const Color(0xFF1A5276)
                            : Colors.grey,
                        fontWeight: _photoAdded
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (!_photoAdded)
                      const Text('or choose from gallery',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Issue Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected =
                    _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedCategory = cat['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (cat['color'] as Color)
                              .withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? cat['color'] as Color
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 28),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? cat['color'] as Color
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Severity Level',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            Row(
              children: _severities.map((s) {
                final isSelected = _selectedSeverity == s;
                Color chipColor = Colors.green;
                if (s == 'Medium') chipColor = Colors.orange;
                if (s == 'High')
                  chipColor = Colors.deepOrange;
                if (s == 'Critical') chipColor = Colors.red;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _selectedSeverity = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.15)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? chipColor
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(s,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? chipColor
                                  : Colors.grey)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Location',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF1A5276), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('GPS Location Detected',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A5276))),
                        Text('Anna Nagar, Ward 42, Chennai',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey)),
                        Text('13.0827° N, 80.2707° E',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Auto',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description (Optional)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF1A5276), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 10),
                          Text('Submit Report',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SubmissionSuccessScreen extends StatelessWidget {
  final String category;
  const SubmissionSuccessScreen(
      {super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    size: 64, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text('Report Submitted!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A5276))),
              const SizedBox(height: 8),
              Text('$category report sent to Ward 42 office',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text('Tracking ID',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('#WD24-00821',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5276),
                            letterSpacing: 2)),
                    SizedBox(height: 8),
                    Text(
                        'Expected resolution: 3-5 working days',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const HomeDashboard()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const ReportIssueScreen()),
                  );
                },
                child: const Text('Report Another Issue',
                    style: TextStyle(
                        color: Color(0xFF2E86C1))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() =>
      _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Submitted',
    'In Progress',
    'Resolved',
    'Rejected'
  ];

  final List<Map<String, dynamic>> _allReports = [
    {
      'id': '#WD24-001',
      'type': 'Pothole',
      'location': 'Anna Nagar, Chennai',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'icon': Icons.warning_rounded,
      'iconColor': Colors.orange,
      'date': '12 May 2026',
      'time': '2 hours ago',
      'ward': 'Ward 42',
      'description':
          'Large pothole near bus stop, dangerous at night',
    },
    {
      'id': '#WD24-002',
      'type': 'Broken Streetlight',
      'location': 'T Nagar, Chennai',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.lightbulb_outline,
      'iconColor': Colors.blue,
      'date': '12 May 2026',
      'time': '5 hours ago',
      'ward': 'Ward 42',
      'description': 'Streetlight not working for 3 days',
    },
    {
      'id': '#WD24-003',
      'type': 'Open Drain',
      'location': 'Adyar, Chennai',
      'status': 'Resolved',
      'statusColor': Colors.green,
      'icon': Icons.water_damage,
      'iconColor': Colors.green,
      'date': '10 May 2026',
      'time': '1 day ago',
      'ward': 'Ward 41',
      'description': 'Open drain causing mosquito breeding',
    },
    {
      'id': '#WD24-004',
      'type': 'Garbage Dump',
      'location': 'Velachery, Chennai',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.delete_outline,
      'iconColor': Colors.red,
      'date': '11 May 2026',
      'time': '2 days ago',
      'ward': 'Ward 43',
      'description': 'Garbage not collected for a week',
    },
    {
      'id': '#WD24-005',
      'type': 'Road Damage',
      'location': 'Tambaram, Chennai',
      'status': 'Rejected',
      'statusColor': Colors.red,
      'icon': Icons.construction,
      'iconColor': Colors.brown,
      'date': '09 May 2026',
      'time': '3 days ago',
      'ward': 'Ward 44',
      'description': 'Outside ward jurisdiction',
    },
    {
      'id': '#WD24-006',
      'type': 'Water Leak',
      'location': 'Kodambakkam, Chennai',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'icon': Icons.water_drop,
      'iconColor': Colors.cyan,
      'date': '08 May 2026',
      'time': '4 days ago',
      'ward': 'Ward 42',
      'description': 'Water pipe leaking on main road',
    },
  ];

  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedFilter == 'All') return _allReports;
    return _allReports
        .where((r) => r['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Reports',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A5276),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _miniStat('6', 'Total', Colors.white),
                _miniStat('2', 'In Progress',
                    Colors.orange.shade200),
                _miniStat('1', 'Resolved',
                    Colors.green.shade200),
                _miniStat(
                    '1', 'Rejected', Colors.red.shade200),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected =
                    _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A5276)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A5276)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(filter,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filteredReports.length} report${_filteredReports.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter reports',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report =
                          _filteredReports[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailScreen(
                                      report: report),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 10,
                                  offset:
                                      const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (report[
                                              'iconColor']
                                          as Color)
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: Icon(
                                    report['icon']
                                        as IconData,
                                    color: report[
                                            'iconColor']
                                        as Color,
                                    size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Text(
                                            report['type']
                                                as String,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize:
                                                    14,
                                                color: Color(
                                                    0xFF1A5276))),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 3),
                                          decoration: BoxDecoration(
                                              color: (report['statusColor']
                                                      as Color)
                                                  .withOpacity(
                                                      0.1),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          20)),
                                          child: Text(
                                              report[
                                                      'status']
                                                  as String,
                                              style: TextStyle(
                                                  fontSize:
                                                      11,
                                                  color: report[
                                                          'statusColor']
                                                      as Color,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: 4),
                                    Text(
                                        report['location']
                                            as String,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.grey)),
                                    const SizedBox(
                                        height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Text(
                                            report['id']
                                                as String,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .grey)),
                                        Text(
                                            report['time']
                                                as String,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String number, String label, Color color) {
    return Column(
      children: [
        Text(number,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  const ReportDetailScreen(
      {super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> timeline = [
      {
        'step': 'Submitted',
        'time': '12 May 2026, 9:00 AM',
        'note': 'Report received by system',
        'done': true,
      },
      {
        'step': 'Acknowledged',
        'time': '12 May 2026, 11:30 AM',
        'note': 'Ward officer acknowledged the complaint',
        'done': report['status'] != 'Submitted',
      },
      {
        'step': 'In Progress',
        'time': report['status'] == 'In Progress' ||
                report['status'] == 'Resolved'
            ? '12 May 2026, 2:00 PM'
            : 'Pending',
        'note': 'Field crew dispatched to location',
        'done': report['status'] == 'In Progress' ||
            report['status'] == 'Resolved',
      },
      {
        'step': 'Resolved',
        'time': report['status'] == 'Resolved'
            ? '13 May 2026, 10:00 AM'
            : 'Pending',
        'note': 'Issue fixed and closed',
        'done': report['status'] == 'Resolved',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(report['id'] as String,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (report['iconColor']
                                      as Color)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(
                                report['icon'] as IconData,
                                color: report['iconColor']
                                    as Color,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(report['type'] as String,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF1A5276))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (report['statusColor']
                                  as Color)
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                            report['status'] as String,
                            style: TextStyle(
                                fontSize: 13,
                                color: report['statusColor']
                                    as Color,
                                fontWeight:
                                    FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(Icons.location_on,
                      report['location'] as String),
                  _detailRow(Icons.apartment,
                      report['ward'] as String),
                  _detailRow(Icons.calendar_today,
                      report['date'] as String),
                  _detailRow(Icons.description,
                      report['description'] as String),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Status Timeline',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                children:
                    timeline.asMap().entries.map((e) {
                  final i = e.key;
                  final step = e.value;
                  final isLast = i == timeline.length - 1;
                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: step['done'] as bool
                                  ? Colors.green
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                step['done'] as bool
                                    ? Icons.check
                                    : Icons.circle,
                                color: step['done'] as bool
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 14),
                          ),
                          if (!isLast)
                            Container(
                                width: 2,
                                height: 48,
                                color: step['done'] as bool
                                    ? Colors.green
                                        .withOpacity(0.3)
                                    : Colors.grey.shade200),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              bottom: 16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(step['step'] as String,
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14,
                                      color: step['done']
                                              as bool
                                          ? const Color(
                                              0xFF1A5276)
                                          : Colors.grey)),
                              Text(step['time'] as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                              Text(step['note'] as String,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (report['status'] != 'Resolved' &&
                report['status'] != 'Rejected')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Escalation sent to higher authority!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.warning,
                      color: Colors.red),
                  label: const Text('Escalate Issue',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedLayer = 'All Issues';
  Map<String, dynamic>? _selectedPin;

  final List<Map<String, dynamic>> _mapPins = [
    {
      'id': '#WD24-001',
      'type': 'Pothole',
      'location': 'Anna Nagar',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'icon': Icons.warning_rounded,
      'color': Colors.orange,
      'x': 0.25,
      'y': 0.35,
    },
    {
      'id': '#WD24-002',
      'type': 'Streetlight',
      'location': 'T Nagar',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.lightbulb_outline,
      'color': Colors.blue,
      'x': 0.55,
      'y': 0.45,
    },
    {
      'id': '#WD24-003',
      'type': 'Open Drain',
      'location': 'Adyar',
      'status': 'Resolved',
      'statusColor': Colors.green,
      'icon': Icons.water_damage,
      'color': Colors.green,
      'x': 0.70,
      'y': 0.65,
    },
    {
      'id': '#WD24-004',
      'type': 'Garbage',
      'location': 'Velachery',
      'status': 'Submitted',
      'statusColor': Colors.blue,
      'icon': Icons.delete_outline,
      'color': Colors.red,
      'x': 0.40,
      'y': 0.70,
    },
    {
      'id': '#WD24-005',
      'type': 'Road Damage',
      'location': 'Tambaram',
      'status': 'Rejected',
      'statusColor': Colors.red,
      'icon': Icons.construction,
      'color': Colors.brown,
      'x': 0.20,
      'y': 0.75,
    },
    {
      'id': '#WD24-006',
      'type': 'Water Leak',
      'location': 'Kodambakkam',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'icon': Icons.water_drop,
      'color': Colors.cyan,
      'x': 0.65,
      'y': 0.30,
    },
  ];

  final List<String> _layers = [
    'All Issues',
    'My Ward',
    'My Reports'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Area Map',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location,
                color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Centering on your location...'),
                  backgroundColor: Color(0xFF1A5276),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A5276),
            padding: const EdgeInsets.only(
                left: 16, right: 16, bottom: 16),
            child: Row(
              children: _layers.map((layer) {
                final isSelected = _selectedLayer == layer;
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedLayer = layer),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(layer,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1A5276)
                                : Colors.white)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE8F5E9),
                        Color(0xFFE3F2FD),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: MapGridPainter(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map,
                            size: 40,
                            color: Color(0xFF1A5276)),
                        SizedBox(height: 8),
                        Text('Ward 42 — Chennai',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5276))),
                        Text(
                            'Google Maps loads after Firebase setup',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                ..._mapPins.map((pin) {
                  return Positioned(
                    left: pin['x'] *
                        (MediaQuery.of(context).size.width -
                            32),
                    top: pin['y'] * 300,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedPin = pin),
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (pin['color'] as Color)
                                  .withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white,
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: (pin['color']
                                          as Color)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                  offset:
                                      const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                                pin['icon'] as IconData,
                                color: Colors.white,
                                size: 18),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: pin['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                if (_selectedPin != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _selectedPin = null),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (_selectedPin![
                                            'color']
                                        as Color)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                              ),
                              child: Icon(
                                  _selectedPin!['icon']
                                      as IconData,
                                  color: _selectedPin![
                                      'color'] as Color,
                                  size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _selectedPin!['type']
                                          as String,
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(
                                              0xFF1A5276))),
                                  Text(
                                      _selectedPin![
                                              'location']
                                          as String,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey)),
                                  Text(
                                      _selectedPin!['id']
                                          as String,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5),
                              decoration: BoxDecoration(
                                color: (_selectedPin![
                                            'statusColor']
                                        as Color)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                              ),
                              child: Text(
                                  _selectedPin!['status']
                                      as String,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _selectedPin![
                                              'statusColor']
                                          as Color,
                                      fontWeight:
                                          FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: Column(
                    children: [
                      _legendItem(
                          Colors.orange, 'In Progress'),
                      const SizedBox(height: 6),
                      _legendItem(
                          Colors.blue, 'Submitted'),
                      const SizedBox(height: 6),
                      _legendItem(
                          Colors.green, 'Resolved'),
                      const SizedBox(height: 6),
                      _legendItem(Colors.red, 'Rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _mapStat('6', 'Total Issues',
                    const Color(0xFF1A5276)),
                _mapStat(
                    '2', 'In Progress', Colors.orange),
                _mapStat('1', 'Resolved', Colors.green),
                _mapStat('1', 'Rejected', Colors.red),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ReportIssueScreen()),
          );
        },
        backgroundColor: const Color(0xFF1A5276),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _mapStat(
      String number, String label, Color color) {
    return Column(
      children: [
        Text(number,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0),
        Offset(size.width * 0.75, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1A5276),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10)
                ],
              ),
              child: const Icon(Icons.person,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Kavin',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const Text('+91 98765 43210',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🥇 Gold Civic Reporter',
                  style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statBox('12', 'Reports\nFiled'),
                const SizedBox(width: 12),
                _statBox('8', 'Issues\nResolved'),
                const SizedBox(width: 12),
                _statBox('4', 'Badges\nEarned'),
              ],
            ),
            const SizedBox(height: 24),
            _menuItem(Icons.list_alt, 'My Reports', () {}),
            _menuItem(Icons.notifications_outlined,
                'Notifications', () {}),
            _menuItem(Icons.shield_outlined, 'Officer Portal', () {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => const OfficerLoginScreen()));
}),
            _menuItem(Icons.privacy_tip_outlined,
                'Privacy Policy', () {}),
            _menuItem(
                Icons.star_outline, 'Rate the App', () {}),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout,
                    color: Colors.red),
                label: const Text('Logout',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Text(number,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:
            Icon(icon, color: const Color(0xFF1A5276)),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Issue In Progress',
      'body':
          'Your Pothole report #WD24-001 is now being worked on by the field crew.',
      'time': '2 hours ago',
      'icon': Icons.construction,
      'color': Colors.orange,
      'read': false,
    },
    {
      'title': 'Report Acknowledged',
      'body':
          'Ward officer has acknowledged your Streetlight report #WD24-002.',
      'time': '5 hours ago',
      'icon': Icons.check_circle_outline,
      'color': Colors.blue,
      'read': false,
    },
    {
      'title': 'Issue Resolved! ✅',
      'body':
          'Your Open Drain report #WD24-003 has been resolved. Please verify.',
      'time': '1 day ago',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'read': true,
    },
    {
      'title': 'Report Rejected',
      'body':
          'Your Road Damage report #WD24-005 was rejected. Reason: Outside ward jurisdiction.',
      'time': '3 days ago',
      'icon': Icons.cancel_outlined,
      'color': Colors.red,
      'read': true,
    },
    {
      'title': 'New Issue Nearby',
      'body':
          'A new Garbage Dump issue was reported 200m from your location in Anna Nagar.',
      'time': '4 days ago',
      'icon': Icons.location_on,
      'color': Colors.purple,
      'read': true,
    },
    {
      'title': 'SLA Reminder',
      'body':
          'Your report #WD24-002 has not been resolved in 3 days. You can escalate now.',
      'time': '5 days ago',
      'icon': Icons.alarm,
      'color': Colors.deepOrange,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['read'] = true;
                }
              });
            },
            child: const Text('Mark all read',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A5276),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final isUnread =
                    !(notif['read'] as bool);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _notifications[index]['read'] =
                          true;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: isUnread
                          ? Border.all(
                              color: (notif['color']
                                      as Color)
                                  .withOpacity(0.3),
                              width: 1.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (notif['color']
                                    as Color)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Icon(
                              notif['icon'] as IconData,
                              color:
                                  notif['color'] as Color,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif['title']
                                          as String,
                                      style: TextStyle(
                                        fontWeight: isUnread
                                            ? FontWeight
                                                .bold
                                            : FontWeight
                                                .w500,
                                        fontSize: 13,
                                        color: const Color(
                                            0xFF1A5276),
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            notif['color']
                                                as Color,
                                        shape:
                                            BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['time'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() =>
      _OfficerLoginScreenState();
}

class _OfficerLoginScreenState
    extends State<OfficerLoginScreen> {
  final TextEditingController _idController =
      TextEditingController();
  final TextEditingController _passController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _login() {
    if (_idController.text.isEmpty ||
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Employee ID and Password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const OfficerDashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5276),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.shield_outlined,
                  size: 70, color: Colors.white),
              const SizedBox(height: 16),
              const Text('Ward Officer Portal',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text('Chennai Municipal Corporation',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70)),
              const SizedBox(height: 48),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text('Employee ID',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A5276))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: 'e.g. CMC-WD42-001',
                        prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF1A5276)),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF1A5276),
                                width: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Password',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A5276))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passController,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF1A5276)),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey),
                          onPressed: () => setState(() =>
                              _obscurePass = !_obscurePass),
                        ),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF1A5276),
                                width: 2)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: Color(0xFF1A5276))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A5276),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2)
                            : const Text('Login as Officer',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    '← Back to Citizen App',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() =>
      _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState
    extends State<OfficerDashboardScreen> {
  String _selectedTab = 'New';
  final List<String> _tabs = [
    'New',
    'In Progress',
    'Resolved',
    'Escalated'
  ];

  final List<Map<String, dynamic>> _queue = [
    {
      'id': '#WD24-007',
      'type': 'Pothole',
      'location': 'Anna Nagar Main Road',
      'status': 'New',
      'priority': 'High',
      'priorityColor': Colors.red,
      'icon': Icons.warning_rounded,
      'iconColor': Colors.orange,
      'submittedBy': 'Citizen #1042',
      'time': '30 min ago',
      'slaHours': 72,
      'elapsedHours': 1,
    },
    {
      'id': '#WD24-008',
      'type': 'Broken Streetlight',
      'location': '2nd Avenue, Anna Nagar',
      'status': 'New',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'icon': Icons.lightbulb_outline,
      'iconColor': Colors.blue,
      'submittedBy': 'Citizen #2031',
      'time': '2 hours ago',
      'slaHours': 48,
      'elapsedHours': 2,
    },
    {
      'id': '#WD24-009',
      'type': 'Open Drain',
      'location': 'Nehru Park Road',
      'status': 'New',
      'priority': 'Critical',
      'priorityColor': Colors.red,
      'icon': Icons.water_damage,
      'iconColor': Colors.teal,
      'submittedBy': 'Citizen #3015',
      'time': '4 hours ago',
      'slaHours': 24,
      'elapsedHours': 4,
    },
    {
      'id': '#WD24-001',
      'type': 'Pothole',
      'location': 'Anna Nagar, Chennai',
      'status': 'In Progress',
      'priority': 'High',
      'priorityColor': Colors.red,
      'icon': Icons.warning_rounded,
      'iconColor': Colors.orange,
      'submittedBy': 'Kavin',
      'time': '2 hours ago',
      'slaHours': 72,
      'elapsedHours': 26,
    },
    {
      'id': '#WD24-006',
      'type': 'Water Leak',
      'location': 'Kodambakkam',
      'status': 'In Progress',
      'priority': 'Medium',
      'priorityColor': Colors.orange,
      'icon': Icons.water_drop,
      'iconColor': Colors.cyan,
      'submittedBy': 'Citizen #4022',
      'time': '4 days ago',
      'slaHours': 48,
      'elapsedHours': 96,
    },
    {
      'id': '#WD24-003',
      'type': 'Open Drain',
      'location': 'Adyar, Chennai',
      'status': 'Resolved',
      'priority': 'Low',
      'priorityColor': Colors.green,
      'icon': Icons.water_damage,
      'iconColor': Colors.green,
      'submittedBy': 'Kavin',
      'time': '1 day ago',
      'slaHours': 72,
      'elapsedHours': 24,
    },
    {
      'id': '#WD24-010',
      'type': 'Garbage Dump',
      'location': 'Bus Stand Area',
      'status': 'Escalated',
      'priority': 'Critical',
      'priorityColor': Colors.red,
      'icon': Icons.delete_outline,
      'iconColor': Colors.red,
      'submittedBy': 'Citizen #5001',
      'time': '8 days ago',
      'slaHours': 48,
      'elapsedHours': 192,
    },
  ];

  List<Map<String, dynamic>> get _filteredQueue {
    return _queue
        .where((q) => q['status'] == _selectedTab)
        .toList();
  }

  int _countByStatus(String status) =>
      _queue.where((q) => q['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Officer Dashboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text('Ward 42 — CMC-WD42-001',
                style: TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart,
                color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const WardStatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A5276),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text('Good Morning, Officer! 👮',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _officerStat(
                        '${_countByStatus('New')}',
                        'New',
                        Colors.red.shade200),
                    const SizedBox(width: 10),
                    _officerStat(
                        '${_countByStatus('In Progress')}',
                        'In Progress',
                        Colors.orange.shade200),
                    const SizedBox(width: 10),
                    _officerStat(
                        '${_countByStatus('Resolved')}',
                        'Resolved',
                        Colors.green.shade200),
                    const SizedBox(width: 10),
                    _officerStat(
                        '${_countByStatus('Escalated')}',
                        'Escalated',
                        Colors.pink.shade200),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = _selectedTab == tab;
                final count = _countByStatus(tab);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedTab = tab),
                  child: Container(
                    margin:
                        const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A5276)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A5276)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text('$tab ($count)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredQueue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No $selectedTabissues',
                            style: TextStyle(
                                fontSize: 16,
                                color:
                                    Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount: _filteredQueue.length,
                    itemBuilder: (context, index) {
                      final issue =
                          _filteredQueue[index];
                      final elapsed =
                          issue['elapsedHours'] as int;
                      final sla =
                          issue['slaHours'] as int;
                      final slaPercent =
                          (elapsed / sla).clamp(0.0, 1.0);
                      final isOverdue = elapsed > sla;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OfficerActionScreen(
                                      issue: issue),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: isOverdue
                                ? Border.all(
                                    color: Colors.red
                                        .withOpacity(0.5),
                                    width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 10,
                                  offset:
                                      const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration:
                                        BoxDecoration(
                                      color: (issue[
                                                  'iconColor']
                                              as Color)
                                          .withOpacity(
                                              0.1),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  10),
                                    ),
                                    child: Icon(
                                        issue['icon']
                                            as IconData,
                                        color: issue[
                                                'iconColor']
                                            as Color,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Text(
                                                issue['type']
                                                    as String,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                    fontSize:
                                                        14,
                                                    color: Color(
                                                        0xFF1A5276))),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal:
                                                      8,
                                                  vertical:
                                                      3),
                                              decoration: BoxDecoration(
                                                  color: (issue['priorityColor']
                                                          as Color)
                                                      .withOpacity(
                                                          0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8)),
                                              child: Text(
                                                  issue['priority']
                                                      as String,
                                                  style: TextStyle(
                                                      fontSize:
                                                          11,
                                                      color: issue[
                                                              'priorityColor']
                                                          as Color,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold)),
                                            ),
                                          ],
                                        ),
                                        Text(
                                            issue['location']
                                                as String,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Colors
                                                        .grey)),
                                        Text(
                                            '${issue['id']} • ${issue['submittedBy']} • ${issue['time']}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color:
                                                    Colors
                                                        .grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [
                                  Text(
                                      isOverdue
                                          ? '⚠️ SLA Breached! ${elapsed - sla}h overdue'
                                          : 'SLA: ${elapsed}h / ${sla}h',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isOverdue
                                              ? Colors.red
                                              : Colors
                                                  .grey,
                                          fontWeight: isOverdue
                                              ? FontWeight
                                                  .bold
                                              : FontWeight
                                                  .normal)),
                                  const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 18),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                        4),
                                child:
                                    LinearProgressIndicator(
                                  value: slaPercent,
                                  backgroundColor:
                                      Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation(
                                    isOverdue
                                        ? Colors.red
                                        : slaPercent > 0.7
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String get selectedTabissues => '$_selectedTab ';

  Widget _officerStat(
      String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(number,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class OfficerActionScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  const OfficerActionScreen(
      {super.key, required this.issue});

  @override
  State<OfficerActionScreen> createState() =>
      _OfficerActionScreenState();
}

class _OfficerActionScreenState
    extends State<OfficerActionScreen> {
  String _selectedStatus = '';
  String _selectedCrew = '';
  final TextEditingController _noteController =
      TextEditingController();
  bool _isUpdating = false;

  final List<String> _statuses = [
    'Acknowledged',
    'In Progress',
    'Resolved',
    'Rejected'
  ];

  final List<String> _crews = [
    'Crew A — Roads',
    'Crew B — Drainage',
    'Crew C — Electrical',
    'Crew D — Sanitation',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue['status'] as String;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _updateStatus() {
    setState(() => _isUpdating = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Status updated to $_selectedStatus! Citizen notified.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.issue['id'] as String,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (widget.issue['iconColor']
                              as Color)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                        widget.issue['icon'] as IconData,
                        color: widget.issue['iconColor']
                            as Color,
                        size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                            widget.issue['type'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1A5276))),
                        Text(
                            widget.issue['location']
                                as String,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey)),
                        Text(
                            'Reported by: ${widget.issue['submittedBy']} • ${widget.issue['time']}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Update Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final s = _statuses[index];
                final isSelected = _selectedStatus == s;
                Color sColor = Colors.blue;
                if (s == 'In Progress')
                  sColor = Colors.orange;
                if (s == 'Resolved') sColor = Colors.green;
                if (s == 'Rejected') sColor = Colors.red;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedStatus = s),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sColor.withOpacity(0.15)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected
                              ? sColor
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? sColor
                                  : Colors.grey)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Assign Field Crew',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            ...(_crews.map((crew) {
              final isSelected = _selectedCrew == crew;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCrew = crew),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A5276)
                            .withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A5276)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group,
                          color: isSelected
                              ? const Color(0xFF1A5276)
                              : Colors.grey,
                          size: 20),
                      const SizedBox(width: 12),
                      Text(crew,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1A5276)
                                  : Colors.grey.shade700)),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF1A5276),
                            size: 18),
                    ],
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 24),
            const Text('Officer Note',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Add a note for the citizen or field crew...',
                hintStyle: const TextStyle(
                    color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A5276),
                        width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    _isUpdating ? null : _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2)
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 10),
                          Text('Update & Notify Citizen',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class WardStatsScreen extends StatelessWidget {
  const WardStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categoryStats = [
      {
        'name': 'Potholes',
        'total': 24,
        'resolved': 18,
        'color': Colors.orange
      },
      {
        'name': 'Streetlights',
        'total': 15,
        'resolved': 12,
        'color': Colors.blue
      },
      {
        'name': 'Drains',
        'total': 10,
        'resolved': 7,
        'color': Colors.teal
      },
      {
        'name': 'Garbage',
        'total': 20,
        'resolved': 14,
        'color': Colors.red
      },
      {
        'name': 'Roads',
        'total': 8,
        'resolved': 5,
        'color': Colors.brown
      },
      {
        'name': 'Water',
        'total': 6,
        'resolved': 3,
        'color': Colors.cyan
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ward Statistics',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _bigStat('83', 'Total\nReports',
                    const Color(0xFF1A5276)),
                const SizedBox(width: 12),
                _bigStat(
                    '59', 'Resolved', Colors.green),
                const SizedBox(width: 12),
                _bigStat('24', 'Pending', Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('Resolution Rate',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A5276))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 0.71,
                              strokeWidth: 10,
                              backgroundColor:
                                  Colors.grey.shade200,
                              valueColor:
                                  const AlwaysStoppedAnimation(
                                      Colors.green),
                            ),
                            const Text('71%',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _legendRow(
                              Colors.green, 'Resolved: 59'),
                          const SizedBox(height: 8),
                          _legendRow(
                              Colors.orange, 'Pending: 18'),
                          const SizedBox(height: 8),
                          _legendRow(
                              Colors.red, 'Escalated: 3'),
                          const SizedBox(height: 8),
                          _legendRow(
                              Colors.grey, 'Rejected: 3'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('By Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            ...categoryStats.map((cat) {
              final rate =
                  (cat['resolved'] / cat['total'])
                      .toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color:
                            Colors.black.withOpacity(0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A5276))),
                        Text(
                            '${cat['resolved']}/${cat['total']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: cat['color']
                                    as Color,
                                fontWeight:
                                    FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rate,
                        backgroundColor:
                            Colors.grey.shade100,
                        valueColor:
                            AlwaysStoppedAnimation(
                                cat['color'] as Color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('Performance Metrics',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A5276))),
                  const SizedBox(height: 16),
                  _metricRow('Avg Resolution Time',
                      '2.3 days', Colors.green),
                  _metricRow(
                      'SLA Compliance', '87%', Colors.blue),
                  _metricRow('Citizen Satisfaction',
                      '4.2 / 5.0', Colors.amber),
                  _metricRow('Reports This Month',
                      '28', const Color(0xFF1A5276)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(
      String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(number,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _metricRow(
      String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}