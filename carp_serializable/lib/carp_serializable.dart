library carp_serializable;

import 'package:meta/meta.dart';
import 'dart:convert';

/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// This is the base class for all JSON serializable objects.
///
/// Using this class allow for implementing both serialization and
/// deserialization to/from JSON.
/// This is done using the [json_serializable](https://pub.dev/packages/json_serializable)
/// package.
///
/// It also allows for serialization of polymorphic classes.
///
/// To support polymorphic serialization, each subclass should:
///
///  * annotate the class with `@JsonSerializable`
///  * add the three json methods
///      * `Function get fromJsonFunction => ...`
///      * `factory ...fromJson(...)`
///      * `Map<String, dynamic> toJson() => ...`
///  * register the classes in the `FromJsonFactory()` registry.
///  * build json function using the `flutter pub run build_runner build --delete-conflicting-outputs` command
///
/// Below is a simple example of two classes `A` and `B` where B extends A.
///
/// ```dart
/// @JsonSerializable()
/// class A extends Serializable {
///   int index;
///
///   A() : super();
///
///   Function get fromJsonFunction => _$AFromJson;
///   factory A.fromJson(Map<String, dynamic> json) =>
///       FromJsonFactory().fromJson(json) as A;
///   Map<String, dynamic> toJson() => _$AToJson(this);
/// }
///
/// @JsonSerializable()
/// class B extends A {
///   String str;
///
///   B() : super();
///
///   Function get fromJsonFunction => _$BFromJson;
///   factory B.fromJson(Map<String, dynamic> json) =>
///       FromJsonFactory().fromJson(json) as B;
///   Map<String, dynamic> toJson() => _$BToJson(this);
/// }
/// ````
///
/// Note that the naming of the `fromJson()` and `toJson()` functions follows
/// [json_serializable](https://pub.dev/packages/json_serializable)
/// package. For example the `fromJson` function for class `A` is called `_$AFromJson`.
///
/// The [fromJsonFunction] must be registered on app startup (before
/// use of de-serialization) in the [FromJsonFactory] singleton, like this:
///
/// ```dart
///  FromJsonFactory().register(A());
/// ````
///
/// For this purpose it is helpful to have an empty constructor, but any constructur
/// will work, since only the `fromJsonFunction` function is used.
///
/// Polymorphic serialization is handled by setting the `$type` property in the
/// [Serializable] class. Per default, an object's `runtimeType` is used as the
/// `$type` for an object. Hence, the json of object of type `A` and `B` would
/// look like this:
///
/// ```json
///  {
///   "$type": "A",
///   "index": 1
///  }
///  {
///   "$type": "B",
///   "index": 2
///   "str": "abc"
///  }
/// ```
///
/// However, if you want to specify your own class type (e.g., if you get
/// json serialized from another language which uses a package structure like
/// Java, C# or Kotlin), you can specify the json type in the [jsonType] property
/// of the class.
///
/// For example, if the class `B` above should use a different `$type` annotation,
/// using the following:
///
/// ```dart
/// @JsonSerializable()
/// class B extends A {
///
///   <<as above>>
///
///   String get jsonType => 'dk.cachet.$runtimeType';
/// }
/// ````
///
/// In which case the json would look like:
///
/// ```json
///  {
///   "$type": "dk.cachet.B",
///   "index": 2
///   "str": "abc"
///  }
/// ```
///
abstract class Serializable {
  /// The identifier of the class type in JSON serialization.
  static const String CLASS_IDENTIFIER = '\$type';

  // to be used in carp_core v. 1.0.0
  // static const String CLASS_IDENTIFIER = '\__type';

  /// The runtime class name (type) of this object.
  /// Used for deserialization from JSON objects.
  String? $type;

  // to be used in carp_core v. 1.0.0
  // @JsonKey(name: '__type')
  // String? $type;

  /// Create an object that can be serialized to JSON.
  @mustCallSuper
  Serializable() {
    $type = jsonType;
  }

  /// The function which can convert a JSON string to an object of this type.
  Function get fromJsonFunction;

  /// Return a JSON encoding of this object.
  Map<String, dynamic> toJson();

  /// Return the [$type] to be used for JSON serialization of this class.
  /// Default is [runtimeType]. Only specify this if you need another type.
  String get jsonType => runtimeType.toString();
}

/// A factory that holds [fromJson] functions to be used in JSON
/// deserialization.
class FromJsonFactory {
  static final FromJsonFactory _instance = FromJsonFactory._();
  factory FromJsonFactory() => _instance;

  final Map<String, Function> _registry = {};

  FromJsonFactory._();

  /// Register a [Serializable] class which can be deserialized from JSON.
  ///
  /// If [type] is specified, then this is used as the type indentifier as
  /// specified in [CLASS_IDENTIFIER].
  /// Othervise the [Serializable] class [jsonType] is used.
  ///
  /// A type needs to be registered **before** a class can be deserialized from
  /// JSON to a Flutter class.
  void register(Serializable serializable, {String? type}) =>
      _registry[type ?? serializable.jsonType] = serializable.fromJsonFunction;

  /// Register all [serializables].
  ///
  /// A convinient way to call [register] for multiple types.
  void registerAll(List<Serializable> serializables) {
    for (var serializable in serializables) {
      register(serializable);
    }
  }

  /// Deserialize [json] based on its type.
  Serializable? fromJson(Map<String, dynamic> json) {
    final type = json[Serializable.CLASS_IDENTIFIER];
    if (!_registry.containsKey(type)) {
      throw SerializationException(
          "A 'fromJson' function was not found in the FromJsonFactory for the type '$type'. "
          "Register a Serializable class using the 'FromJsonFactory().register()' method.");
    }
    var fromJson = Function.apply(_registry[type!]!, [json]);
    if (fromJson is Serializable) {
      return fromJson;
    } else {
      throw SerializationException(
          "The 'fromJson' function registered for the type '$type' does not return a Serializable class. "
          "Make sure that the fromJson function returns a class that inherits from the Serializable class.");
    }
  }
}

/// Throws when serialization to/from json fails.
class SerializationException implements Exception {
  final String _message;
  String get message => _message;
  SerializationException([this._message = '']);
  @override
  String toString() => '$runtimeType - $message';
}

/// A convient function to convert a Dart object into a formatted JSON string.
String toJsonString(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);
