/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_core_protocols;

/// A [TaskDescriptor] holds information about each task to be triggered by
/// a [Trigger] as part of a [StudyProtocol].
/// Each [TaskDescriptor] holds a list of [Measure]s to be done as part of this task.
/// A [TaskDescriptor] is hence merely an aggregation of [Measure]s.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class TaskDescriptor extends Serializable {
  static int _counter = 0;

  /// The name of this task. Unique for this [StudyProtocol].
  late String name;

  /// A list of [Measure]s to be done as part of this task.
  List<Measure> measures = [];

  /// Add a [Measure] to this task.
  void addMeasure(Measure measure) => measures.add(measure);

  /// Add a list of [Measure]s to this task.
  void addMeasures(Iterable<Measure> list) => measures.addAll(list);

  /// Remove a [Measure] from this task.
  void removeMeasure(Measure measure) => measures.remove(measure);

  @mustCallSuper
  TaskDescriptor({
    String? name,
    List<Measure>? measures,
  }) : super() {
    this.name = name ?? 'Task #${_counter++}';
    this.measures = measures ?? [];
  }

  Function get fromJsonFunction => _$TaskDescriptorFromJson;
  factory TaskDescriptor.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as TaskDescriptor;
  Map<String, dynamic> toJson() => _$TaskDescriptorToJson(this);
  String get jsonType => 'dk.cachet.carp.protocols.domain.tasks.$runtimeType';

  String toString() =>
      '$runtimeType - name: $name, measures size: ${measures.length}';
}

/// A task which specifies that all containing measures and/or
/// outputs should immediately start running in the background once triggered.
/// The task runs for the specified [duration], or until stopped, or until
/// all measures and/or outputs have completed.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class BackgroundTask extends TaskDescriptor {
  /// The optional duration over the course of which the [measures] need to
  /// be sampled. `null` implies infinite by default.
  Duration? duration;

  BackgroundTask({
    String? name,
    List<Measure>? measures,
    this.duration,
  }) : super(name: name, measures: measures);

  Function get fromJsonFunction => _$BackgroundTaskFromJson;
  factory BackgroundTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as BackgroundTask;
  Map<String, dynamic> toJson() => _$BackgroundTaskToJson(this);
}

/// A task which contains a definition on how to run tasks, measures,
/// and triggers which differs from the CARP domain model.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class CustomProtocolTask extends TaskDescriptor {
  /// A definition on how to run a study on a master device, serialized as a string.
  String studyProtocol;

  // The measures list is empty, since measures are defined in [studyProtocol]
  // in a different format.
  CustomProtocolTask({
    String? name,
    required this.studyProtocol,
  }) : super(name: name, measures: []);

  Function get fromJsonFunction => _$CustomProtocolTaskFromJson;
  factory CustomProtocolTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as CustomProtocolTask;
  Map<String, dynamic> toJson() => _$CustomProtocolTaskToJson(this);

  String toString() => '${super.toString()}, studyProtocol: $studyProtocol';
}
