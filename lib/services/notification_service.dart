import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!task.notificationsEnabled || task.notificationTime == null) return;

    await initialize();

    final notificationTime = task.notificationTime!;
    final now = DateTime.now();
    
    // Create the scheduled time for today
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('Scheduling notification for ${task.name} at $scheduledDate');

    // Calculate days since task creation for progress tracking
    final daysSinceCreation = DateTime.now().difference(task.createdAt).inDays + 1;
    final progressPercentage = ((task.currentValue / task.targetValue) * 100).clamp(0, 100);

    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Daily reminders for your progressive overload tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercentage.round(),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      icon: '@mipmap/launcher_icon',
      autoCancel: false,
      ongoing: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = _buildNotificationBody(task, daysSinceCreation, progressPercentage.toDouble());

    try {
      // First cancel any existing notification for this task
      await _notifications.cancel(task.id.hashCode);
      
      // Convert to timezone-aware datetime
      final scheduledTz = tz.TZDateTime.from(scheduledDate, tz.local);
      
      // Schedule the notification for the specific time
      await _notifications.zonedSchedule(
        task.id.hashCode,
        '🏋️ Time for ${task.name}!',
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at this time
      );
      
      // Also schedule an immediate test notification to verify the system works
      await _notifications.show(
        task.id.hashCode + 10000, // Different ID for test
        '🏋️ SCHEDULED: ${task.name}',
        'Task notification has been scheduled for ${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}. You will receive daily reminders at this time.',
        notificationDetails,
      );
      
      print('Notification scheduled successfully for ${task.name} at ${scheduledTz}');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  String _buildNotificationBody(Task task, int daysSinceCreation, double progressPercentage) {
    final currentValueStr = task.type == TaskType.timeBased 
        ? _formatMinutesToTime(task.currentValue)
        : '${task.currentValue.toStringAsFixed(task.currentValue.truncateToDouble() == task.currentValue ? 0 : 1)} ${task.unit}';
    
    final targetValueStr = task.type == TaskType.timeBased 
        ? _formatMinutesToTime(task.targetValue)
        : '${task.targetValue.toStringAsFixed(task.targetValue.truncateToDouble() == task.targetValue ? 0 : 1)} ${task.unit}';

    return 'Day $daysSinceCreation • Current: $currentValueStr → Target: $targetValueStr (${progressPercentage.toStringAsFixed(0)}% complete)';
  }

  String _formatMinutesToTime(double minutes) {
    final hours = (minutes / 60).floor();
    final mins = (minutes % 60).round();
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }


  Future<void> cancelTaskNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  Future<void> updateTaskNotification(Task task) async {
    await cancelTaskNotification(task.id);
    if (task.notificationsEnabled) {
      await scheduleTaskNotification(task);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<bool> requestPermissions() async {
    await initialize();
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    
    return true;
  }

  // Test notification to verify the system is working
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      '🏋️ Milo Test Notification',
      'This is a test notification to verify your notification system is working!',
      platformDetails,
    );
  }

  /// Shows a persistent notification that stays in the notification shade
  Future<void> showPersistentNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'persistent_channel',
      'Persistent Notifications',
      channelDescription: 'Shows ongoing progress for pinned tasks',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  /// Cancels a notification by ID
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // Show immediate notification for debugging
  Future<void> showImmediateTaskNotification(Task task) async {
    await initialize();

    final daysSinceCreation = DateTime.now().difference(task.createdAt).inDays + 1;
    final progressPercentage = ((task.currentValue / task.targetValue) * 100).clamp(0, 100);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Daily reminders for your progressive overload tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = _buildNotificationBody(task, daysSinceCreation, progressPercentage.toDouble());

    await _notifications.show(
      task.id.hashCode + 1000, // Different ID for immediate notifications
      '🏋️ Time for ${task.name}!',
      body,
      notificationDetails,
    );
  }
}
