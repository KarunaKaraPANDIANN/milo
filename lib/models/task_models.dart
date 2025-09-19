import 'package:flutter/material.dart';

enum TaskType { timeBased, unitBased }

enum ProgressionType { linear, exponential }

enum TimeUnit { days, weeks, months, years }

class UnitOption {
  final String label;
  final String description;

  const UnitOption({required this.label, required this.description});

  Map<String, dynamic> toJson() {
    return {'label': label, 'description': description};
  }

  factory UnitOption.fromJson(Map<String, dynamic> json) {
    return UnitOption(label: json['label'], description: json['description']);
  }
}

class Task {
  final String id;
  final String name;
  final TaskType type;
  final ProgressionType progressionType;
  final String? unit; // For unit-based tasks
  final double startingValue; // Original starting value when task was created
  final double currentValue;
  final double targetValue;
  final double incrementValue;
  final Duration?
  timerDuration; // For time-based tasks - timer duration in hh:mm:ss
  final int? incrementFrequency; // Number of time units between increments
  final TimeUnit?
  incrementUnit; // Unit for increment frequency (days/weeks/months/years)
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<TaskEntry> entries;
  final bool notificationsEnabled;
  final TimeOfDay? notificationTime;
  final bool isPinned;

  Task({
    required this.id,
    required this.name,
    required this.type,
    required this.progressionType,
    this.unit,
    required this.startingValue,
    required this.currentValue,
    required this.targetValue,
    required this.incrementValue,
    this.timerDuration,
    this.incrementFrequency,
    this.incrementUnit,
    required this.createdAt,
    required this.lastUpdated,
    this.entries = const [],
    this.notificationsEnabled = false,
    this.notificationTime,
    this.isPinned = false,
  });

  /// Calculates the estimated end date based on the current progress and increment value
  DateTime get estimatedEndDate {
    final remainingValue = targetValue - startingValue;
    final totalIncrements = (remainingValue / incrementValue).ceil();
    
    if (incrementFrequency == null || incrementUnit == null) {
      return DateTime.now();
    }
    
    Duration incrementDuration;
    switch (incrementUnit) {
      case TimeUnit.days:
        incrementDuration = Duration(days: incrementFrequency!);
        break;
      case TimeUnit.weeks:
        incrementDuration = Duration(days: incrementFrequency! * 7);
        break;
      case TimeUnit.months:
        // Approximate month as 30 days for simplicity
        incrementDuration = Duration(days: incrementFrequency! * 30);
        break;
      case TimeUnit.years:
        // Approximate year as 365 days for simplicity
        incrementDuration = Duration(days: incrementFrequency! * 365);
        break;
      default:
        incrementDuration = Duration(days: incrementFrequency!);
    }
    
    return createdAt.add(incrementDuration * totalIncrements);
  }
  
  /// Returns the number of days remaining until the estimated end date
  int get daysRemaining {
    final now = DateTime.now();
    final end = estimatedEndDate;
    return end.isAfter(now) ? end.difference(now).inDays : 0;
  }
  
  /// Returns the progress percentage (0-100)
  double get progressPercentage {
    if (targetValue <= startingValue) return 100.0;
    return ((currentValue - startingValue) / (targetValue - startingValue) * 100).clamp(0.0, 100.0);
  }
  
  /// Returns the expected value based on the current date and increment schedule
  double get expectedValue {
    if (incrementFrequency == null || incrementUnit == null) {
      return startingValue;
    }
    
    final now = DateTime.now();
    final daysSinceCreation = now.difference(createdAt).inDays;
    
    double incrementMultiplier;
    switch (incrementUnit) {
      case TimeUnit.days:
        incrementMultiplier = daysSinceCreation / (incrementFrequency!);
        break;
      case TimeUnit.weeks:
        incrementMultiplier = daysSinceCreation / (incrementFrequency! * 7);
        break;
      case TimeUnit.months:
        incrementMultiplier = daysSinceCreation / (incrementFrequency! * 30);
        break;
      case TimeUnit.years:
        incrementMultiplier = daysSinceCreation / (incrementFrequency! * 365);
        break;
      default:
        incrementMultiplier = 0;
    }
    
    return (startingValue + (incrementValue * incrementMultiplier)).clamp(startingValue, targetValue);
  }
  
  /// Returns the number of days since the task was created
  int get daysSinceCreation {
    return DateTime.now().difference(createdAt).inDays + 1; // +1 to count the current day
  }

  Task copyWith({
    String? id,
    String? name,
    TaskType? type,
    ProgressionType? progressionType,
    String? unit,
    double? startingValue,
    double? currentValue,
    double? targetValue,
    double? incrementValue,
    Duration? timerDuration,
    int? incrementFrequency,
    TimeUnit? incrementUnit,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<TaskEntry>? entries,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
    bool? isPinned,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progressionType: progressionType ?? this.progressionType,
      unit: unit ?? this.unit,
      startingValue: startingValue ?? this.startingValue,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      incrementValue: incrementValue ?? this.incrementValue,
      timerDuration: timerDuration ?? this.timerDuration,
      incrementFrequency: incrementFrequency ?? this.incrementFrequency,
      incrementUnit: incrementUnit ?? this.incrementUnit,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      entries: entries ?? this.entries,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'progressionType': progressionType.index,
      'unit': unit,
      'startingValue': startingValue,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'incrementValue': incrementValue,
      'timerDuration': timerDuration?.inSeconds,
      'incrementFrequency': incrementFrequency,
      'incrementUnit': incrementUnit?.name,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime != null
          ? {'hour': notificationTime!.hour, 'minute': notificationTime!.minute}
          : null,
      'isPinned': isPinned,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle enum parsing - support both string names and integer indices
    TaskType taskType;
    if (json['type'] is String) {
      taskType = TaskType.values.firstWhere((e) => e.name == json['type']);
    } else {
      taskType = TaskType.values[json['type']];
    }

    ProgressionType progressionType;
    if (json['progressionType'] is String) {
      progressionType = ProgressionType.values.firstWhere(
        (e) => e.name == json['progressionType'],
      );
    } else {
      progressionType = ProgressionType.values[json['progressionType']];
    }

    return Task(
      id: json['id'],
      name: json['name'],
      type: taskType,
      progressionType: progressionType,
      unit: json['unit'],
      startingValue: json['startingValue'] != null
          ? (json['startingValue'] is String
                    ? double.parse(json['startingValue'])
                    : json['startingValue'])
                .toDouble()
          : (json['currentValue'] is String
                    ? double.parse(json['currentValue'])
                    : json['currentValue'])
                .toDouble(), // Fallback for old data
      currentValue:
          (json['currentValue'] is String
                  ? double.parse(json['currentValue'])
                  : json['currentValue'])
              .toDouble(),
      targetValue:
          (json['targetValue'] is String
                  ? double.parse(json['targetValue'])
                  : json['targetValue'])
              .toDouble(),
      incrementValue:
          (json['incrementValue'] is String
                  ? double.parse(json['incrementValue'])
                  : json['incrementValue'])
              .toDouble(),
      timerDuration: json['timerDuration'] != null
          ? Duration(
              seconds: json['timerDuration'] is String
                  ? int.parse(json['timerDuration'])
                  : json['timerDuration'],
            )
          : null,
      incrementFrequency: json['incrementFrequency'] != null
          ? (json['incrementFrequency'] is String
                ? int.parse(json['incrementFrequency'])
                : json['incrementFrequency'])
          : null,
      incrementUnit: json['incrementUnit'] != null
          ? TimeUnit.values.firstWhere((e) => e.name == json['incrementUnit'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      entries:
          (json['entries'] as List?)
              ?.map((e) => TaskEntry.fromJson(e))
              .toList() ??
          [],
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      notificationTime: json['notificationTime'] != null
          ? TimeOfDay(
              hour: json['notificationTime']['hour'],
              minute: json['notificationTime']['minute'],
            )
          : null,
    );
  }
}

class TaskEntry {
  final String id;
  final String taskId;
  final double value;
  final DateTime completedAt;
  final String? notes;

  TaskEntry({
    required this.id,
    required this.taskId,
    required this.value,
    required this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'value': value,
      'completedAt': completedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory TaskEntry.fromJson(Map<String, dynamic> json) {
    return TaskEntry(
      id: json['id'],
      taskId: json['taskId'],
      value:
          (json['value'] is String
                  ? double.parse(json['value'])
                  : json['value'])
              .toDouble(),
      completedAt: DateTime.parse(json['completedAt']),
      notes: json['notes'],
    );
  }
}

class TaskTemplate {
  final String name;
  final IconData icon;
  final TaskType type;
  final String? unit;
  final bool featured;

  const TaskTemplate({
    required this.name,
    required this.icon,
    required this.type,
    this.unit,
    this.featured = false,
  });
}

class TaskTypeConfig {
  final TaskType type;
  final String description;
  final List<String> exampleTasks;
  final String? defaultUnit;
  final ProgressionType progressionType;
  final bool customUnitAllowed;
  final List<UnitOption>? unitOptions;

  const TaskTypeConfig({
    required this.type,
    required this.description,
    required this.exampleTasks,
    this.defaultUnit,
    required this.progressionType,
    required this.customUnitAllowed,
    this.unitOptions,
  });

  static const List<TaskTypeConfig> configs = [
    TaskTypeConfig(
      type: TaskType.timeBased,
      description:
          "Tasks where the overload is increasing the duration of the activity over time.",
      exampleTasks: [
        "Meditation",
        "Reading",
        "Language Study",
        "Jogging",
        "Calisthenics",
        "Circuit Training",
        "Break Bad Habits",
      ],
      defaultUnit: "minutes",
      progressionType: ProgressionType.linear,
      customUnitAllowed: false,
    ),
    TaskTypeConfig(
      type: TaskType.unitBased,
      description:
          "Tasks where the overload is based on increasing or reducing a measurable unit.",
      exampleTasks: [
        "Save Money",
        "Cut Sugar",
        "Drink Water",
        "Push-Ups",
        "Weightlifting",
        "Protein Intake",
        "Steps Walked",
        "Quit Smoking",
        "Reduce Screen Time",
        "Cold Showers",
      ],
      progressionType: ProgressionType.linear,
      customUnitAllowed: true,
      unitOptions: [
        UnitOption(label: "kg", description: "Kilograms"),
        UnitOption(label: "g", description: "Grams"),
        UnitOption(label: "L", description: "Liters"),
        UnitOption(label: "ml", description: "Milliliters"),
        UnitOption(label: "cal", description: "Calories"),
        UnitOption(label: "USD", description: "US Dollars"),
      ],
    ),
  ];

  // Task templates with icons
  static const List<TaskTemplate> allTemplates = [
    // Time-based templates
    TaskTemplate(
      name: "Meditation",
      icon: Icons.self_improvement,
      type: TaskType.timeBased,
      featured: true,
    ),
    TaskTemplate(
      name: "Reading",
      icon: Icons.menu_book,
      type: TaskType.timeBased,
    ),
    TaskTemplate(
      name: "Language Study",
      icon: Icons.translate,
      type: TaskType.timeBased,
    ),
    TaskTemplate(
      name: "Jogging",
      icon: Icons.directions_run,
      type: TaskType.timeBased,
    ),
    TaskTemplate(
      name: "Calisthenics",
      icon: Icons.fitness_center,
      type: TaskType.timeBased,
    ),
    TaskTemplate(
      name: "Circuit Training",
      icon: Icons.timer,
      type: TaskType.timeBased,
      featured: true,
    ),
    TaskTemplate(
      name: "Break Bad Habits",
      icon: Icons.block,
      type: TaskType.timeBased,
    ),

    // Unit-based templates
    TaskTemplate(
      name: "Save Money",
      icon: Icons.account_balance_wallet,
      type: TaskType.unitBased,
      unit: "USD",
    ),
    TaskTemplate(
      name: "Cut Sugar",
      icon: Icons.no_food,
      type: TaskType.unitBased,
      unit: "g",
    ),
    TaskTemplate(
      name: "Drink Water",
      icon: Icons.water_drop,
      type: TaskType.unitBased,
      unit: "L",
      featured: true,
    ),
    TaskTemplate(
      name: "Push-Ups",
      icon: Icons.sports_gymnastics,
      type: TaskType.unitBased,
      unit: "reps",
    ),
    TaskTemplate(
      name: "Weightlifting",
      icon: Icons.fitness_center,
      type: TaskType.unitBased,
      unit: "kg",
    ),
    TaskTemplate(
      name: "Protein Intake",
      icon: Icons.restaurant,
      type: TaskType.unitBased,
      unit: "g",
    ),
    TaskTemplate(
      name: "Steps Walked",
      icon: Icons.directions_walk,
      type: TaskType.unitBased,
      unit: "steps",
    ),
    TaskTemplate(
      name: "Quit Smoking",
      icon: Icons.smoke_free,
      type: TaskType.unitBased,
      unit: "cigarettes",
      featured: true,
    ),
    TaskTemplate(
      name: "Reduce Screen Time",
      icon: Icons.phone_android,
      type: TaskType.unitBased,
      unit: "hours",
    ),
    TaskTemplate(
      name: "Cold Showers",
      icon: Icons.shower,
      type: TaskType.unitBased,
      unit: "days",
    ),
  ];

  static List<TaskTemplate> get featuredTemplates =>
      allTemplates.where((template) => template.featured).toList();
}
