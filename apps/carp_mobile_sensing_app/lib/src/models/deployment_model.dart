part of mobile_sensing_app;

class StudyDeploymentModel {
  SmartphoneDeployment deployment;

  String get title => deployment.protocolDescription?.title ?? '';
  String get description =>
      deployment.protocolDescription?.description ??
      'No description available.';
  Image get image => Image.asset('assets/study.png');
  String get studyDeploymentId => deployment.studyDeploymentId;
  String get userID => deployment.userId ?? '';
  String get dataEndpoint => deployment.dataEndPoint.toString();

  /// Events on the state of the study executor
  Stream<ExecutorState> get studyExecutorStateEvents =>
      Sensing().controller!.executor!.stateEvents;

  /// Current state of the study executor (e.g., resumed, paused, ...)
  ExecutorState get studyState => Sensing().controller!.executor!.state;

  /// Get all sesing events (i.e. all [Datum] objects being collected).
  Stream<DataPoint> get data => Sensing().controller!.data;

  /// The total sampling size so far since this study was started.
  int get samplingSize => Sensing().controller!.samplingSize;

  StudyDeploymentModel(this.deployment) : super();
}
