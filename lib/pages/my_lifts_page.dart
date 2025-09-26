import 'dart:async';
import 'package:flutter/material.dart';

import '../models/task_models.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

// Simple observer for app lifecycle changes
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  
  AppLifecycleObserver({required this.onResume});
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class MyLiftsPage extends StatefulWidget {
  const MyLiftsPage({super.key});

  @override
  State<MyLiftsPage> createState() => _MyLiftsPageState();
}

class _MyLiftsPageState extends State<MyLiftsPage> {
  final TaskService _taskService = TaskService.instance;
  final NotificationService _notificationService = NotificationService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  static const int _persistentNotificationId = 1000;

  Timer? _refreshTimer;

  // Track the last time we refreshed tasks
  DateTime? _lastRefreshTime;
  late final AppLifecycleObserver _appLifecycleObserver;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the lifecycle observer
    _appLifecycleObserver = AppLifecycleObserver(
      onResume: () {
        // Only refresh if it's been more than 5 minutes since last refresh
        if (_lastRefreshTime == null || 
            DateTime.now().difference(_lastRefreshTime!) > const Duration(minutes: 5)) {
          _refreshTasks();
        }
      },
    );
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);
    
    // Initial load
    _loadTasks();
    _notificationService.initialize();
    _setupPersistentNotification();
    
    // Refresh tasks every minute to update progress
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _refreshTasks();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_appLifecycleObserver);
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getTasks();
      print('Loaded ${tasks.length} tasks');
      
      final updatedTasks = <Task>[];
      final now = DateTime.now();
      
      for (var task in tasks) {
        print('Task: ${task.name}, Pinned: ${task.isPinned}');
        
        // Calculate the expected value based on time elapsed
        final expectedValue = task.expectedValue;
        
        // For each task, update the current value to match expected progress
        final updatedTask = task.copyWith(
          lastUpdated: now,
          currentValue: expectedValue, // Update current value to match expected progress
        );
        
        // Log the current state of the task
        print('Type: ${task.progressionType} (${task.isDecrementing ? 'Decrementing' : 'Incrementing'})');
        print('Starting Value: ${task.startingValue}');
        print('Current Value: ${task.currentValue} -> ${updatedTask.currentValue}');
        print('Expected Value: $expectedValue');
        print('Target Value: ${task.targetValue}');
        print('Progress: ${task.progressPercentage.toStringAsFixed(2)}% -> ${updatedTask.progressPercentage.toStringAsFixed(2)}%');
        print('Days since creation: ${task.daysSinceCreation}');
        print('---');
        
        updatedTasks.add(updatedTask);
      }
      
      // Save the updated tasks
      if (updatedTasks.isNotEmpty) {
        await _taskService.saveTasks(updatedTasks);
      }
      
      setState(() {
        _tasks = updatedTasks; // Use the updated tasks with recalculated values
        _lastRefreshTime = now;
        print('Task list updated in state at ${_lastRefreshTime}');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshTasks() async {
    if (!mounted) return;
    
    try {
      final tasks = await _taskService.getTasks();
      final now = DateTime.now();
      
      final updatedTasks = <Task>[];
      bool hasChanges = false;
      
      for (var task in tasks) {
        // Calculate the expected value based on time elapsed
        final expectedValue = task.expectedValue;
        
        // Only update if the expected value is different from current value
        final shouldUpdate = task.isDecrementing 
            ? expectedValue < task.currentValue
            : expectedValue > task.currentValue;
        
        // If no update is needed, keep the existing task
        if (!shouldUpdate) {
          updatedTasks.add(task);
          continue;
        }
        
        // Update the task with the new current value
        final updatedTask = task.copyWith(
          lastUpdated: now,
          currentValue: expectedValue,
        );
        
        // Log the update
        print('Updating task: ${task.name}');
        print('Type: ${task.progressionType} (${task.isDecrementing ? 'Decrementing' : 'Incrementing'})');
        print('Starting Value: ${task.startingValue}');
        print('Current Value: ${task.currentValue} -> ${updatedTask.currentValue}');
        print('Expected Value: $expectedValue');
        print('Target Value: ${task.targetValue}');
        print('Progress: ${task.progressPercentage.toStringAsFixed(2)}% -> ${updatedTask.progressPercentage.toStringAsFixed(2)}%');
        print('---');
        
        updatedTasks.add(updatedTask);
        hasChanges = true;
      }
      
      // Only save if there are actual changes
      if (hasChanges && updatedTasks.isNotEmpty) {
        await _taskService.saveTasks(updatedTasks);
      }
      
      if (mounted) {
        setState(() {
          _tasks = updatedTasks;
          _lastRefreshTime = now;
          print('Tasks refreshed at ${_lastRefreshTime}');
        });
      }
    } catch (e) {
      print('Error refreshing tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh tasks. Pull down to retry.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int get _pinnedTaskCount => _tasks.where((task) => task.isPinned).length;

  Future<void> _toggleTaskPin(Task task, bool isPinned) async {
    try {
      print('Toggling pin for task ${task.id} to $isPinned');
      
      // Check if we're trying to pin a new task when already at max pins
      if (isPinned && _pinnedTaskCount >= 3 && !task.isPinned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only pin up to 3 tasks at a time'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Update local state immediately for better UX
      setState(() {
        final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(isPinned: isPinned);
        }
      });
      
      // Update in database
      final updatedTask = task.copyWith(isPinned: isPinned);
      await _taskService.updateTask(updatedTask);
      
      // Cancel notification if task is being unpinned
      if (!isPinned) {
        await _notificationService.cancelTaskNotification(task.id);
      } else {
        // Update notification if task is being pinned
        await _notificationService.updateTaskNotification(updatedTask);
      }
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPinned ? 'Task pinned' : 'Task unpinned'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Error toggling pin: $e');
      // Revert UI on error
      setState(() {
        final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(isPinned: !isPinned);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task')),
        );
      }
    }
  }

  Future<void> _setupPersistentNotification() async {
    await _notificationService.initialize();
    // Clear any existing persistent notifications
    await _notificationService.cancel(_persistentNotificationId);
    
    // No longer showing persistent notifications for pinned tasks
    // as per user request
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return TaskCard(
                      key: ValueKey('${task.id}_${task.isPinned}'), // Include isPinned in the key
                      task: task,
                      onTaskUpdated: _refreshTasks,
                      onLogProgress: () => _showLogProgressDialog(task),
                      onDelete: () => _showDeleteConfirmation(task),
                      onPinToggled: (isPinned) => _toggleTaskPin(task, isPinned),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No lifts yet!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to create task screen
            },
            child: const Text('Create Your First Lift'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogProgressDialog(Task task) async {
    // TODO: Implement log progress dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Progress'),
        content: const Text('Progress logging will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTask(task);
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      // Cancel any existing notifications for this task
      await _notificationService.cancelTaskNotification(task.id);
      
      // Delete the task from the database
      await _taskService.deleteTask(task.id);
      await _refreshTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${task.name}'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo functionality
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task')),
        );
      }
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTaskUpdated;
  final VoidCallback onDelete;
  final Function(bool) onPinToggled;
  final VoidCallback onLogProgress;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.onDelete,
    required this.onPinToggled,
    required this.onLogProgress,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: task.isPinned 
          ? theme.colorScheme.primary.withOpacity(0.05)
          : null,
      shape: RoundedRectangleBorder(
        side: task.isPinned
            ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: task.isPinned ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (task.isDecrementing)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Text(
                            'Decremental',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: task.isPinned 
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: task.isPinned ? theme.colorScheme.primary : null,
                      size: 20,
                    ),
                  ),
                  onPressed: () => onPinToggled(!task.isPinned),
                  tooltip: task.isPinned ? 'Unpin task' : 'Pin task',
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                task.progressPercentage >= 100 
                    ? Colors.green 
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${task.progressPercentage.toStringAsFixed(0)}%'),
                Text(
                  task.isDecrementing
                      ? '${task.currentValue.toStringAsFixed(1)} → ${task.targetValue.toStringAsFixed(1)} ${task.unit}'
                      : '${task.currentValue.toStringAsFixed(1)} / ${task.targetValue.toStringAsFixed(1)} ${task.unit}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: task.isDecrementing ? Colors.red[700] : null,
                    fontWeight: task.isDecrementing ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timeline, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Day ${task.daysSinceCreation} of ${task.estimatedEndDate.difference(task.createdAt).inDays + 1}',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(task.createdAt)} - ${_formatDate(task.estimatedEndDate)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (task.notificationTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notifications, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Reminder at ${task.notificationTime!.hour.toString().padLeft(2, '0')}:${task.notificationTime!.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onLogProgress,
                  child: const Text('LOG PROGRESS'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
