/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of communication;

/// Holds a list of text (SMS) messages from the device.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class TextMessageLogDatum extends Datum {
  @override
  DataFormat get format =>
      DataFormat.fromString(CommunicationSamplingPackage.TEXT_MESSAGE_LOG);

  List<TextMessage> textMessageLog = [];

  TextMessageLogDatum() : super();

  factory TextMessageLogDatum.fromJson(Map<String, dynamic> json) =>
      _$TextMessageLogDatumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TextMessageLogDatumToJson(this);

  @override
  String toString() => '${super.toString()}, size: ${textMessageLog.length}';
}

/// Holds a single text (SMS) message as a [Datum] object.
///
/// Wraps a [TextMessage].
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class TextMessageDatum extends Datum {
  @override
  DataFormat get format =>
      DataFormat.fromString(CommunicationSamplingPackage.TEXT_MESSAGE);

  TextMessage? textMessage;

  TextMessageDatum() : super();

  factory TextMessageDatum.fromTextMessage(TextMessage msg) =>
      TextMessageDatum()..textMessage = msg;

  factory TextMessageDatum.fromJson(Map<String, dynamic> json) =>
      _$TextMessageDatumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TextMessageDatumToJson(this);

  @override
  String toString() => '${super.toString()}, textMessage: $textMessage';
}

/// Holds a text messages (SMS).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class TextMessage {
  int? id;

  /// The receiver address of this message
  String? address;

  /// The text body of this message.
  String? body;

  /// The size in bytes of the body of the message.
  int? size;

  /// Has the message been read?
  bool? read;

  /// The date this message was created.
  DateTime? date;

  /// The date this message was sent.
  DateTime? dateSent;

  /// The type of message:
  SmsType? type;

  /// The state of the message:
  SmsStatus? status;

  TextMessage(
      {this.id,
      this.address,
      this.body,
      this.size,
      this.read,
      this.date,
      this.dateSent,
      this.type,
      this.status})
      : super();

  factory TextMessage.fromSmsMessage(SmsMessage sms) => TextMessage(
        id: sms.id,
        address: sms.address,
        body: sms.body,
        size: (sms.body != null) ? sms.body!.length : null,
        read: sms.read,
        date: DateTime.fromMicrosecondsSinceEpoch(sms.date!, isUtc: true),
        dateSent:
            DateTime.fromMicrosecondsSinceEpoch(sms.dateSent!, isUtc: true),
        type: sms.type,
        status: sms.status,
      );

  factory TextMessage.fromJson(Map<String, dynamic> json) =>
      _$TextMessageFromJson(json);
  Map<String, dynamic> toJson() => _$TextMessageToJson(this);

  @override
  String toString() =>
      "Text Message - id: $id, address: $address, read: $read, date: $date, date_send: $dateSent, type: $type, status: $status\n$body";
}

/// Holds a phone log, i.e. a list of phone calls made on the device.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class PhoneLogDatum extends Datum {
  @override
  DataFormat get format =>
      DataFormat.fromString(CommunicationSamplingPackage.PHONE_LOG);

  List<PhoneCall> phoneLog = [];

  PhoneLogDatum() : super();

  factory PhoneLogDatum.fromJson(Map<String, dynamic> json) =>
      _$PhoneLogDatumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PhoneLogDatumToJson(this);

  @override
  String toString() => "${super.toString()}, size: ${phoneLog.length}";
}

/// Phone call data.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class PhoneCall {
  /// Date & Time of the call.
  DateTime? timestamp;

  /// Type of call:
  ///  - answered
  ///  - incoming
  ///  - blocked
  ///  - missed
  ///  - outgoing
  ///  - rejected
  ///  - voice_mail
  String? callType;

  /// Duration of call in ms.
  int? duration;

  /// The formatted version of the phone number (if available).
  String? formattedNumber;

  /// The phone number
  String? number;

  /// The name of the caller (if available).
  String? name;

  PhoneCall(
      [this.timestamp,
      this.callType,
      this.duration,
      this.formattedNumber,
      this.number,
      this.name]);

  factory PhoneCall.fromCallLogEntry(CallLogEntry call) {
    DateTime timestamp = DateTime.fromMicrosecondsSinceEpoch(call.timestamp!);
    String type = "unknown";

    switch (call.callType) {
      case CallType.answeredExternally:
        type = 'answered_externally';
        break;
      case CallType.blocked:
        type = 'blocked';
        break;
      case CallType.incoming:
        type = 'incoming';
        break;
      case CallType.missed:
        type = 'missed';
        break;
      case CallType.outgoing:
        type = 'outgoing';
        break;
      case CallType.rejected:
        type = 'rejected';
        break;
      case CallType.voiceMail:
        type = 'voice_mail';
        break;
      default:
        type = "unknown";
        break;
    }

    return PhoneCall(timestamp, type, call.duration, call.formattedNumber,
        call.number, call.name);
  }

  factory PhoneCall.fromJson(Map<String, dynamic> json) =>
      _$PhoneCallFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneCallToJson(this);

  @override
  String toString() =>
      "$runtimeType - timestamp: $timestamp, call_type: $callType, duration: $duration, number: $number, formatted_number: $formattedNumber, name: $name";
}

/// Holds a list of calendar events from the device.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CalendarDatum extends Datum {
  @override
  DataFormat get format =>
      DataFormat.fromString(CommunicationSamplingPackage.CALENDAR);

  List<CalendarEvent> calendarEvents = [];

  CalendarDatum() : super();

  factory CalendarDatum.fromJson(Map<String, dynamic> json) =>
      _$CalendarDatumFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CalendarDatumToJson(this);

  @override
  String toString() => '${super.toString()}, size: ${calendarEvents.length}';
}

/// A calendar event.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CalendarEvent {
  /// The unique identifier for this event
  String? eventId;

  /// The identifier of the calendar that this event is associated with
  String? calendarId;

  /// The title of this event
  String? title;

  /// The description for this event
  String? description;

  /// Indicates when the event starts
  DateTime? start;

  /// Indicates when the event ends
  DateTime? end;

  /// Indicates if this is an all-day event
  bool? allDay;

  /// The location of this event
  String? location;

  /// A list of attendees' name for this event
  List<String?>? attendees;

  CalendarEvent(
      [this.eventId,
      this.calendarId,
      this.title,
      this.description,
      this.start,
      this.end,
      this.allDay,
      this.location,
      this.attendees]);

  factory CalendarEvent.fromEvent(Event event) {
    return CalendarEvent(
        event.eventId,
        event.calendarId,
        event.title,
        event.description,
        event.start!.toUtc(),
        event.end!.toUtc(),
        event.allDay,
        event.location,
        event.attendees!.map((attendees) => attendees!.name).toList());
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);

  @override
  String toString() =>
      "Calendar Event - eventId: $eventId, calendarId: $calendarId, title: $title, description: $description, start: $start, end: $end, all day: $allDay, location: $location, no. attendees: ${attendees!.length}";
}
