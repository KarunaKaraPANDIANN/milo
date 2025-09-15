import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';
import '../widgets/milo_logo.dart';

class SetLoadPage extends StatefulWidget {
  const SetLoadPage({super.key});

  @override
  State<SetLoadPage> createState() => _SetLoadPageState();
}

class _SetLoadPageState extends State<SetLoadPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            backgroundColor: const Color(0xFFFF6B35),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Plant the Calf',
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
                      Color(0xFFFF6B35),
                      Color(0xFFFF8E53),
                      Color(0xFFFFA726),
                    ],
                  ),
                ),
                child: const Center(child: MiloLogo()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Your Journey',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Featured Tasks Carousel
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: TaskTypeConfig.featuredTemplates.length,
                        itemBuilder: (context, index) {
                          final template =
                              TaskTypeConfig.featuredTemplates[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _createTaskFromTemplate(template),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xFFFFA726,
                                        ).withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        template.icon,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        template.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final config = TaskTypeConfig.configs[index];
              return AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildTaskTypeCard(config, index),
                    ),
                  );
                },
              );
            }, childCount: TaskTypeConfig.configs.length),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // Space for FAB
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTaskTypeCard(TaskTypeConfig config, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: index == 0
              ? [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                  const Color(0xFF9575CD),
                ]
              : [
                  const Color(0xFF11998E),
                  const Color(0xFF38EF7D),
                  const Color(0xFF26D0CE),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                (index == 0 ? const Color(0xFF667EEA) : const Color(0xFF11998E))
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    config.type == TaskType.timeBased
                        ? Icons.timer_outlined
                        : Icons.trending_up_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.type == TaskType.timeBased
                            ? 'Time-Based Tasks'
                            : 'Unit-Based Tasks',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Popular Templates:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...config.exampleTasks.map(
              (task) => _buildTemplateItem(task, config),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCreateTaskBottomSheet(context, config),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: index == 0
                      ? const Color(0xFF667EEA)
                      : const Color(0xFF11998E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Create ${config.type == TaskType.timeBased ? 'Time' : 'Unit'}-Based Task',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateItem(String task, TaskTypeConfig config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCreateTaskBottomSheet(context, config, task),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(_getTaskIcon(task), color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTaskIcon(String task) {
    // Find matching template by name
    final template = TaskTypeConfig.allTemplates.firstWhere(
      (template) => template.name.toLowerCase() == task.toLowerCase(),
      orElse: () => TaskTypeConfig.allTemplates.firstWhere(
        (template) => task.toLowerCase().contains(template.name.toLowerCase()),
        orElse: () => const TaskTemplate(
          name: 'default',
          icon: Icons.task_alt,
          type: TaskType.unitBased,
        ),
      ),
    );
    return template.icon;
  }

  void _createTaskFromTemplate(TaskTemplate template) {
    final config = TaskTypeConfig.configs.firstWhere(
      (config) => config.type == template.type,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskBottomSheet(
        config: config,
        onTaskCreated: (task) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${task.name} created successfully!')),
          );
        },
        preselectedTemplate: template.name,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showQuickCreateDialog(),
      backgroundColor: const Color(0xFFFF6B35),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showQuickCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Quick Create',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        content: const Text('Choose task type to create:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreateTaskBottomSheet(context, TaskTypeConfig.configs[0]);
            },
            icon: const Icon(Icons.timer),
            label: const Text('Time-Based'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showCreateTaskBottomSheet(context, TaskTypeConfig.configs[1]);
            },
            icon: const Icon(Icons.trending_up),
            label: const Text('Unit-Based'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskBottomSheet(
    BuildContext context,
    TaskTypeConfig config, [
    String? preselectedTemplate,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskBottomSheet(
        config: config,
        onTaskCreated: (task) {
          TaskService.instance.addTask(task);
          _showSuccessMessage(task);
        },
        preselectedTemplate: preselectedTemplate,
      ),
    );
  }

  void _showSuccessMessage(Task task) {
    final messages = [
      "🐂 The calf grows stronger! ${task.name} added to your journey.",
      "💪 Another stone in the foundation! ${task.name} is ready to lift.",
      "🏛️ Like Milo's daily routine, ${task.name} begins your legend.",
      "⚡ The bull awakens! ${task.name} joins your progressive path.",
      "🌟 Croton would be proud! ${task.name} added successfully.",
    ];

    final randomMessage =
        messages[DateTime.now().millisecond % messages.length];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(randomMessage),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class CreateTaskBottomSheet extends StatefulWidget {
  final TaskTypeConfig config;
  final Function(Task) onTaskCreated;
  final String? preselectedTemplate;

  const CreateTaskBottomSheet({
    super.key,
    required this.config,
    required this.onTaskCreated,
    this.preselectedTemplate,
  });

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _incrementController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _frequencyController = TextEditingController();

  TimeUnit _selectedTimeUnit = TimeUnit.days;

  String? _selectedUnit;
  bool _useCustomUnit = false;
  String? _selectedTemplate;
  List<String> _customUnits = [];

  // Notification settings
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.config.type == TaskType.timeBased) {
      _selectedUnit = widget.config.defaultUnit;
    }

    if (widget.preselectedTemplate != null) {
      _selectedTemplate = widget.preselectedTemplate;
      _nameController.text = widget.preselectedTemplate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.config.type == TaskType.timeBased
                        ? [const Color(0xFF667EEA), const Color(0xFF764BA2)]
                        : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.config.type == TaskType.timeBased
                          ? Icons.timer
                          : Icons.trending_up,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create ${widget.config.type == TaskType.timeBased ? 'Time-Based' : 'Unit-Based'} Task',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.config.type == TaskType.timeBased
                          ? 'Track time-based activities like meditation or reading'
                          : 'Track measurable goals with custom units',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTemplateSelection(),
                        const SizedBox(height: 16),
                        if (widget.config.type == TaskType.unitBased) ...[
                          _buildUnitSelection(),
                          const SizedBox(height: 16),
                        ],
                        widget.config.type == TaskType.timeBased
                            ? _buildTimeField(
                                controller: _currentValueController,
                                label: 'Starting Duration',
                                hint: 'e.g., 00:05 (5 minutes)',
                              )
                            : _buildNumberField(
                                controller: _currentValueController,
                                label: 'Starting Value',
                                hint: 'Initial value to start with',
                              ),
                        const SizedBox(height: 16),
                        widget.config.type == TaskType.timeBased
                            ? _buildTimeField(
                                controller: _targetValueController,
                                label: 'Target Duration',
                                hint: 'e.g., 00:30 (30 minutes)',
                              )
                            : _buildNumberField(
                                controller: _targetValueController,
                                label: 'Target Value',
                                hint: 'Goal value to reach',
                              ),
                        const SizedBox(height: 16),
                        widget.config.type == TaskType.timeBased
                            ? _buildTimeField(
                                controller: _incrementController,
                                label: 'Increment Duration',
                                hint: 'e.g., 00:02 (2 minutes)',
                              )
                            : _buildNumberField(
                                controller: _incrementController,
                                label: 'Increment Value',
                                hint: 'How much to increase each time',
                              ),
                        const SizedBox(height: 16),
                        _buildFrequencyField(),
                        const SizedBox(height: 16),
                        _buildNotificationSettings(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _createTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      widget.config.type == TaskType.timeBased
                                      ? const Color(0xFF667EEA)
                                      : const Color(0xFF11998E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Create Task',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplateSelection() {
    if (_selectedTemplate == null) {
      return Column(
        children: [
          const Text(
            'Choose a template or create custom:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.config.exampleTasks
                .map(
                  (task) => ActionChip(
                    label: Text(task),
                    onPressed: () {
                      setState(() {
                        _selectedTemplate = task;
                        _nameController.text = task;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTemplate = 'custom';
                _nameController.clear();
              });
            },
            child: const Text('Create Custom Task'),
          ),
        ],
      );
    } else if (_selectedTemplate == 'custom') {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Custom Task Name',
                hintText: 'e.g., My Custom Activity',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedTemplate = null;
                _nameController.clear();
              });
            },
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              widget.config.type == TaskType.timeBased
                  ? Icons.timer
                  : Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTemplate!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _selectedTemplate = null;
                });
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUnitSelection() {
    return Column(
      children: [
        if (!_useCustomUnit && widget.config.unitOptions != null) ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    ...widget.config.unitOptions!.map(
                      (unit) => DropdownMenuItem(
                        value: unit.label,
                        child: Text('${unit.label} (${unit.description})'),
                      ),
                    ),
                    ..._customUnits.map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text('$unit (Custom)'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a unit';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddCustomUnitDialog,
                tooltip: 'Add custom unit',
              ),
            ],
          ),
        ],
        if (widget.config.customUnitAllowed)
          Row(
            children: [
              Checkbox(
                value: _useCustomUnit,
                onChanged: (value) {
                  setState(() {
                    _useCustomUnit = value ?? false;
                    if (_useCustomUnit) {
                      _selectedUnit = null;
                    }
                  });
                },
              ),
              const Text('Use one-time custom unit'),
            ],
          ),
        if (_useCustomUnit)
          TextFormField(
            controller: _customUnitController,
            decoration: const InputDecoration(
              labelText: 'Custom Unit',
              hintText: 'e.g., reps, pages, etc.',
            ),
            validator: (value) {
              if (_useCustomUnit && (value == null || value.isEmpty)) {
                return 'Please enter a custom unit';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildFrequencyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Increment Frequency',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Every',
                  hintText: 'e.g., 7',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Invalid number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<TimeUnit>(
                value: _selectedTimeUnit,
                decoration: const InputDecoration(labelText: 'Time Unit'),
                items: TimeUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.name.toLowerCase()),
                  );
                }).toList(),
                onChanged: (TimeUnit? value) {
                  setState(() {
                    _selectedTimeUnit = value ?? TimeUnit.days;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    suffixText: _getUnitText(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.config.type == TaskType.timeBased
                            ? const Color(0xFF667EEA)
                            : const Color(0xFF11998E),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Please enter a valid number';
                    }
                    if (number < 0) {
                      return 'Value must be positive';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: widget.config.type == TaskType.timeBased
                          ? const Color(0xFF667EEA)
                          : const Color(0xFF11998E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _adjustValue(controller, 1),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () => _adjustValue(controller, -1),
                      iconSize: 20,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _adjustValue(TextEditingController controller, double adjustment) {
    final currentValue = double.tryParse(controller.text) ?? 0;
    final newValue = (currentValue + adjustment).clamp(0, double.infinity);
    controller.text = newValue.toStringAsFixed(
      newValue.truncateToDouble() == newValue ? 0 : 1,
    );
  }

  void _showAddCustomUnitDialog() {
    final customUnitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Unit'),
        content: TextFormField(
          controller: customUnitController,
          decoration: const InputDecoration(
            labelText: 'Unit Name',
            hintText: 'e.g., reps, pages, cups',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final unit = customUnitController.text.trim();
              if (unit.isNotEmpty && !_customUnits.contains(unit)) {
                setState(() {
                  _customUnits.add(unit);
                  _selectedUnit = unit;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  inputFormatters: [TimeInputFormatter()],
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF667EEA),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a time';
                    }
                    if (!_isValidTimeFormat(value)) {
                      return 'Please enter time in HH:MM format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.white),
                  onPressed: () => _showTimePicker(controller),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isValidTimeFormat(String value) {
    final regex = RegExp(r'^\d{1,2}:\d{2}$');
    if (!regex.hasMatch(value)) return false;

    final parts = value.split(':');
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    return hours != null &&
        minutes != null &&
        hours >= 0 &&
        hours <= 23 &&
        minutes >= 0 &&
        minutes <= 59;
  }

  Widget _buildNotificationSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Notifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value ?? false;
                  });
                },
                activeColor: widget.config.type == TaskType.timeBased
                    ? const Color(0xFF667EEA)
                    : const Color(0xFF11998E),
              ),
              const Expanded(
                child: Text(
                  'Remind me daily to complete this task',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Notification time:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showNotificationTimePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.config.type == TaskType.timeBased
                          ? const Color(0xFF667EEA)
                          : const Color(0xFF11998E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _notificationTime.format(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showNotificationTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.config.type == TaskType.timeBased
                  ? const Color(0xFF667EEA)
                  : const Color(0xFF11998E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  void _showTimePicker(TextEditingController controller) async {
    final currentTime = _parseTimeFromController(controller);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: const Color(0xFF667EEA),
              dialHandColor: const Color(0xFF667EEA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  TimeOfDay _parseTimeFromController(TextEditingController controller) {
    if (controller.text.isEmpty || !_isValidTimeFormat(controller.text)) {
      return const TimeOfDay(hour: 0, minute: 5); // Default to 5 minutes
    }

    final parts = controller.text.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  double _convertTimeToMinutes(String timeString) {
    if (!_isValidTimeFormat(timeString)) return 0.0;

    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    return (hours * 60 + minutes).toDouble();
  }

  String _getUnitText() {
    if (widget.config.type == TaskType.timeBased) {
      return 'minutes';
    }
    if (_useCustomUnit) {
      return _customUnitController.text;
    }
    return _selectedUnit ?? '';
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      String taskName;
      if (_selectedTemplate != null && _selectedTemplate != 'custom') {
        taskName = _selectedTemplate!;
      } else {
        taskName = _nameController.text;
      }

      if (taskName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a template or enter a custom task name',
            ),
          ),
        );
        return;
      }

      final unit = widget.config.type == TaskType.timeBased
          ? widget.config.defaultUnit
          : (_useCustomUnit ? _customUnitController.text : _selectedUnit);

      final startingValue = widget.config.type == TaskType.timeBased
          ? _convertTimeToMinutes(_currentValueController.text)
          : double.parse(_currentValueController.text);

      final task = Task(
        id: TaskService.instance.generateId(),
        name: taskName,
        type: widget.config.type,
        progressionType: widget.config.progressionType,
        unit: unit,
        startingValue: startingValue,
        currentValue: startingValue, // Initially same as starting value
        targetValue: widget.config.type == TaskType.timeBased
            ? _convertTimeToMinutes(_targetValueController.text)
            : double.parse(_targetValueController.text),
        incrementValue: widget.config.type == TaskType.timeBased
            ? _convertTimeToMinutes(_incrementController.text)
            : double.parse(_incrementController.text),
        timerDuration: null, // Not used for time-based tasks anymore
        incrementFrequency: _frequencyController.text.isNotEmpty
            ? int.tryParse(_frequencyController.text)
            : null,
        incrementUnit: _frequencyController.text.isNotEmpty
            ? _selectedTimeUnit
            : null,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
        notificationTime: _notificationsEnabled ? _notificationTime : null,
      );

      widget.onTaskCreated(task);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentValueController.dispose();
    _targetValueController.dispose();
    _incrementController.dispose();
    _customUnitController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Remove any non-digit characters except colon
    final digitsOnly = text.replaceAll(RegExp(r'[^\d:]'), '');

    // If empty, return as is
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Split by colon to handle hours and minutes
    final parts = digitsOnly.split(':');
    String formatted = '';

    if (parts.length == 1) {
      // Only digits, no colon yet
      final digits = parts[0];
      if (digits.length <= 2) {
        formatted = digits;
      } else if (digits.length <= 4) {
        // Auto-add colon after 2 digits
        formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
      } else {
        // Limit to 4 digits total
        formatted = '${digits.substring(0, 2)}:${digits.substring(2, 4)}';
      }
    } else if (parts.length == 2) {
      // Already has colon
      String hours = parts[0];
      String minutes = parts[1];

      // Limit hours to 2 digits
      if (hours.length > 2) {
        hours = hours.substring(0, 2);
      }

      // Limit minutes to 2 digits
      if (minutes.length > 2) {
        minutes = minutes.substring(0, 2);
      }

      formatted = '$hours:$minutes';
    } else {
      // More than one colon, just take first two parts
      formatted = '${parts[0]}:${parts[1]}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
