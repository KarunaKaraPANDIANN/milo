import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'pages/set_load_page.dart';
import 'pages/my_lifts_page.dart';
import 'pages/about_page.dart';
import 'services/notification_service.dart';
import 'services/task_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data first
  tz.initializeTimeZones();
  
  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initialize(
    onNotificationTap: (payload) {
      // Handle notification tap - payload contains the task ID
      print('Notification tapped with payload: $payload');
      // You can add navigation logic here if needed
    },
  );
  await notificationService.requestPermissions();
  
  // Initialize tasks and clean up any orphaned notifications
  await TaskService.instance.initializeStream();
  await _cleanUpOrphanedNotifications();

  runApp(const MyApp());
}

/// Cleans up notifications for tasks that no longer exist in the database
Future<void> _cleanUpOrphanedNotifications() async {
  try {
    // Get all active notifications
    final activeNotifications = await NotificationService().getActiveNotifications();
    if (activeNotifications.isEmpty) return;
    
    // Get all task IDs from the database
    final tasks = await TaskService.instance.getTasks();
    final taskIds = tasks.map((task) => task.id).toSet();
    
    // Cancel notifications for tasks that don't exist anymore
    for (final notification in activeNotifications) {
      if (!taskIds.contains(notification.payload)) {
        await NotificationService().cancel(notification.id);
      }
    }
  } catch (e) {
    print('Error cleaning up orphaned notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milo - Progressive Overload',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35), // Pixar orange
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 12,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF2D3748)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFFF6B35),
          unselectedItemColor: Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SetLoadPage(),
    const MyLiftsPage(),
    const AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Set Load',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'My Lifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
