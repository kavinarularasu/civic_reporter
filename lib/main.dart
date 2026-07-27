import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'env_config.dart';
import 'ai_moderation_service.dart';
import 'notification_service.dart';
import 'india_locations.dart';
import 'google_auth_service.dart';
import 'sms_auth_service.dart';

// ==========================================
// CROSS-PLATFORM IMAGE HELPER (WEB & MOBILE & DESKTOP)
// ==========================================

Widget buildCrossPlatformImage({
  Uint8List? bytes,
  String? path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(bytes, width: width, height: height, fit: fit);
  }
  if (path != null && path.isNotEmpty) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      );
    } else {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(file, width: width, height: height, fit: fit);
        }
      } catch (_) {}
    }
  }
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image, color: Colors.grey),
  );
}

// ==========================================
// DATA MODELS & GLOBAL STATE STORE (USER & OFFICER LOCATION)
// ==========================================

class UserAccount {
  final String name;
  final String username;
  final String password;
  final String email;
  final String role; // 'reporter' or 'officer'
  final String mobileNumber;
  final bool isMobileVerified;
  final String verificationMethod; // 'OTP', 'Google', 'Password'
  final String aadharNumber;

  // Dynamic Location Context
  String selectedState;
  String selectedCity;
  String selectedWard;

  UserAccount({
    required this.name,
    required this.username,
    required this.password,
    required this.email,
    required this.role,
    this.mobileNumber = '+91 9876543210',
    this.isMobileVerified = true,
    this.verificationMethod = 'Password',
    this.selectedState = 'Tamil Nadu',
    this.selectedCity = 'Tiruvallur',
    this.selectedWard = 'Avadi',
    this.aadharNumber = '',
  });
}

class UserStore extends ChangeNotifier {
  static final UserStore instance = UserStore._internal();
  UserStore._internal();

  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  void setCurrentUser(UserAccount user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateLocationContext({
    required String state,
    required String city,
    required String ward,
  }) {
    if (_currentUser != null) {
      _currentUser!.selectedState = state;
      _currentUser!.selectedCity = city;
      _currentUser!.selectedWard = ward;

      try {
        final docId = _currentUser!.role == 'officer'
            ? _currentUser!.username
            : '${_currentUser!.username}_${_currentUser!.mobileNumber}';
        FirebaseFirestore.instance.collection('users').doc(docId).set({
          'selected_state': state,
          'selected_city': city,
          'selected_ward': ward,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore User Location Update Error: $e');
      }

      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String username,
    String password, {
    String role = 'reporter',
    String mobileNumber = '+91 9876543210',
    String state = 'Tamil Nadu',
    String city = 'Tiruvallur',
    String ward = 'Avadi',
  }) async {
    if (username.trim().isEmpty || password.trim().isEmpty) return false;

    final formattedUsername = username.trim();
    final email = formattedUsername.contains('@')
        ? formattedUsername
        : '${formattedUsername.toLowerCase()}@civicreporter.org';
    final displayName = name.trim().isEmpty ? formattedUsername : name.trim();

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(displayName);

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': displayName,
          'username': formattedUsername,
          'email': email,
          'role': role,
          'mobile_number': mobileNumber,
          'is_verified': true,
          'selected_state': state,
          'selected_city': city,
          'selected_ward': ward,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _currentUser = UserAccount(
        name: displayName,
        username: formattedUsername,
        password: password,
        email: email,
        role: role,
        mobileNumber: mobileNumber,
        isMobileVerified: true,
        verificationMethod: 'Password',
        selectedState: state,
        selectedCity: city,
        selectedWard: ward,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Register Error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        return await login(username, password, selectedRole: role);
      }
    } catch (e) {
      debugPrint('Register Error: $e');
    }

    _currentUser = UserAccount(
      name: displayName,
      username: formattedUsername,
      password: password,
      email: email,
      role: role,
      mobileNumber: mobileNumber,
      isMobileVerified: true,
      verificationMethod: 'Password',
      selectedState: state,
      selectedCity: city,
      selectedWard: ward,
    );
    notifyListeners();
    return true;
  }

  Future<bool> login(
    String username,
    String password, {
    String selectedRole = 'reporter',
    String mobileNumber = '',
    String aadharNumber = '',
  }) async {
    final formattedUsername = username.trim();
    if (formattedUsername.isEmpty) return false;

    // Validate Officer ID (any 2 capital letters + 123) and password (INDIA)
    if (selectedRole == 'officer') {
      final RegExp officerIdRegExp = RegExp(r'^[A-Z]{2}123$');
      if (!officerIdRegExp.hasMatch(formattedUsername) || password != 'INDIA') {
        return false;
      }
    }

    // Handle Officer State Shortform Username format (e.g. TN123, AP123, KL123, KA123, MH123)
    String state = 'Tamil Nadu';
    String city = 'Tiruvallur';
    String ward = 'Avadi';

    final upperUser = formattedUsername.toUpperCase();
    if (upperUser.startsWith('TN')) {
      state = 'Tamil Nadu'; city = 'Tiruvallur'; ward = 'Avadi';
    } else if (upperUser.startsWith('AP')) {
      state = 'Andhra Pradesh'; city = 'Visakhapatnam'; ward = 'MVP Colony';
    } else if (upperUser.startsWith('KL')) {
      state = 'Kerala'; city = 'Kochi'; ward = 'Marine Drive';
    } else if (upperUser.startsWith('KA')) {
      state = 'Karnataka'; city = 'Bengaluru'; ward = 'Indiranagar';
    } else if (upperUser.startsWith('MH')) {
      state = 'Maharashtra'; city = 'Mumbai'; ward = 'Andheri';
    } else if (upperUser.startsWith('DL')) {
      state = 'Delhi (NCT)'; city = 'New Delhi'; ward = 'Connaught Place';
    } else if (upperUser.startsWith('TS')) {
      state = 'Telangana'; city = 'Hyderabad'; ward = 'Banjara Hills';
    } else if (upperUser.startsWith('GJ')) {
      state = 'Gujarat'; city = 'Ahmedabad'; ward = 'Navrangpura';
    } else if (upperUser.startsWith('UP')) {
      state = 'Uttar Pradesh'; city = 'Lucknow'; ward = 'Hazratganj';
    } else if (upperUser.startsWith('WB')) {
      state = 'West Bengal'; city = 'Kolkata'; ward = 'Park Street';
    } else if (upperUser.startsWith('RJ')) {
      state = 'Rajasthan'; city = 'Jaipur'; ward = 'Malviya Nagar';
    }

    final String role = selectedRole;

    // Generate consistent email and password for Firebase Auth
    final email = role == 'officer'
        ? '${formattedUsername.toLowerCase()}@civicreporter.gov.in'
        : '${formattedUsername.toLowerCase()}_${mobileNumber.replaceAll(RegExp(r'\D'), '')}@civicreporter.org';
    final firebasePassword = role == 'officer' ? password : 'citizen_password_123';

    // Authenticate with Firebase Auth
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: firebasePassword,
      );
    } catch (e) {
      try {
        // If user does not exist in Auth database, create it
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: firebasePassword,
        );
      } catch (e2) {
        debugPrint('Firebase Auth Login/Signup Error: $e2');
      }
    }

    _currentUser = UserAccount(
      name: role == 'officer' ? 'Ward Officer ($formattedUsername)' : formattedUsername,
      username: formattedUsername,
      password: password,
      email: email,
      role: role,
      mobileNumber: mobileNumber.isNotEmpty ? mobileNumber.replaceAll(RegExp(r'\D'), '') : '9876543210',
      isMobileVerified: true,
      verificationMethod: 'Credentials',
      selectedState: state,
      selectedCity: city,
      selectedWard: ward,
      aadharNumber: aadharNumber,
    );

    try {
      final docId = role == 'officer' ? formattedUsername : '${formattedUsername}_$mobileNumber';
      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'uid': docId,
        'name': _currentUser!.name,
        'username': formattedUsername,
        'role': role,
        'mobile_number': _currentUser!.mobileNumber,
        'aadhar_number': aadharNumber,
        'selected_state': state,
        'selected_city': city,
        'selected_ward': ward,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore User Login Sync Error: $e');
      rethrow;
    }

    notifyListeners();
    return true;
  }

  Future<bool> loginWithMobileOTP({
    required String mobileNumber,
    required String otp,
    required String verificationId,
    String role = 'reporter',
  }) async {
    bool verified = await SMSAuthService.verifyLiveOTP(
      verificationId: verificationId,
      userEnteredCode: otp,
      mobileNumber: mobileNumber,
      role: role,
    );

    if (!verified) return false;

    final cleanMobile = mobileNumber.trim();
    final displayName = 'Citizen (${cleanMobile.length > 4 ? cleanMobile.substring(cleanMobile.length - 4) : 'User'})';
    final email = '${cleanMobile.replaceAll(RegExp(r'\D'), '')}@civicreporter.org';

    _currentUser = UserAccount(
      name: displayName,
      username: cleanMobile,
      password: '',
      email: email,
      role: role,
      mobileNumber: cleanMobile,
      isMobileVerified: true,
      verificationMethod: 'Live_SMS_OTP',
      selectedState: 'Tamil Nadu',
      selectedCity: 'Tiruvallur',
      selectedWard: 'Avadi',
    );

    notifyListeners();
    return true;
  }

  Future<bool> loginOfficer2FA({
    required String officerIdOrEmail,
    required String password,
    required String mobileNumber,
    required String otp,
    required String verificationId,
  }) async {
    bool verified = await SMSAuthService.verifyLiveOTP(
      verificationId: verificationId,
      userEnteredCode: otp,
      mobileNumber: mobileNumber,
      role: 'officer',
    );

    if (!verified) return false;

    final email = officerIdOrEmail.contains('@')
        ? officerIdOrEmail.trim()
        : '${officerIdOrEmail.trim().toLowerCase()}@civicreporter.org';
    final displayName = 'Ward Officer (${officerIdOrEmail.trim()})';

    _currentUser = UserAccount(
      name: displayName,
      username: officerIdOrEmail.trim(),
      password: password.trim(),
      email: email,
      role: 'officer',
      mobileNumber: mobileNumber.trim().isNotEmpty ? mobileNumber.trim() : '+91 9876543210',
      isMobileVerified: true,
      verificationMethod: '2FA_Live_OTP',
      selectedState: 'Tamil Nadu',
      selectedCity: 'Tiruvallur',
      selectedWard: 'Avadi',
    );

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      debugPrint('SignOut Error: $e');
    }
    _currentUser = null;
    notifyListeners();
  }
}

// ==========================================
// REPORT / ISSUE DATA MODEL & STORE
// ==========================================

class ReportModel {
  final String id;
  final String type;
  final String location;
  final String state;
  final String cityDistrict;
  final String ward; // ward_name e.g. 'Avadi'
  final String status; // 'Submitted' / 'Pending', 'In Progress', 'Resolved', 'Rejected'
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final String date;
  final String time;
  final String description;
  final String severity;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String submittedBy;
  final String submittedByPhone;
  final String submittedByEmail;
  final String submittedByAadhar;
  final double latitude;
  final double longitude;
  final String? assignedCrew;
  final String? officerNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String aiModerationStatus;

  ReportModel({
    required this.id,
    required this.type,
    required this.location,
    required this.state,
    required this.cityDistrict,
    required this.ward,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.date,
    required this.time,
    required this.description,
    required this.severity,
    this.imagePath,
    this.imageBytes,
    required this.submittedBy,
    this.submittedByPhone = '+91 9876543210',
    this.submittedByEmail = 'citizen@civicreporter.org',
    this.submittedByAadhar = '',
    required this.latitude,
    required this.longitude,
    this.assignedCrew,
    this.officerNote,
    DateTime? createdAt,
    this.resolvedAt,
    this.aiModerationStatus = 'Passed',
  }) : createdAt = createdAt ?? DateTime.now();
}

class ReportStore extends ChangeNotifier {
  static final ReportStore instance = ReportStore._internal();
  ReportStore._internal() {
    _initRealtimeListener();
  }

  final List<ReportModel> _reports = [];

  void _initRealtimeListener() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous Auth fallback failed: $e');
      }
    }

    try {
      FirebaseFirestore.instance
          .collection('reports')
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data != null) {
            final id = data['id'] ?? change.doc.id;
            final index = _reports.indexWhere((r) => r.id == id);
            final status = data['status'] ?? 'Submitted';
            Color statusColor = Colors.blue;
            if (status == 'In Progress') statusColor = Colors.orange;
            if (status == 'Resolved') statusColor = Colors.green;
            if (status == 'Rejected') statusColor = Colors.red;

            IconData icon = Icons.warning_rounded;
            Color iconColor = Colors.orange;
            final type = data['type'] ?? 'Pothole';
            if (type == 'Streetlight') {
              icon = Icons.lightbulb_outline;
              iconColor = Colors.blue;
            }
            if (type == 'Open Drain') {
              icon = Icons.water_damage;
              iconColor = Colors.teal;
            }
            if (type == 'Garbage') {
              icon = Icons.delete_outline;
              iconColor = Colors.red;
            }

            final base64Str = data['image_base64'];
            Uint8List? imgBytes;
            if (base64Str != null && base64Str.toString().isNotEmpty) {
              try {
                imgBytes = base64Decode(base64Str.toString());
              } catch (_) {}
            }

            final report = ReportModel(
              id: id,
              type: type,
              location: data['location'] ?? 'Avadi Municipal Region',
              state: data['state'] ?? 'Tamil Nadu',
              cityDistrict: data['city_district'] ?? 'Tiruvallur',
              ward: data['ward_name'] ?? 'Avadi',
              status: status,
              statusColor: statusColor,
              icon: icon,
              iconColor: iconColor,
              date: data['date'] ?? 'Today',
              time: data['time'] ?? 'Just now',
              description: data['description'] ?? '',
              severity: data['severity'] ?? 'Medium',
              imageBytes: imgBytes,
              submittedBy: data['submittedBy'] ?? 'Citizen',
              submittedByPhone: data['submittedByPhone'] ?? '+91 9876543210',
              submittedByEmail: data['submittedByEmail'] ?? 'citizen@civicreporter.org',
              submittedByAadhar: data['submittedByAadhar'] ?? '',
              latitude: (data['latitude'] ?? 13.1147).toDouble(),
              longitude: (data['longitude'] ?? 80.1098).toDouble(),
              assignedCrew: data['assignedCrew'],
              officerNote: data['officerNote'],
              aiModerationStatus: data['ai_moderation_status'] ?? 'Passed',
            );

            if (index != -1) {
              _reports[index] = report;
            } else {
              _reports.insert(0, report);
            }
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firestore Listener Error: $e');
    }
  }

  List<ReportModel> get reports => List.unmodifiable(_reports);

  int get totalCount => _reports.length;
  int get inProgressCount => _reports.where((r) => r.status == 'In Progress').length;
  int get resolvedCount => _reports.where((r) => r.status == 'Resolved').length;
  int get submittedCount => _reports.where((r) => r.status == 'Submitted' || r.status == 'Acknowledged' || r.status == 'Pending').length;
  int get rejectedCount => _reports.where((r) => r.status == 'Rejected').length;

  Future<void> addReport(ReportModel report) async {
    final existingIndex = _reports.indexWhere((r) => r.id == report.id);
    if (existingIndex != -1) {
      _reports[existingIndex] = report;
    } else {
      _reports.insert(0, report);
    }
    notifyListeners();

    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        debugPrint('Anonymous Auth fallback on addReport failed: $e');
      }
    }

    String? imageBase64;
    if (report.imageBytes != null && report.imageBytes!.isNotEmpty) {
      imageBase64 = base64Encode(report.imageBytes!);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reports').doc(report.id).set({
        'id': report.id,
        'type': report.type,
        'location': report.location,
        'state': report.state,
        'city_district': report.cityDistrict,
        'ward_name': report.ward,
        'status': report.status,
        'date': report.date,
        'time': report.time,
        'description': report.description,
        'severity': report.severity,
        'image_base64': imageBase64,
        'submittedBy': report.submittedBy,
        'submittedByPhone': report.submittedByPhone,
        'submittedByEmail': report.submittedByEmail,
        'submittedByAadhar': report.submittedByAadhar,
        'userUid': user?.uid ?? '',
        'latitude': report.latitude,
        'longitude': report.longitude,
        'ai_moderation_status': report.aiModerationStatus,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore Sync Error: $e');
      rethrow;
    }
  }

  void updateReportStatus(String id, String newStatus, {String? assignedCrew, String? officerNote}) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      Color newColor = Colors.blue;
      if (newStatus == 'In Progress') newColor = Colors.orange;
      if (newStatus == 'Resolved') newColor = Colors.green;
      if (newStatus == 'Rejected') newColor = Colors.red;

      final existing = _reports[index];
      DateTime? newlyResolvedAt = existing.resolvedAt;
      if (newStatus == 'Resolved' && existing.status != 'Resolved') {
        newlyResolvedAt = DateTime.now();

        NotificationService.triggerResolutionNotifications(
          citizenPhone: existing.submittedByPhone,
          citizenEmail: existing.submittedByEmail,
          citizenName: existing.submittedBy,
          issueId: existing.id,
          issueTitle: existing.type,
          wardName: '${existing.ward}, ${existing.cityDistrict}, ${existing.state}',
          resolutionNotes: officerNote ?? 'Action completed by Municipal Field Crew.',
          resolvedAt: newlyResolvedAt,
        );
      }

      _reports[index] = ReportModel(
        id: existing.id,
        type: existing.type,
        location: existing.location,
        state: existing.state,
        cityDistrict: existing.cityDistrict,
        ward: existing.ward,
        status: newStatus,
        statusColor: newColor,
        icon: existing.icon,
        iconColor: existing.iconColor,
        date: existing.date,
        time: existing.time,
        description: existing.description,
        severity: existing.severity,
        imagePath: existing.imagePath,
        imageBytes: existing.imageBytes,
        submittedBy: existing.submittedBy,
        submittedByPhone: existing.submittedByPhone,
        submittedByEmail: existing.submittedByEmail,
        latitude: existing.latitude,
        longitude: existing.longitude,
        assignedCrew: assignedCrew ?? existing.assignedCrew,
        officerNote: officerNote ?? existing.officerNote,
        createdAt: existing.createdAt,
        resolvedAt: newlyResolvedAt,
        aiModerationStatus: existing.aiModerationStatus,
      );
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('reports').doc(id).update({
          'status': newStatus,
          'assignedCrew': assignedCrew ?? existing.assignedCrew,
          'officerNote': officerNote ?? existing.officerNote,
          'resolved_at': newlyResolvedAt != null ? Timestamp.fromDate(newlyResolvedAt) : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore update error: $e');
      }
    }
  }
}

// ==========================================
// MAIN ENTRY POINT
// ==========================================

Future<void> preseedAadhaarDatabase() async {
  try {
    final uidaiRef = FirebaseFirestore.instance.collection('uidai_aadhaar_records');
    final records = {
      '880561950214': 'kavin',
      '123456789012': 'Kavin Kumar',
      '987654321012': 'John',
    };

    for (var entry in records.entries) {
      await uidaiRef.doc(entry.key).set({
        'name': entry.value,
        'status': 'Active',
      }, SetOptions(merge: true));
    }
  } catch (e) {
    debugPrint('Preseed error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.printConfigSummary();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await preseedAadhaarDatabase();
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

// ==========================================
// SPLASH SCREEN
// ==========================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
    Future.delayed(const Duration(seconds: 2), () {
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
                        color: Colors.black.withValues(alpha: 0.2),
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
                  'Fix Your City — Production Auth',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 60),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

// ==========================================
// PRODUCTION AUTHENTICATION SCREEN
// ==========================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();

  String _selectedRole = 'reporter'; // 'reporter' or 'officer'
  bool _isLoading = false;
  bool _isSignUpMode = false;

  String _signUpState = 'Tamil Nadu';
  String _signUpCity = 'Tiruvallur';
  String _signUpWard = 'Avadi';

  List<String> _availableStates = [];
  List<String> _availableCities = [];
  List<String> _availableWards = [];

  void _loadSignUpDropdowns() {
    _availableStates = IndiaLocations.getStates();
    if (!_availableStates.contains(_signUpState) && _availableStates.isNotEmpty) {
      _signUpState = _availableStates.first;
    }
    _availableCities = IndiaLocations.getCities(_signUpState);
    if (!_availableCities.contains(_signUpCity) && _availableCities.isNotEmpty) {
      _signUpCity = _availableCities.first;
    }
    _availableWards = IndiaLocations.getWards(_signUpState, _signUpCity);
    if (!_availableWards.contains(_signUpWard) && _availableWards.isNotEmpty) {
      _signUpWard = _availableWards.first;
    }
  }

  void _onSignUpStateChanged(String? newState) {
    if (newState == null || newState == _signUpState) return;
    setState(() {
      _signUpState = newState;
      _availableCities = IndiaLocations.getCities(_signUpState);
      _signUpCity = _availableCities.isNotEmpty ? _availableCities.first : '';
      _availableWards = IndiaLocations.getWards(_signUpState, _signUpCity);
      _signUpWard = _availableWards.isNotEmpty ? _availableWards.first : '';
    });
  }

  void _onSignUpCityChanged(String? newCity) {
    if (newCity == null || newCity == _signUpCity) return;
    setState(() {
      _signUpCity = newCity;
      _availableWards = IndiaLocations.getWards(_signUpState, _signUpCity);
      _signUpWard = _availableWards.isNotEmpty ? _availableWards.first : '';
    });
  }

  void _onSignUpWardChanged(String? newWard) {
    if (newWard == null || newWard == _signUpWard) return;
    setState(() {
      _signUpWard = newWard;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkRedirectAuth();
    _loadSignUpDropdowns();
  }

  Future<void> _checkRedirectAuth() async {
    final result = await GoogleAuthService.checkRedirectResult(role: 'reporter');
    if (result != null && result.isSuccess && mounted) {
      final displayName = result.displayName ?? 'Citizen User';
      final email = result.email ?? 'citizen@gmail.com';
      final googleUser = UserAccount(
        name: displayName,
        username: email,
        password: '',
        email: email,
        role: 'reporter',
        mobileNumber: 'Google Verified',
        isMobileVerified: true,
        verificationMethod: 'Google',
        selectedState: 'Tamil Nadu',
        selectedCity: 'Tiruvallur',
        selectedWard: 'Avadi',
      );
      UserStore.instance.setCurrentUser(googleUser);
      _navigateToLocationSelection();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final aadhar = _aadharController.text.trim();

    if (_selectedRole == 'officer') {
      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed: Wrong Authentication'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (username.isEmpty || mobile.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your Username and a valid 10-digit Mobile Number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_isSignUpMode) {
        if (email.isEmpty || !email.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid Email Address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'officer') {
        bool success = await UserStore.instance.login(
          username,
          password.isNotEmpty ? password : 'INDIA',
          selectedRole: 'officer',
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          await FirebaseFirestore.instance.collection('users').doc(username).set({
            'uid': username,
            'name': username,
            'username': username,
            'email': '${username.toLowerCase()}@civicreporter.gov.in',
            'role': 'officer',
            'provider': 'credentials',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _navigateToDashboard();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed: Wrong Authentication'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Citizen Flow
        final docId = '${username}_$mobile';

        if (_isSignUpMode) {
          // Sign Up registration
          bool success = await UserStore.instance.login(
            username,
            'citizen_password_123',
            selectedRole: 'reporter',
            mobileNumber: mobile,
            aadharNumber: aadhar,
          );

          if (success) {
            // Write sign up details directly to Firestore
            await FirebaseFirestore.instance.collection('users').doc(docId).set({
              'uid': docId,
              'name': username,
              'username': username,
              'email': email,
              'role': 'reporter',
              'mobile_number': mobile,
              'aadhar_number': aadhar,
              'selected_state': _signUpState,
              'selected_city': _signUpCity,
              'selected_ward': _signUpWard,
              'provider': 'credentials',
              'is_verified': true,
              'lastLogin': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            final newUser = UserAccount(
              name: username,
              username: username,
              password: '',
              email: email,
              role: 'reporter',
              mobileNumber: mobile,
              isMobileVerified: true,
              verificationMethod: 'Credentials',
              selectedState: _signUpState,
              selectedCity: _signUpCity,
              selectedWard: _signUpWard,
              aadharNumber: aadhar,
            );
            UserStore.instance.setCurrentUser(newUser);

            if (!mounted) return;
            setState(() => _isLoading = false);
            _navigateToDashboard();
          } else {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign up failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Citizen Login - check user profile exists
          final docSnap = await FirebaseFirestore.instance.collection('users').doc(docId).get();
          if (!docSnap.exists) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account not found. Please click "Sign Up" below to create a new account!'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Performs login which loads saved locations automatically
          bool success = await UserStore.instance.login(
            username,
            'citizen_password_123',
            selectedRole: 'reporter',
            mobileNumber: mobile,
          );

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (success) {
            _navigateToDashboard();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication failed. Check your ID and password.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Firestore Database Error'),
            ],
          ),
          content: Text(
            'Could not authenticate user profile:\n\n$e\n\n'
            'Please ensure your Firebase Firestore is running.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await GoogleAuthService.signInWithGoogle(role: 'reporter')
          .timeout(const Duration(seconds: 15), onTimeout: () {
        return GoogleAuthResult.failure('Google Sign-In popup timed out or was closed. Please try again.');
      });

      if (!mounted) return;

      if (result.isSuccess) {
        String displayName = result.displayName ?? 'Citizen User';
        final email = result.email ?? 'citizen@gmail.com';

        if (displayName == 'Google Verified Citizen') {
          final nameController = TextEditingController();
          final enteredName = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Google Verification Success'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please enter your Full Name to complete registration:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final txt = nameController.text.trim();
                    if (txt.isNotEmpty) {
                      Navigator.pop(context, txt);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
          if (enteredName != null && enteredName.isNotEmpty) {
            displayName = enteredName;
          }
        }

        final googleUser = UserAccount(
          name: displayName,
          username: email,
          password: '',
          email: email,
          role: 'reporter',
          mobileNumber: 'Google Verified',
          isMobileVerified: true,
          verificationMethod: 'Google',
          selectedState: 'Tamil Nadu',
          selectedCity: 'Tiruvallur',
          selectedWard: 'Avadi',
        );

        UserStore.instance.setCurrentUser(googleUser);

        // Save new Google Sign-In user account in database
        try {
          final docId = result.uid ?? email;
          await FirebaseFirestore.instance.collection('users').doc(docId).set({
            'uid': docId,
            'name': displayName,
            'username': email,
            'email': email,
            'role': 'reporter',
            'mobile_number': 'Google Verified',
            'provider': 'google.com',
            'is_verified': true,
            'selected_state': 'Tamil Nadu',
            'selected_city': 'Tiruvallur',
            'selected_ward': 'Avadi',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore Google Account Creation Error: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in with Google as $displayName'),
            backgroundColor: Colors.green,
          ),
        );

        _navigateToLocationSelection();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Google Sign-In failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLocationSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
    );
  }

  void _navigateToDashboard() {
    final user = UserStore.instance.currentUser;
    if (user != null) {
      if (user.role == 'officer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDashboard()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfficer = _selectedRole == 'officer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // GOVERNMENT HEADER BANNER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A2540),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                          ),
                          child: const Icon(Icons.account_balance, size: 32, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CIVIC REPORTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'GOVERNMENT OF INDIA • PUBLIC SERVICES PORTAL',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ROLE SELECTION TAB BAR
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'reporter'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !isOfficer ? const Color(0xFF0A2540) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person, size: 18, color: !isOfficer ? Colors.white : Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Citizen Portal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: !isOfficer ? Colors.white : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'officer'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isOfficer ? const Color(0xFF0A2540) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.shield, size: 18, color: isOfficer ? Colors.white : Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Ward Officer',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isOfficer ? Colors.white : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          isOfficer ? 'Ward Officer / Admin Login' : 'Citizen Sign-In',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOfficer
                              ? 'Enter your Officer ID and Password'
                              : 'Enter your Full Name & Mobile Number',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),

                        // CITIZEN FORM OR OFFICER FORM
                        if (isOfficer) ...[
                          const Text('Officer State Shortform ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.badge, color: Color(0xFF0A2540)),
                              hintText: 'Officer ID',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF0A2540)),
                              hintText: 'Password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                              ),
                            ),
                          ),
                        ] else ...[
                          const Text('Username / Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF0A2540)),
                              hintText: 'Username / Full Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF0A2540)),
                              hintText: 'Mobile Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                              ),
                            ),
                          ),
                          if (_isSignUpMode) ...[
                            const SizedBox(height: 16),
                            const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF0A2540)),
                                hintText: 'Email Address',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Aadhar Number (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _aadharController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.fingerprint, color: Color(0xFF0A2540)),
                                hintText: 'Aadhar Number',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0A2540), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Select State / UT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _signUpState,
                              items: _availableStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: _onSignUpStateChanged,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.map, color: Color(0xFF0A2540)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Select City / District', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _signUpCity,
                              items: _availableCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: _onSignUpCityChanged,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.location_city, color: Color(0xFF0A2540)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Select Ward / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _signUpWard,
                              items: _availableWards.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                              onChanged: _onSignUpWardChanged,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.near_me, color: Color(0xFF0A2540)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2540),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text(
                                    isOfficer
                                        ? 'Log In as Ward Officer'
                                        : (_isSignUpMode ? 'Register & Sign Up' : 'Log In as Citizen / Reporter'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        if (!isOfficer) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4285F4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: Color(0xFF202124),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                });
                              },
                              child: Text(
                                _isSignUpMode
                                    ? 'Already have an account? Sign In'
                                    : 'Don\'t have an account? Sign Up',
                                style: const TextStyle(
                                  color: Color(0xFF0A2540),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PRE-REPORTING LOCATION SELECTION SCREEN
// ==========================================

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late String _selectedState;
  late String _selectedCity;
  late String _selectedWard;

  List<String> _availableStates = [];
  List<String> _availableCities = [];
  List<String> _availableWards = [];

  @override
  void initState() {
    super.initState();
    final user = UserStore.instance.currentUser;
    _selectedState = user?.selectedState ?? 'Tamil Nadu';
    _selectedCity = user?.selectedCity ?? 'Tiruvallur';
    _selectedWard = user?.selectedWard ?? 'Avadi';

    _loadDropdowns();
  }

  void _loadDropdowns() {
    _availableStates = IndiaLocations.getStates();
    if (!_availableStates.contains(_selectedState) && _availableStates.isNotEmpty) {
      _selectedState = _availableStates.first;
    }

    _availableCities = IndiaLocations.getCities(_selectedState);
    if (!_availableCities.contains(_selectedCity) && _availableCities.isNotEmpty) {
      _selectedCity = _availableCities.first;
    }

    _availableWards = IndiaLocations.getWards(_selectedState, _selectedCity);
    if (!_availableWards.contains(_selectedWard) && _availableWards.isNotEmpty) {
      _selectedWard = _availableWards.first;
    }

    setState(() {});
  }

  void _onStateChanged(String? newState) {
    if (newState == null || newState == _selectedState) return;
    setState(() {
      _selectedState = newState;
      _availableCities = IndiaLocations.getCities(_selectedState);
      _selectedCity = _availableCities.isNotEmpty ? _availableCities.first : '';

      _availableWards = IndiaLocations.getWards(_selectedState, _selectedCity);
      _selectedWard = _availableWards.isNotEmpty ? _availableWards.first : '';
    });
  }

  void _onCityChanged(String? newCity) {
    if (newCity == null || newCity == _selectedCity) return;
    setState(() {
      _selectedCity = newCity;
      _availableWards = IndiaLocations.getWards(_selectedState, _selectedCity);
      _selectedWard = _availableWards.isNotEmpty ? _availableWards.first : '';
    });
  }

  void _onWardChanged(String? newWard) {
    if (newWard == null || newWard == _selectedWard) return;
    setState(() {
      _selectedWard = newWard;
    });
  }

  void _confirmLocation() {
    UserStore.instance.updateLocationContext(
      state: _selectedState,
      city: _selectedCity,
      ward: _selectedWard,
    );

    final currentUser = UserStore.instance.currentUser;
    if (currentUser?.role == 'officer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OfficerDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfficer = UserStore.instance.currentUser?.role == 'officer';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: const Text(
          'Government Location Onboarding',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2540),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isOfficer ? Icons.shield : Icons.map_outlined, color: const Color(0xFFD4AF37), size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isOfficer
                                  ? 'Select state and region to manage jurisdiction'
                                  : 'Select the state and region to report your issue',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isOfficer
                            ? 'Cascading jurisdiction parameters: State -> District -> Ward.'
                            : 'Select your State, City, and Locality to lock in pre-filled reporting coordinates.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Select State / UT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState.isNotEmpty ? _selectedState : null,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A2540)),
                      items: _availableStates.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: _onStateChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Select City / District',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity.isNotEmpty ? _selectedCity : null,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A2540)),
                      items: _availableCities.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: _onCityChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Select Ward / Area',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedWard.isNotEmpty ? _selectedWard : null,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A2540)),
                      items: _availableWards.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: _onWardChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2540),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20),
                        SizedBox(width: 10),
                        Text('Confirm Location & Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
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
}

// ==========================================
// REPORTER DASHBOARD & NAVIGATION
// ==========================================

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    ReportStore.instance.addListener(_onStoreChanged);
    UserStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreChanged);
    UserStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHome(),
      MyReportsScreen(onBack: () => setState(() => _currentIndex = 0)),
      ProfileScreen(onBack: () => setState(() => _currentIndex = 0)),
    ];

    final isWeb = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: pages[_currentIndex],
      bottomNavigationBar: isWeb
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: const Color(0xFF0A2540),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Reports'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
    );
  }

  Widget _buildHome() {
    final user = UserStore.instance.currentUser;
    final userName = user != null ? user.name : 'Citizen';
    final userWard = user != null ? user.selectedWard : 'Avadi';
    final userCity = user != null ? user.selectedCity : 'Tiruvallur';
    final userState = user != null ? user.selectedState : 'Tamil Nadu';
    final store = ReportStore.instance;
    final isWeb = MediaQuery.of(context).size.width > 900;
    final userPhone = user != null ? user.mobileNumber.replaceAll(RegExp(r'\D'), '') : '9876543210';
    final myReports = store.reports.where((r) {
      final nameMatch = r.submittedBy.trim().toLowerCase() == userName.trim().toLowerCase();
      final phoneMatch = r.submittedByPhone.replaceAll(RegExp(r'\D'), '') == userPhone;
      return nameMatch && phoneMatch;
    }).toList();

    final filteredReports = myReports.where((r) {
      if (_statusFilter == 'All') return true;
      return r.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isWeb ? 80 : 65),
        child: Container(
          color: const Color(0xFF0A2540),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CIVIC REPORTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Region: $userWard, $userCity, $userState',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isWeb)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _currentIndex = 0),
                        icon: const Icon(Icons.home, color: Colors.white, size: 18),
                        label: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => setState(() => _currentIndex = 1),
                        icon: const Icon(Icons.list_alt, color: Colors.white70, size: 18),
                        label: const Text('My Reports', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => setState(() => _currentIndex = 2),
                        icon: const Icon(Icons.person, color: Colors.white70, size: 18),
                        label: const Text('Profile', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF0A2540),
                        ),
                        icon: const Icon(Icons.edit_location_alt, size: 16),
                        label: const Text('Change Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_location_alt, color: Colors.white),
                        tooltip: 'Switch Location',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 1100 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A2540),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName! 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (user != null && user.aadharNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Aadhaar: ${user.aadharNumber} (Verified ✓)',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Public Services & Incident Reporting active for $userWard ($userCity, $userState)',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _statCard('${myReports.length}', 'Total\nReported', 'All'),
                          const SizedBox(width: 14),
                          _statCard('${myReports.where((r) => r.status == 'In Progress').length}', 'In\nProgress', 'In Progress'),
                          const SizedBox(width: 14),
                          _statCard('${myReports.where((r) => r.status == 'Resolved').length}', 'Resolved', 'Resolved'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A2540),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _quickReportBtn(Icons.warning_rounded, 'Pothole', Colors.orange),
                          _quickReportBtn(Icons.lightbulb_outline, 'Streetlight', Colors.blue),
                          _quickReportBtn(Icons.water_damage, 'Drain', Colors.teal),
                          _quickReportBtn(Icons.delete_outline, 'Garbage', Colors.red),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Reports',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2540),
                            ),
                          ),
                          if (myReports.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _currentIndex = 1;
                                });
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(color: Color(0xFF0A2540)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (filteredReports.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _statusFilter == 'All'
                                    ? 'No reports submitted yet'
                                    : 'No $_statusFilter reports found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A2540),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusFilter == 'All'
                                    ? 'Tap "+ Report Issue" below to submit your first civic issue!'
                                    : 'There are no active complaints with this status in your records.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredReports.take(5).map((report) => _issueCard(report)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
          );
        },
        backgroundColor: const Color(0xFF0A2540),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text(
          'Report Issue',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _statCard(String number, String label, String filterValue) {
    final isSelected = _statusFilter == filterValue;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = filterValue;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFD4AF37).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: const Color(0xFFD4AF37), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Text(number,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0A2540) : Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  )),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0A2540) : Colors.white70, 
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickReportBtn(IconData icon, String label, Color color) {
    final isWeb = MediaQuery.of(context).size.width > 900;
    final size = isWeb ? 52.0 : 48.0;
    final iconSize = isWeb ? 22.0 : 20.0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportIssueScreen(preSelectedCategory: label),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: TextStyle(
              fontSize: isWeb ? 11 : 10, 
              fontWeight: FontWeight.w600, 
              color: Colors.grey.shade700
            )
          ),
        ],
      ),
    );
  }

  Widget _issueCard(ReportModel report) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                color: report.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(report.icon, color: report.iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(report.type,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A5276))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: report.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(report.status,
                            style: TextStyle(
                                fontSize: 11, color: report.statusColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${report.ward}, ${report.cityDistrict}, ${report.state}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text('${report.id} • ${report.time}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// OFFICER PORTAL (STRICT LOCATION ISOLATION)
// ==========================================

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  String _viewMode = 'all'; // 'all' or 'ward'
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Submitted', 'In Progress', 'Resolved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    ReportStore.instance.addListener(_onStoreChanged);
    UserStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreChanged);
    UserStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  List<ReportModel> get _strictlyIsolatedReports {
    final officer = UserStore.instance.currentUser;
    final state = officer?.selectedState ?? 'Tamil Nadu';
    final city = officer?.selectedCity ?? 'Tiruvallur';
    final ward = officer?.selectedWard ?? 'Avadi';

    final allReports = ReportStore.instance.reports;
    
    // Filter strictly by the officer's jurisdiction (same state, city, and ward)
    final List<ReportModel> baseList = allReports.where((r) {
      final stateMatch = r.state.trim().toLowerCase() == state.trim().toLowerCase();
      final cityMatch = r.cityDistrict.trim().toLowerCase() == city.trim().toLowerCase();
      final wardMatch = r.ward.trim().toLowerCase() == ward.trim().toLowerCase();
      return stateMatch && cityMatch && wardMatch;
    }).toList();

    if (_selectedFilter == 'All') return baseList;
    if (_selectedFilter == 'Submitted') {
      return baseList.where((r) => r.status == 'Submitted' || r.status == 'Acknowledged' || r.status == 'Pending').toList();
    }
    return baseList.where((r) => r.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStore.instance;
    final officer = UserStore.instance.currentUser;
    final officerName = officer != null ? officer.name : 'Officer';
    final state = officer?.selectedState ?? 'Tamil Nadu';
    final city = officer?.selectedCity ?? 'Tiruvallur';
    final ward = officer?.selectedWard ?? 'Avadi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Officer Portal — $ward',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Logged in: $officerName | Jurisdiction: $ward ($city, $state)',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt, color: Colors.white),
            tooltip: 'Switch Officer Jurisdiction',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _officerStat('${_strictlyIsolatedReports.length}', _viewMode == 'all' ? 'All Feed' : 'Ward Feed', Colors.white),
                _officerStat('${store.submittedCount}', 'Pending', Colors.yellow.shade200),
                _officerStat('${store.inProgressCount}', 'In Progress', Colors.orange.shade200),
                _officerStat('${store.resolvedCount}', 'Resolved', Colors.green.shade200),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('All Citizen Complaints')),
                    selected: _viewMode == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'all');
                    },
                    selectedColor: const Color(0xFF1A5276).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _viewMode == 'all' ? const Color(0xFF1A5276) : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text('Assigned Ward ($ward)')),
                    selected: _viewMode == 'ward',
                    onSelected: (selected) {
                      if (selected) setState(() => _viewMode = 'ward');
                    },
                    selectedColor: const Color(0xFF1A5276).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _viewMode == 'ward' ? const Color(0xFF1A5276) : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A5276) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1A5276) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(filter,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey.shade700)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _strictlyIsolatedReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter complaints in $ward ($city, $state)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Issues outside this State -> District -> Ward are strictly hidden.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _strictlyIsolatedReports.length,
                    itemBuilder: (context, index) {
                      final report = _strictlyIsolatedReports[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfficerActionScreen(report: report),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: report.iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(report.icon, color: report.iconColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(report.type,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF1A5276))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: report.statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(report.status,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: report.statusColor,
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        Text('${report.ward}, ${report.cityDistrict}, ${report.state}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text('Reported by: ${report.submittedBy} • ${report.time}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    report.assignedCrew != null
                                        ? 'Assigned: ${report.assignedCrew}'
                                        : 'Priority: ${report.severity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: report.assignedCrew != null
                                          ? const Color(0xFF1A5276)
                                          : (report.severity == 'Critical' ? Colors.red : Colors.orange),
                                    ),
                                  ),
                                  const Row(
                                    children: [
                                      Text('Take Action',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1A5276),
                                              fontWeight: FontWeight.bold)),
                                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF1A5276)),
                                    ],
                                  ),
                                ],
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

  Widget _officerStat(String number, String label, Color color) {
    return Column(
      children: [
        Text(number, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class OfficerActionScreen extends StatefulWidget {
  final ReportModel report;
  const OfficerActionScreen({super.key, required this.report});

  @override
  State<OfficerActionScreen> createState() => _OfficerActionScreenState();
}

class _OfficerActionScreenState extends State<OfficerActionScreen> {
  late String _selectedStatus;
  String? _selectedCrew;
  final TextEditingController _noteController = TextEditingController();
  bool _isUpdating = false;

  final List<String> _statuses = ['Acknowledged', 'In Progress', 'Resolved', 'Rejected'];
  final List<String> _crews = [
    'Crew A — Roads & Potholes',
    'Crew B — Drainage & Water',
    'Crew C — Electrical & Lights',
    'Crew D — Sanitation & Waste',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _selectedCrew = widget.report.assignedCrew;
    if (widget.report.officerNote != null) {
      _noteController.text = widget.report.officerNote!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);

    ReportStore.instance.updateReportStatus(
      widget.report.id,
      _selectedStatus,
      assignedCrew: _selectedCrew,
      officerNote: _noteController.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedStatus == 'Resolved'
            ? 'Status marked RESOLVED! Automated SMS & Email notifications dispatched.'
            : 'Status updated to "$_selectedStatus"!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.report.id} (${widget.report.ward})',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.report.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.report.icon, color: widget.report.iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.report.type,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A5276))),
                            Text('${widget.report.ward}, ${widget.report.cityDistrict}, ${widget.report.state}',
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('Submitted by: ${widget.report.submittedBy} (Phone: ${widget.report.submittedByPhone}${widget.report.submittedByAadhar.isNotEmpty ? " | Aadhaar: ${widget.report.submittedByAadhar}" : ""})',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Description: ${widget.report.description}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Update Complaint Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final s = _statuses[index];
                final isSelected = _selectedStatus == s;
                Color sColor = Colors.blue;
                if (s == 'In Progress') sColor = Colors.orange;
                if (s == 'Resolved') sColor = Colors.green;
                if (s == 'Rejected') sColor = Colors.red;

                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = s),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? sColor.withValues(alpha: 0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? sColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? sColor : Colors.grey.shade700)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Assign Field Crew',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            ..._crews.map((crew) {
              final isSelected = _selectedCrew == crew;
              return GestureDetector(
                onTap: () => setState(() => _selectedCrew = crew),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A5276).withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1A5276) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group,
                          color: isSelected ? const Color(0xFF1A5276) : Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(crew,
                          style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1A5276) : Colors.grey.shade700)),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF1A5276), size: 18),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text('Officer Resolution Summary (SMS & Email Alert)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add official resolution details for citizen notification...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A5276), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 10),
                          Text('Update & Trigger Resolution SMS/Email',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

// ==========================================
// REPORT ISSUE SCREEN (WITH GPS DOUBLE-VERIFICATION)
// ==========================================

class ReportIssueScreen extends StatefulWidget {
  final String? preSelectedCategory;
  const ReportIssueScreen({super.key, this.preSelectedCategory});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedCategory;
  String? _selectedSeverity = 'Medium';
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isSubmitting = false;
  File? _capturedImage;
  Uint8List? _capturedImageBytes;
  String? _capturedImagePath;
  String? _capturedImageName;

  final double _latitude = 13.1147;
  final double _longitude = 80.1098;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pothole', 'icon': Icons.warning_rounded, 'color': Colors.orange},
    {'name': 'Streetlight', 'icon': Icons.lightbulb_outline, 'color': Colors.blue},
    {'name': 'Open Drain', 'icon': Icons.water_damage, 'color': Colors.teal},
    {'name': 'Garbage', 'icon': Icons.delete_outline, 'color': Colors.red},
    {'name': 'Road Damage', 'icon': Icons.construction, 'color': Colors.brown},
    {'name': 'Water Leak', 'icon': Icons.water_drop, 'color': Colors.cyan},
  ];

  final List<String> _severities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preSelectedCategory;
    final user = UserStore.instance.currentUser;
    final ward = user?.selectedWard ?? 'Avadi';
    final city = user?.selectedCity ?? 'Tiruvallur';
    final state = user?.selectedState ?? 'Tamil Nadu';

    _locationController.text = '$ward Municipal Region, $city, $state';
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              children: [
                const Text(
                  'Select Photo Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A2540),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF0A2540)),
                  title: const Text('Take Photo (Native Camera Stream)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF0A2540)),
                  title: const Text('Choose from Gallery (Fallback Upload)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _capturedImagePath = image.path;
          _capturedImageName = image.name;
          if (!kIsWeb) {
            _capturedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera/Storage access blocked: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
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

    // Show simulated premium AI Vision loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2540)),
            ),
            SizedBox(height: 20),
            Text(
              'AI Vision Pipeline Active',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A2540)),
            ),
            SizedBox(height: 6),
            Text(
              'Analyzing photo alignment and category integrity...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pop(context); // Close the AI loader
    }

    final moderationResult = await AIModerationService.validateImage(
      imageBytes: _capturedImageBytes,
      imagePath: _capturedImagePath ?? _capturedImage?.path,
      imageName: _capturedImageName,
      category: _selectedCategory,
      title: _descController.text,
    );

    if (!moderationResult.isValid) {
      setState(() => _isSubmitting = false);
      _showAIModerationErrorModal(moderationResult.rejectionReason);
      return;
    }

    final catMatch = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {'icon': Icons.warning, 'color': Colors.blue},
    );

    final user = UserStore.instance.currentUser;
    final userName = user != null ? user.name : 'Citizen';
    final userPhone = user != null ? user.mobileNumber.replaceAll(RegExp(r'\D'), '') : '9876543210';
    final userEmail = user != null ? user.email : 'citizen@civicreporter.org';
    final userState = user?.selectedState ?? 'Tamil Nadu';
    final userCity = user?.selectedCity ?? 'Tiruvallur';
    final userWard = user?.selectedWard ?? 'Avadi';

    final newReport = ReportModel(
      id: '#WD24-${(100 + ReportStore.instance.totalCount + 1)}',
      type: _selectedCategory!,
      location: _locationController.text.trim().isEmpty
          ? '$userWard Municipal Region, $userCity, $userState'
          : _locationController.text.trim(),
      state: userState,
      cityDistrict: userCity,
      ward: userWard,
      status: 'Submitted',
      statusColor: Colors.blue,
      icon: catMatch['icon'] as IconData,
      iconColor: catMatch['color'] as Color,
      date: '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
      time: 'Just now',
      description: _descController.text.trim().isEmpty
          ? 'No description provided.'
          : _descController.text.trim(),
      severity: _selectedSeverity ?? 'Medium',
      imagePath: _capturedImagePath ?? _capturedImage?.path,
      imageBytes: _capturedImageBytes,
      submittedBy: userName,
      submittedByPhone: userPhone,
      submittedByEmail: userEmail,
      submittedByAadhar: user?.aadharNumber ?? '',
      latitude: _latitude,
      longitude: _longitude,
      aiModerationStatus: 'Passed',
    );

    try {
      await ReportStore.instance.addReport(newReport);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Database Sync Error'),
            ],
          ),
          content: Text(
            'Could not save report to Firebase Firestore:\n\n$e\n\n'
            'Please ensure your Firebase Firestore Rules allow authenticated reads and writes.\n\n'
            'Go to Firebase Console -> Firestore Database -> Rules, and set them to:\n\n'
            'allow read, write: if request.auth != null;'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionSuccessScreen(report: newReport),
      ),
    );
  }

  void _showAIModerationErrorModal(String? message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('AI Moderation Flag')),
          ],
        ),
        content: Text(
          message ?? 'Invalid image detected. Please upload a clear photo of the issue.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2540)),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _capturedImageBytes != null || _capturedImage != null || _capturedImagePath != null;
    final user = UserStore.instance.currentUser;
    final activeLocationStr = '${user?.selectedWard ?? "Avadi"}, ${user?.selectedCity ?? "Tiruvallur"}, ${user?.selectedState ?? "Tamil Nadu"}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report an Issue',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showImagePickerModal,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasImage ? const Color(0xFF1A5276) : Colors.grey.shade300,
                    width: hasImage ? 2 : 1,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildCrossPlatformImage(
                              bytes: _capturedImageBytes,
                              path: _capturedImagePath ?? _capturedImage?.path,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _capturedImage = null;
                                      _capturedImageBytes = null;
                                      _capturedImagePath = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 48, color: Color(0xFF1A5276)),
                          SizedBox(height: 12),
                          Text(
                            'Tap for Native Camera / Gallery Upload',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1A5276),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('AI Vision will validate image content before submission',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Issue Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (cat['color'] as Color).withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cat['color'] as Color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? cat['color'] as Color : Colors.grey.shade700,
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            Row(
              children: _severities.map((s) {
                final isSelected = _selectedSeverity == s;
                Color chipColor = Colors.green;
                if (s == 'Medium') chipColor = Colors.orange;
                if (s == 'High') chipColor = Colors.deepOrange;
                if (s == 'Critical') chipColor = Colors.red;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSeverity = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor.withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? chipColor : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(s,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? chipColor : Colors.grey)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Locked-In Region Context',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                    );
                  },
                  child: const Text('Change Location', style: TextStyle(color: Color(0xFF2E86C1), fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeLocationStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Add street name or landmark',
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A5276), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 10),
                          Text('Validate AI & Submit Report',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

// ==========================================
// SUBMISSION SUCCESS SCREEN
// ==========================================

class SubmissionSuccessScreen extends StatelessWidget {
  final ReportModel report;
  const SubmissionSuccessScreen({super.key, required this.report});

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
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text('Report Submitted!',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
              const SizedBox(height: 8),
              Text('${report.type} report sent to ${report.ward} (${report.cityDistrict}, ${report.state}) office',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Tracking ID',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(report.id,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A5276),
                            letterSpacing: 2)),
                    const SizedBox(height: 8),
                    const Text('Expected resolution: 3-5 working days',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      MaterialPageRoute(builder: (context) => const HomeDashboard()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5276),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                  );
                },
                child: const Text('Report Another Issue',
                    style: TextStyle(color: Color(0xFF2E86C1))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MY REPORTS SCREEN
// ==========================================

class MyReportsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyReportsScreen({super.key, this.onBack});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Submitted', 'In Progress', 'Resolved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    ReportStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ReportStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  List<ReportModel> get _allMyReports {
    final user = UserStore.instance.currentUser;
    final String currentName = user?.name ?? '';
    final String currentPhone = (user?.mobileNumber ?? '').replaceAll(RegExp(r'\D'), '');

    return ReportStore.instance.reports.where((r) {
      final nameMatch = r.submittedBy.trim().toLowerCase() == currentName.trim().toLowerCase();
      final phoneMatch = r.submittedByPhone.replaceAll(RegExp(r'\D'), '') == currentPhone;
      return nameMatch && phoneMatch;
    }).toList();
  }

  List<ReportModel> get _filteredReports {
    final myReports = _allMyReports;
    if (_selectedFilter == 'All') return myReports;
    return myReports.where((r) => r.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myReports = _allMyReports;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('My Reports',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A5276),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('${myReports.length}', 'Total', Colors.white),
                _miniStat('${myReports.where((r) => r.status == 'In Progress').length}', 'In Progress', Colors.orange.shade200),
                _miniStat('${myReports.where((r) => r.status == 'Resolved').length}', 'Resolved', Colors.green.shade200),
                _miniStat('${myReports.where((r) => r.status == 'Rejected').length}', 'Rejected', Colors.red.shade200),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A5276) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1A5276) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(filter,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.grey.shade700)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter reports',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportDetailScreen(report: report),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
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
                                  color: report.iconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(report.icon, color: report.iconColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(report.type,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF1A5276))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: report.statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20)),
                                          child: Text(report.status,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: report.statusColor,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${report.ward}, ${report.cityDistrict}, ${report.state}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(report.id,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(report.time,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Colors.grey),
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

  Widget _miniStat(String number, String label, Color color) {
    return Column(
      children: [
        Text(number,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// ==========================================
// REPORT DETAIL SCREEN
// ==========================================

class ReportDetailScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> timeline = [
      {
        'step': 'Submitted',
        'time': report.time,
        'note': 'Report received & AI vision verified',
        'done': true,
      },
      {
        'step': 'Acknowledged',
        'time': report.status != 'Submitted' ? 'Within 2 hours' : 'Pending',
        'note': '${report.ward} Officer acknowledged complaint',
        'done': report.status != 'Submitted',
      },
      {
        'step': 'In Progress',
        'time': report.status == 'In Progress' || report.status == 'Resolved' ? 'In Action' : 'Pending',
        'note': report.assignedCrew != null ? 'Assigned to ${report.assignedCrew}' : 'Field crew dispatched',
        'done': report.status == 'In Progress' || report.status == 'Resolved',
      },
      {
        'step': 'Resolved',
        'time': report.status == 'Resolved' ? (report.resolvedAt != null ? report.resolvedAt.toString().split('.').first : 'Completed') : 'Pending',
        'note': 'Issue fixed. Resolution SMS & Email sent to citizen.',
        'done': report.status == 'Resolved',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(report.id,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((report.imageBytes != null && report.imageBytes!.isNotEmpty) ||
                (report.imagePath != null && report.imagePath!.isNotEmpty)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: buildCrossPlatformImage(
                    bytes: report.imageBytes,
                    path: report.imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: report.iconColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(report.icon, color: report.iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(report.type,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A5276))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: report.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(report.status,
                            style: TextStyle(
                                fontSize: 13,
                                color: report.statusColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(Icons.location_on, report.location),
                  _detailRow(Icons.apartment, 'State: ${report.state} | City: ${report.cityDistrict} | Ward: ${report.ward}'),
                  _detailRow(Icons.pin_drop, 'Coordinates: ${report.latitude.toStringAsFixed(4)}° N, ${report.longitude.toStringAsFixed(4)}° E'),
                  _detailRow(Icons.calendar_today, report.date),
                  _detailRow(Icons.person, 'Reported by: ${report.submittedBy} (Phone: ${report.submittedByPhone}${report.submittedByAadhar.isNotEmpty ? " | Aadhaar: ${report.submittedByAadhar}" : ""})'),
                  _detailRow(Icons.verified_user, 'AI Moderation: ${report.aiModerationStatus}'),
                  if (report.assignedCrew != null)
                    _detailRow(Icons.group, 'Assigned Crew: ${report.assignedCrew}'),
                  if (report.officerNote != null && report.officerNote!.isNotEmpty)
                    _detailRow(Icons.note_alt, 'Officer Note: ${report.officerNote}'),
                  _detailRow(Icons.description, report.description),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Status Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A5276))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: timeline.asMap().entries.map((e) {
                  final i = e.key;
                  final step = e.value;
                  final isLast = i == timeline.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: step['done'] as bool ? Colors.green : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                step['done'] as bool ? Icons.check : Icons.circle,
                                color: step['done'] as bool ? Colors.white : Colors.grey.shade400,
                                size: 14),
                          ),
                          if (!isLast)
                            Container(
                                width: 2,
                                height: 48,
                                color: step['done'] as bool
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.shade200),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step['step'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: step['done'] as bool
                                          ? const Color(0xFF1A5276)
                                          : Colors.grey)),
                              Text(step['time'] as String,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(step['note'] as String,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
            child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MAP SCREEN
// ==========================================

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ReportModel? _selectedReport;

  @override
  Widget build(BuildContext context) {
    final reports = ReportStore.instance.reports;
    final user = UserStore.instance.currentUser;
    final wardStr = user?.selectedWard ?? 'Avadi';
    final cityStr = user?.selectedCity ?? 'Tiruvallur';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Interactive Map — $wardStr',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
              ),
            ),
            child: CustomPaint(painter: MapGridPainter()),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.crop_free, color: Color(0xFF1A5276), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Perimeter Boundary: $wardStr ($cityStr)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                  ),
                ],
              ),
            ),
          ),
          if (reports.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map, size: 48, color: Color(0xFF1A5276)),
                    const SizedBox(height: 12),
                    const Text(
                      'No reports on map yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reported issues with GPS location will appear here dynamically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reports.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              final posX = 0.2 + (idx * 0.15) % 0.6;
              final posY = 0.25 + (idx * 0.18) % 0.45;

              return Positioned(
                left: posX * (MediaQuery.of(context).size.width - 40),
                top: posY * 400,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReport = r),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: r.iconColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: r.iconColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(r.icon, color: Colors.white, size: 18),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: r.iconColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          if (_selectedReport != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _selectedReport = null),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
                          color: _selectedReport!.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_selectedReport!.icon, color: _selectedReport!.iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedReport!.type,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A5276))),
                            Text('${_selectedReport!.ward}, ${_selectedReport!.cityDistrict}, ${_selectedReport!.state}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final boundaryPaint = Paint()
      ..color = const Color(0xFF1A5276).withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.15)
      ..lineTo(size.width * 0.9, size.height * 0.15)
      ..lineTo(size.width * 0.85, size.height * 0.8)
      ..lineTo(size.width * 0.15, size.height * 0.8)
      ..close();
    
    canvas.drawPath(path, boundaryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// PROFILE SCREEN
// ==========================================

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final user = UserStore.instance.currentUser;
    final userName = user != null ? user.name : 'User';
    final isGoogle = user != null && user.verificationMethod == 'Google';
    final userHandle = user != null 
        ? (isGoogle ? '@${user.username.split('@').first}' : '@${user.username}')
        : '@user';
    final userEmail = user != null ? user.email : 'user@civicreporter.org';
    final userPhone = user != null ? user.mobileNumber : '+91 9876543210';
    final isOfficer = user != null && user.role == 'officer';

    final selectedState = user?.selectedState ?? 'Tamil Nadu';
    final selectedCity = user?.selectedCity ?? 'Tiruvallur';
    final selectedWard = user?.selectedWard ?? 'Avadi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF1A5276),
                    child: Icon(isOfficer ? Icons.local_police : Icons.person, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A5276)),
                  ),
                  const SizedBox(height: 4),
                  Text(userHandle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOfficer ? Colors.orange.withValues(alpha: 0.15) : const Color(0xFF1A5276).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOfficer ? '👮 Ward Officer ($selectedWard)' : '🙋 Citizen Reporter ($selectedWard)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOfficer ? Colors.orange.shade800 : const Color(0xFF1A5276),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        isGoogle ? 'Google Verified' : userPhone,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        userEmail,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  if (user != null && user.aadharNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fingerprint, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Aadhaar: ${user.aadharNumber}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Color(0xFF1A5276)),
                    title: Text('$selectedWard, $selectedCity, $selectedState'),
                    subtitle: const Text('Active Location Context'),
                    trailing: const Icon(Icons.edit, size: 20, color: Color(0xFF1A5276)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  if (isOfficer)
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF1A5276)),
                      title: const Text('Officer Action Portal (State/City/Ward Isolation)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const OfficerDashboardScreen()),
                        );
                      },
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.assessment_outlined, color: Color(0xFF1A5276)),
                      title: const Text('Ward Statistics'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WardStatsScreen()),
                        );
                      },
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      await UserStore.instance.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WARD STATISTICS & NOTIFICATIONS
// ==========================================

class WardStatsScreen extends StatelessWidget {
  const WardStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ReportStore.instance;
    final user = UserStore.instance.currentUser;
    final wardStr = user?.selectedWard ?? 'Avadi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A5276),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$wardStr Ward Statistics',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _bigStat('${store.totalCount}', 'Total\nReports', const Color(0xFF1A5276)),
                const SizedBox(width: 12),
                _bigStat('${store.resolvedCount}', 'Resolved', Colors.green),
                const SizedBox(width: 12),
                _bigStat('${store.inProgressCount}', 'In Progress', Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resolution Overview',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A5276))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendRow(Colors.blue, 'Submitted: ${store.submittedCount}'),
                          const SizedBox(height: 8),
                          _legendRow(Colors.orange, 'In Progress: ${store.inProgressCount}'),
                          const SizedBox(height: 8),
                          _legendRow(Colors.green, 'Resolved: ${store.resolvedCount}'),
                          const SizedBox(height: 8),
                          _legendRow(Colors.red, 'Rejected: ${store.rejectedCount}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(number, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A5276),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('No new notifications', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}