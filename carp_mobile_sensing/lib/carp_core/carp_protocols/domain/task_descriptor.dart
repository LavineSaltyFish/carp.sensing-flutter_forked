/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_core_domain;

/// A [TaskDescriptor] holds information about each task to be triggered by
/// a [Trigger] as part of a [StudyProtocol].
/// Each [TaskDescriptor] holds a list of [Measure]s to be done as part of this task.
/// A [TaskDescriptor] is hence merely an aggregation of [Measure]s.
class TaskDescriptor {
  static int _counter = 0;

  /// The name of this task. Unique for this [StudyProtocol].
  String name;

  /// A list of [Measure]s to be done as part of this task.
  List<Measure> measures = [];

  TaskDescriptor({this.name}) : super() {
    name ??= 'Task #${_counter++}';
  }

  /// Add a [Measure] to this task.
  void addMeasure(Measure measure) {
    measures.add(measure);
  }

  /// Add a list of [Measure]s to this task.
  void addMeasures(Iterable<Measure> list) {
    measures.addAll(list);
  }

  /// Remove a [Measure] from this task.
  void removeMeasure(Measure measure) {
    measures.remove(measure);
  }

  String toString() => '$runtimeType: name: $name';
}

/// A [TaskDescriptor] that automatically collects data from the specified measures.
/// Runs without any interaction with the user or UI of the app.
class AutomaticTaskDescriptor extends TaskDescriptor {
  AutomaticTaskDescriptor({String name}) : super(name: name);
}

/// Specifies a task which at some point during a [StudyProtocol] gets sent
/// to a specific device.
class TriggeredTask {
  TaskDescriptor task;
  DeviceDescriptor targetDevice;

  TriggeredTask(this.task, this.targetDevice) : super();
}