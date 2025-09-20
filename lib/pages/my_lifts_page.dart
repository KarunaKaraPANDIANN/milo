import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_models.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import '../widgets/milo_logo.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _notificationService.initialize();
    _setupPersistentNotification();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getTasks();
      print('Loaded ${tasks.length} tasks');
      for (var task in tasks) {
        print('Task: ${task.name}, Pinned: ${task.isPinned}');
      }
      setState(() {
        _tasks = tasks;
        print('Task list updated in state');
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
    await _loadTasks();
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
