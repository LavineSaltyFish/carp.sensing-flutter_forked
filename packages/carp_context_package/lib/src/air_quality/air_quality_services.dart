/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_context_package;

/// An [OnlineService] for the air quality service.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AirQualityService extends OnlineService {
  /// The type of a air quality service.
  static const String DEVICE_TYPE =
      '${DeviceDescriptor.DEVICE_NAMESPACE}.AirQualityService';

  /// The default rolename for a air quality service.
  static const String DEFAULT_ROLENAME = 'air_quality_service';

  /// API key for the WAQI API.
  String apiKey;

  AirQualityService({
    String? roleName,
    List<String>? supportedDataTypes,
    required this.apiKey,
  }) : super(
          roleName: roleName ?? DEFAULT_ROLENAME,
          supportedDataTypes: supportedDataTypes,
        );

  @override
  Function get fromJsonFunction => _$AirQualityServiceFromJson;
  factory AirQualityService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as AirQualityService;
  @override
  Map<String, dynamic> toJson() => _$AirQualityServiceToJson(this);
}

/// A [DeviceManager] for the [AirQualityService].
class AirQualityServiceManager
    extends OnlineServiceManager<DeviceRegistration, AirQualityService> {
  AirQuality? _service;

  /// A handle to the [AirQuality] plugin.
  AirQuality? get service => (_service != null)
      ? _service
      : (deviceDescriptor?.apiKey != null)
          ? _service = AirQuality(deviceDescriptor!.apiKey)
          : null;

  @override
  String get id =>
      deviceDescriptor?.roleName ?? AirQualityService.DEFAULT_ROLENAME;

  @override
  // ignore: avoid_renaming_method_parameters
  void onInitialize(AirQualityService service) {}

  @override
  Future<bool> canConnect() async {
    try {
      var data = await service?.feedFromGeoLocation(
          40.63047005003576, -74.12938368359374);
      return (data != null);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DeviceStatus> onConnect() async =>
      (service != null) ? DeviceStatus.connected : DeviceStatus.disconnected;

  @override
  Future<bool> onDisconnect() async => true;
}
