import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../models/task_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(String?)? _onNotificationTap;

  Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_initialized) return;

    _onNotificationTap = onNotificationTap;

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (details.payload != null) {
          _onNotificationTap?.call(details.payload);
        }
      },
    );

    _initialized = true;
  }

  // Generate a consistent notification ID for a task
  int _getNotificationId(String taskId) {
    try {
      // Ensure we have a non-empty string
      if (taskId.isEmpty) {
        print('Warning: Empty task ID provided, using default ID');
        return 0;
      }

      // If the ID is a numeric string, parse it directly
      if (RegExp(r'^\d+$').hasMatch(taskId)) {
        final id = int.parse(taskId);
        return id.abs() % 1000000;
      }

      // For non-numeric IDs, use the hash code
      final hash = taskId.hashCode.abs();
      final id = hash % 1000000;
      print('Generated notification ID $id for task: $taskId');
      return id;
    } catch (e) {
      print('Error generating notification ID for task $taskId: $e');
      // Fallback to a simple hash if anything goes wrong
      return taskId.hashCode.abs() % 1000000;
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    // Only schedule notifications for pinned tasks
    if (!task.isPinned) {
      return;
    }

    print('Scheduling notification for task: ${task.name}');

    await initialize();

    // Check if we can schedule exact alarms (required for Android 12+)
    final bool canScheduleExactAlarms =
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestExactAlarmsPermission() ??
        false;

    if (!canScheduleExactAlarms) {
      print(
        'Exact alarms permission not granted, scheduling with inexact timing',
      );
    }

    // Use the task's notification time or default to 9 AM
    final notificationTime =
        task.notificationTime ?? const TimeOfDay(hour: 9, minute: 0);
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

    print('Scheduling daily notification for ${task.name} at $scheduledDate');

    // Calculate progress based on expected value
    final daysSinceCreation = task.daysSinceCreation;
    final expectedValue = task.expectedValue;
    final progressPercentage = task.isDecrementing
        ? ((task.startingValue - expectedValue) / (task.startingValue - task.targetValue) * 100).clamp(0, 100)
        : ((expectedValue - task.startingValue) / (task.targetValue - task.startingValue) * 100).clamp(0, 100);

    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Daily reminders for your progressive overload tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      showProgress: true,
      maxProgress: 200, // Increased to 200 to allow for overachievement
      progress: progressPercentage.round(),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      icon: '@mipmap/launcher_icon',
      autoCancel: false,
      ongoing: true, // Make it ongoing so it stays in the notification shade
      channelShowBadge: true,
      styleInformation: BigTextStyleInformation(''),
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      threadIdentifier: 'task_reminders',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final body = _buildNotificationBody(
      task,
      daysSinceCreation,
      progressPercentage.toDouble(),
    );

    try {
      // First cancel any existing notification for this task
      await _notifications.cancel(_getNotificationId(task.id));

      // Get the timezone location
      final location = tz.getLocation(tz.local.name);

      // Create the first scheduled time
      var scheduledTz = tz.TZDateTime(
        location,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );

      // If the time has already passed today, schedule for the same time tomorrow
      final now = tz.TZDateTime.now(location);
      if (scheduledTz.isBefore(now)) {
        scheduledTz = scheduledTz.add(const Duration(days: 1));
      }

      print(
        'Scheduling daily notification for ${task.name} at $scheduledTz (timezone: ${tz.local.name})',
      );

      // Schedule the notification to repeat daily
      await _notifications.zonedSchedule(
        _getNotificationId(task.id),
        '🏋️ ${task.name} Progress Update',
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: canScheduleExactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at this time
        payload:
            task.id, // Store task ID in payload for handling notification taps
      );

      print(
        'Successfully scheduled notification for ${task.name} at ${scheduledTz.hour}:${scheduledTz.minute}',
      );

      // Also schedule an immediate test notification to verify the system works
      await _notifications.show(
        _getNotificationId(task.id) + 10000, // Different ID for test
        '🏋️ SCHEDULED: ${task.name}',
        '',
        notificationDetails,
      );

      print(
        'Notification scheduled successfully for ${task.name} at ${scheduledTz}',
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  String _buildNotificationBody(
    Task task,
    int daysSinceCreation,
    double progressPercentage,
  ) {
    final progressBar =
        '${'▰' * (progressPercentage ~/ 10)}${'▱' * (10 - (progressPercentage ~/ 10))}';

    final currentValue = task.currentValue;
    final expectedValue = task.expectedValue;

    // Calculate progress based on expected value
    final expectedProgress = task.isDecrementing
        ? ((task.startingValue - expectedValue) / (task.startingValue - task.targetValue) * 100).clamp(0, 100)
        : ((expectedValue - task.startingValue) / (task.targetValue - task.startingValue) * 100).clamp(0, 100);

    String progressStatus;
    if (task.isDecrementing) {
      if (currentValue <= task.targetValue) {
        progressStatus = '🎉 Target reached! Keep it up!';
      } else if (currentValue <= expectedValue) {
        progressStatus = '📊 On track - keep going!';
      } else {
        final remaining = currentValue - task.targetValue;
        progressStatus = '📉 ${remaining.toStringAsFixed(1)}${task.unit ?? ''} left';
      }
    } else {
      if (currentValue >= task.targetValue) {
        progressStatus = '🎉 Target reached! Amazing work!';
      } else if (currentValue >= expectedValue) {
        progressStatus = '📊 On track - keep pushing!';
      } else {
        final remaining = task.targetValue - currentValue;
        progressStatus = '📈 ${remaining.toStringAsFixed(1)}${task.unit ?? ''} to go';
      }
    }

    // Format dates
    final startDate = DateFormat('MMM d, y').format(task.createdAt);
    final endDate = task.estimatedEndDate;
    final formattedEndDate = DateFormat('MMM d, y').format(endDate);

    return '''
📅 Day $daysSinceCreation • ${progressPercentage.toStringAsFixed(1)}%
$progressBar

Current: ${currentValue.toStringAsFixed(1)}${task.unit ?? ''}
Expected: ${expectedValue.toStringAsFixed(1)}${task.unit ?? ''}
${task.isDecrementing ? 'Starting' : 'Target'}: ${task.targetValue}${task.unit ?? ''}

⏳ Timeline: $startDate → $formattedEndDate
⏱️ ${task.daysRemaining} days remaining • ${(expectedProgress / 100).toStringAsFixed(1)}x speed

$progressStatus

Tap to update your progress!''';
  }

  Future<void> cancelTaskNotification(String taskId) async {
    try {
      final notificationId = _getNotificationId(taskId);
      // Cancel all possible notification IDs for this task
      await _notifications.cancel(notificationId);
      await _notifications.cancel(notificationId + 10000);
      await _notifications.cancel(notificationId + 1000);
      print('Canceled all notifications for task: $taskId');
    } catch (e) {
      print('Error canceling notifications for task $taskId: $e');
      rethrow;
    }
  }

  Future<void> updateTaskNotification(Task task) async {
    // Cancel any existing notifications for this task
    await cancelTaskNotification(task.id);

    if (task.isPinned) {
      // If the task has a specific notification time, use that
      await scheduleTaskNotification(task);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Returns a list of all active (pending) notifications
  Future<List<PendingNotificationRequest>> getActiveNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
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

    await _notifications.show(id, title, body, platformDetails);
  }

  /// Cancels a notification by ID
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // Show immediate notification for debugging
  Future<void> showImmediateTaskNotification(Task task) async {
    await initialize();

    final daysSinceCreation =
        DateTime.now().difference(task.createdAt).inDays + 1;
    final progressPercentage = ((task.currentValue / task.targetValue) * 100)
        .clamp(0, 100);

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

    final body = _buildNotificationBody(
      task,
      daysSinceCreation,
      progressPercentage.toDouble(),
    );

    await _notifications.show(
      task.id.hashCode + 1000, // Different ID for immediate notifications
      '🏋️ Time for ${task.name}!',
      body,
      notificationDetails,
    );
  }
}
