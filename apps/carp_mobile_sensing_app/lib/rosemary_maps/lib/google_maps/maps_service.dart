// part of rosemary_maps;

import 'package:dio/dio.dart';
import 'maps_data_model.dart';

abstract class MapService<T extends MapsDataModel> {
  final String baseUrl;
  late Map<String, dynamic> queryParameters;

  final Dio _dio = Dio();
  MapService(this.baseUrl);

  void setQueryParams();
  T? processResponseData(dynamic data);

  Future<T?> run() async {
    setQueryParams();

    // data is nullable
    final data = await getResponse();

    return data == null? processResponseData(data) : null;
  }

  Future<dynamic> getResponse() async {
    final response = await _dio.get(
      baseUrl,
      queryParameters: queryParameters,
    );

    // Check if response is successful
    // return (response.statusCode == 200) ? response.data : null;
    return response.data;
  }
}

// --- LEGACY --- //
// class MapsServiceRequest {
//   final String _baseUrl;
//   Map<String, dynamic> _queryParameters = new Map<String, dynamic>();
//
//   final Dio _dio = Dio();
//
//   MapsServiceRequest(String baseUrl) :
//         _baseUrl = baseUrl;
//
//   Future<dynamic?> getResponse() async {
//     final response = await _dio.get(
//       _baseUrl,
//       queryParameters: _queryParameters,
//     );
//
//     // Check if response is successful
//     return (response.statusCode == 200) ? response.data : null;
//   }
// }