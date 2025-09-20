import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_models.dart';
import 'notification_service.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static TaskService? _instance;
  
  final StreamController<List<Task>> _tasksController = StreamController<List<Task>>.broadcast();
  
  TaskService._();
  
  static TaskService get instance {
    _instance ??= TaskService._();
    return _instance!;
  }

  Stream<List<Task>> get tasksStream => _tasksController.stream;

  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    
    final List<Task> tasks = [];
    for (final taskJson in tasksJson) {
      try {
        final task = Task.fromJson(json.decode(taskJson));
        tasks.add(task);
      } catch (e) {
        print('Error parsing task: $e');
        // Skip corrupted task data
        continue;
      }
    }
    
    return tasks;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks
        .map((task) => json.encode(task.toJson()))
        .toList();
    
    await prefs.setStringList(_tasksKey, tasksJson);
    
    // Notify stream listeners of the updated tasks
    _tasksController.add(tasks);
  }

  Future<void> addTask(Task task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
    
    // Schedule notification if enabled
    if (task.notificationsEnabled) {
      await NotificationService().scheduleTaskNotification(task);
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      print('Updating task: ${updatedTask.id} (${updatedTask.name})');
      final tasks = await getTasks();
      final taskId = updatedTask.id;
      final index = tasks.indexWhere((task) => task.id == taskId);
      
      if (index == -1) {
        print('Task not found: $taskId');
        return;
      }
      
      // Ensure we have a valid task ID
      if (taskId.isEmpty) {
        throw Exception('Cannot update task with empty ID');
      }
      
      // Update the task
      tasks[index] = updatedTask;
      await saveTasks(tasks);
      
      // Update notification if needed
      if (updatedTask.isPinned && updatedTask.notificationsEnabled) {
        print('Updating notification for task: $taskId');
        await NotificationService().updateTaskNotification(updatedTask);
      } else {
        print('Canceling notification for task: $taskId');
        await NotificationService().cancelTaskNotification(taskId);
      }
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
    
    // Cancel notification
    await NotificationService().cancelTaskNotification(taskId);
  }

  Future<void> addTaskEntry(String taskId, TaskEntry entry) async {
    final tasks = await getTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      final updatedEntries = [...task.entries, entry];
      
      // Update current value based on the new entry
      final updatedTask = task.copyWith(
        entries: updatedEntries,
        currentValue: entry.value,
        lastUpdated: DateTime.now(),
      );
      
      tasks[taskIndex] = updatedTask;
      await saveTasks(tasks);
      
      // Debug print to verify update
      print('Task updated: ${updatedTask.name}');
      print('New current value: ${updatedTask.currentValue}');
      print('Progress entries count: ${updatedTask.entries.length}');
    }
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Initialize the stream with current tasks
  Future<void> initializeStream() async {
    final tasks = await getTasks();
    _tasksController.add(tasks);
  }

  Future<void> clearAllTasks() async {
    // First cancel all notifications
    await NotificationService().cancelAllNotifications();
    
    // Then clear the tasks from storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    _tasksController.add([]);
  }

  void dispose() {
    _tasksController.close();
  }
}
