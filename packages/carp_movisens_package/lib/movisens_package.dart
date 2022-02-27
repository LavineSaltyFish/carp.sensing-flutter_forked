/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of movisens;

/// The Movisens sampling package
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(MovisensSamplingPackage());
/// ```
class MovisensSamplingPackage implements SamplingPackage {
  static const String MOVISENS = "${NameSpace.CARP}.movisens";

  static const String MOVISENS_NAMESPACE = "${NameSpace.CARP}.movisens";
  static const String MET_LEVEL = "$MOVISENS_NAMESPACE.met_level";
  static const String MET = "$MOVISENS_NAMESPACE.met";
  static const String HR = "$MOVISENS_NAMESPACE.hr";
  static const String HRV = "$MOVISENS_NAMESPACE.hrv";
  static const String IS_HRV_VALID = "$MOVISENS_NAMESPACE.is_hrv_valid";
  static const String BODY_POSITION = "$MOVISENS_NAMESPACE.body_position";
  static const String STEP_COUNT = "$MOVISENS_NAMESPACE.step_count";
  static const String MOVEMENT_ACCELERATION =
      "$MOVISENS_NAMESPACE.movement_acceleration";
  static const String TAP_MARKER = "$MOVISENS_NAMESPACE.tap_marker";
  static const String BATTERY_LEVEL = "$MOVISENS_NAMESPACE.battery_level";
  static const String CONNECTION_STATUS =
      "$MOVISENS_NAMESPACE.connection_status";

  @override
  void onRegister() {
    FromJsonFactory()
        .register(MovisensDeviceDescriptor(address: '', sensorName: ''));

    // registering the transformers from CARP to OMH and FHIR for heart rate and step count.
    // we assume that there are OMH and FHIR schemas created and registrered already...
    TransformerSchemaRegistry().lookup(NameSpace.OMH)!.add(
          HR,
          OMHHeartRateDataPoint.transformer,
        );
    TransformerSchemaRegistry().lookup(NameSpace.OMH)!.add(
          STEP_COUNT,
          OMHStepCountDataPoint.transformer,
        );
    TransformerSchemaRegistry().lookup(NameSpace.FHIR)!.add(
          HR,
          FHIRHeartRateObservation.transformer,
        );
  }

  @override
  String get deviceType => MovisensDeviceDescriptor.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => MovisensDeviceManager();

  @override
  List<Permission> get permissions => []; // no special permissions needed

  /// Create a [MovisensProbe].
  @override
  Probe? create(String type) => (type == MOVISENS) ? MovisensProbe() : null;

  @override
  List<String> get dataTypes => [MOVISENS];

  SamplingSchema get common => SamplingSchema(
        type: SamplingSchemaType.common,
        powerAware: false,
      )..measures.addEntries([
          MapEntry(
              MOVISENS_NAMESPACE,
              CAMSMeasure(
                type: MOVISENS_NAMESPACE,
                name: 'Movisens ECG device',
                description:
                    "Collects heart rythm data from the Movisens EcgMove4 sensor",
              )),
        ]);

  SamplingSchema get light => common..type = SamplingSchemaType.light;
  SamplingSchema get minimum => common..type = SamplingSchemaType.minimum;
  SamplingSchema get normal => common..type = SamplingSchemaType.normal;
  SamplingSchema get debug => common..type = SamplingSchemaType.debug;
}
