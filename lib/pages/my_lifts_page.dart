import 'package:flutter/material.dart';
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
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  static const int _persistentNotificationId = 1000; // Unique ID for persistent notification
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _notificationService.initialize();
    _setupPersistentNotification();
  }

  void _loadTasks() {
    _taskService.initializeStream();
  }

  void _refreshTasks() {
    _taskService.initializeStream();
    setState(() {
      // This will trigger a rebuild and refresh the StreamBuilder
    });
  }

  Future<void> _toggleTaskPin(Task task, bool isPinned) async {
    final updatedTask = task.copyWith(isPinned: isPinned);
    await _taskService.updateTask(updatedTask);
    _refreshTasks();
  }

  Future<void> _updatePersistentNotification() async {
    final tasks = await _taskService.getTasks();
    final pinnedTasks = tasks.where((task) => task.isPinned).toList();
    
    if (pinnedTasks.isEmpty) {
      await _notificationService.cancel(_persistentNotificationId);
      return;
    }

    final notificationContent = StringBuffer("📌 Pinned Tasks\n");
    for (var task in pinnedTasks.take(3)) { // Show up to 3 tasks
      final progress = ((task.currentValue / task.targetValue) * 100).toStringAsFixed(1);
      notificationContent.write("• ${task.name}: $progress%\n");
    }
    
    if (pinnedTasks.length > 3) {
      notificationContent.write("and ${pinnedTasks.length - 3} more...");
    }

    await _notificationService.showPersistentNotification(
      id: _persistentNotificationId,
      title: '📌 Track Your Progress',
      body: notificationContent.toString(),
    );
  }

  Future<void> _setupPersistentNotification() async {
    // Request notification permissions if not already granted
    await _notificationService.initialize();
    await _updatePersistentNotification();
  }

  Future<void> _testNotification() async {
    try {
      // First test a simple notification
      await NotificationService().showTestNotification();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔔 Test notification sent! Check your notification panel.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Notification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Task task) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.delete_forever, size: 60, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Delete Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "${task.name}"?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _deleteTask(task);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _taskService.deleteTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ "${task.name}" has been deleted'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality if needed
              },
            ),
          ),
        );
      }

      _refreshTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF8B4513),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Raise the Bull',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B4513),
                      Color(0xFFD2691E),
                      Color(0xFFDEB887),
                    ],
                  ),
                ),
                child: const Center(child: MiloLogo()),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: _testNotification,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshTasks,
                ),
              ),
            ],
          ),
          StreamBuilder<List<Task>>(
            stream: _taskService.tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              final tasks = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTaskUpdated: _refreshTasks,
                      onLogProgress: () => _showLogProgressDialog(task),
                      onDelete: () => _showDeleteConfirmation(task),
                      onPinToggled: (isPinned) => _toggleTaskPin(task, isPinned),
                    );
                  }, childCount: tasks.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Tasks Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first task in the Set Load tab',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showLogProgressDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => LogProgressDialog(
        task: task,
        onProgressLogged: (entry) async {
          await _taskService.addTaskEntry(task.id, entry);
          // Force refresh to ensure UI updates immediately
          _refreshTasks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Progress logged for ${task.name}!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTaskUpdated;
  final VoidCallback onLogProgress;
  final VoidCallback onDelete;
  final Function(bool) onPinToggled;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.onLogProgress,
    required this.onDelete,
    required this.onPinToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress from starting value to target value
    final totalRange = task.targetValue - task.startingValue;
    final currentProgress = task.currentValue - task.startingValue;
    final progress = totalRange > 0
        ? (currentProgress / totalRange).clamp(0.0, 1.0)
        : 0.0;
    
    // Debug print to check values
    print('Task: ${task.name}');
    print('Starting: ${task.startingValue}, Current: ${task.currentValue}, Target: ${task.targetValue}');
    print('Progress: ${(progress * 100).toStringAsFixed(1)}%');

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    task.type == TaskType.timeBased
                        ? Icons.timer
                        : Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: task.isPinned 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey,
                    ),
                    onPressed: () => onPinToggled(!task.isPinned),
                    tooltip: task.isPinned ? 'Unpin task' : 'Pin task',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: onLogProgress,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Days since creation and notification status
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Day ${DateTime.now().difference(task.createdAt).inDays + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (task.notificationsEnabled) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.notificationTime?.format(context) ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: ${_formatValue(task.currentValue, task)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_formatValue(task.currentValue, task)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      ' / ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_formatValue(task.targetValue, task)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.add, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Next: +${_formatValue(task.incrementValue, task)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (task.entries.isNotEmpty)
                              Text(
                                'Last: ${_formatDate(task.lastUpdated)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value, Task task) {
    final formattedNumber = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );

    if (task.type == TaskType.timeBased) {
      // For time-based tasks, value represents minutes - convert to HH:MM format
      final totalMinutes = value.toInt();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '$formattedNumber ${task.unit}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class LogProgressDialog extends StatefulWidget {
  final Task task;
  final Function(TaskEntry) onProgressLogged;

  const LogProgressDialog({
    super.key,
    required this.task,
    required this.onProgressLogged,
  });

  @override
  State<LogProgressDialog> createState() => _LogProgressDialogState();
}

class _LogProgressDialogState extends State<LogProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _useNextValue = true;

  @override
  void initState() {
    super.initState();
    final nextValue = widget.task.currentValue + widget.task.incrementValue;
    _valueController.text = nextValue.toStringAsFixed(
      nextValue.truncateToDouble() == nextValue ? 0 : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log Progress - ${widget.task.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _useNextValue,
                  onChanged: (value) {
                    setState(() {
                      _useNextValue = value ?? true;
                      if (_useNextValue) {
                        final nextValue =
                            widget.task.currentValue +
                            widget.task.incrementValue;
                        _valueController.text = nextValue.toStringAsFixed(
                          nextValue.truncateToDouble() == nextValue ? 0 : 1,
                        );
                      }
                    });
                  },
                ),
                const Expanded(child: Text('Use suggested next value')),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value Achieved',
                suffixText: widget.task.unit,
              ),
              keyboardType: TextInputType.number,
              enabled: !_useNextValue,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel? Any observations?',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _logProgress,
          child: const Text('Log Progress'),
        ),
      ],
    );
  }

  void _logProgress() {
    if (_formKey.currentState!.validate()) {
      final entry = TaskEntry(
        id: TaskService.instance.generateId(),
        taskId: widget.task.id,
        value: double.parse(_valueController.text),
        completedAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onProgressLogged(entry);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
