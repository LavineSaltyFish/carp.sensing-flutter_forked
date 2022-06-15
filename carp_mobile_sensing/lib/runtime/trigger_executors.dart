/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of runtime;

/// Returns the relevant [TriggerExecutor] based on the type of [trigger].
TriggerExecutor getTriggerExecutor(Trigger trigger) {
  switch (trigger.runtimeType) {
    case ImmediateTrigger:
      return ImmediateTriggerExecutor();
    case OneTimeTrigger:
      return OneTimeTriggerExecutor();
    case DelayedTrigger:
      return DelayedTriggerExecutor();
    case ElapsedTimeTrigger:
      return ElapsedTimeTriggerExecutor();
    case ElapsedTimeTrigger:
      return ElapsedTimeTriggerExecutor();
    case IntervalTrigger:
      return IntervalTriggerExecutor();
    case PeriodicTrigger:
      return PeriodicTriggerExecutor();
    case DateTimeTrigger:
      return DateTimeTriggerExecutor();
    case RecurrentScheduledTrigger:
      return RecurrentScheduledTriggerExecutor();
    case CronScheduledTrigger:
      return CronScheduledTriggerExecutor();
    case SamplingEventTrigger:
      return SamplingEventTriggerExecutor();
    case ConditionalSamplingEventTrigger:
      return ConditionalSamplingEventTriggerExecutor();
    case ConditionalPeriodicTrigger:
      return ConditionalPeriodicTriggerExecutor();
    case RandomRecurrentTrigger:
      return RandomRecurrentTriggerExecutor();
    case PassiveTrigger:
      return PassiveTriggerExecutor();
    default:
      warning(
          "Unknown trigger used - cannot find a TriggerExecutor for the trigger of type '${trigger.runtimeType}'. "
          "Using an 'ImmediateTriggerExecutor' instead.");
      return ImmediateTriggerExecutor();
  }
}

// ---------------------------------------------------------------------------------------------------------
// TRIGGER EXECUTORS
// ---------------------------------------------------------------------------------------------------------

/// Responsible for handling the execution of a [Trigger].
///
/// This is an abstract class. For each specific type of [Trigger],
/// a corresponding implementation of this class exists.
abstract class TriggerExecutor<TConfig extends Trigger>
    extends AggregateExecutor<TConfig> {
  // /// An ordered list of timestamp generated by this trigger for a
  // /// given period. This is mainly used for persistently scheduling
  // /// a list of [AppTask]s from this trigger.
  // List<DateTime> getSchedule(DateTime from, DateTime to);

  @override
  void onInitialize() {
    // No initialize needed pr. default.
  }

  /// Returns a list of the running probes in this [TriggerExecutor].
  /// This is a combination of the running probes in all task executors.
  List<Probe> get probes {
    List<Probe> _probes = [];
    executors.forEach((executor) {
      if (executor is TaskExecutor) {
        _probes.addAll(executor.probes);
      }
    });
    return _probes;
  }
}

abstract class ScheduleableTriggerExecutor<TConfig extends Trigger>
    extends TriggerExecutor<TConfig> {
  /// An ordered list of timestamp generated by this trigger for a
  /// given period. This is mainly used for persistently scheduling
  /// a list of [AppTask]s from triggers that implement the [Scheduleable]
  /// interface.
  List<DateTime> getSchedule(DateTime from, DateTime to);
}

/// Executes a [ImmediateTrigger], i.e. starts sampling immediately.
class ImmediateTriggerExecutor extends TriggerExecutor<Trigger> {}

/// Executes a [OneTimeTrigger], i.e. a trigger that only runs once during a
/// study deployment.
class OneTimeTriggerExecutor extends TriggerExecutor<OneTimeTrigger> {
  @override
  Future<void> onResume() async {
    if (!configuration!.hasBeenTriggered) {
      configuration!.triggerTimestamp = DateTime.now();
      await super.onResume();
    } else {
      info(
          "$runtimeType - one time trigger already occured at: ${configuration?.triggerTimestamp}. "
          'Will not trigger now.');
    }
  }
}

/// Executes a [PassiveTrigger].
class PassiveTriggerExecutor extends TriggerExecutor<PassiveTrigger> {
  PassiveTriggerExecutor() : super() {
    configuration!.executor = ImmediateTriggerExecutor();
    group.add(configuration!.executor.data);
  }

  // Forward to the embedded trigger executor
  @override
  void onInitialize() =>
      configuration!.executor.initialize(configuration as Trigger, deployment!);

  // No-op methods since a PassiveTrigger can only be resumed/paused
  // using the resume/pause methods on the PassiveTrigger.
  @override
  Future<void> onResume() async {}
  @override
  Future<void> onPause() async {}

  // Forward to the embedded trigger executor
  @override
  Future<void> onRestart() async => configuration!.executor.restart();
  @override
  Future<void> onStop() async => configuration!.executor.stop();
}

/// Executes a [DelayedTrigger], i.e. resumes sampling after the specified delay.
/// Once started, it can be paused / resumed as any other [Executor].
class DelayedTriggerExecutor extends TriggerExecutor<DelayedTrigger> {
  @override
  Future<void> onResume() async =>
      Timer(configuration!.delay, () => super.onResume());
}

/// Executes a [ElapsedTimeTrigger], i.e. resumes sampling after the
/// specified delay after deployment start on this phone.
///
/// Once started, this trigger executor can be paused / resumed as any
/// other [Executor].
class ElapsedTimeTriggerExecutor
    extends ScheduleableTriggerExecutor<ElapsedTimeTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    final dd = DateTime.now().add(configuration!.elapsedTime);
    return (dd.isAfter(from) && dd.isBefore(to)) ? [dd] : [];
  }

  @override
  Future<void> onResume() async {
    if (deployment?.deployed == null) {
      warning(
          '$runtimeType - this deployment does not have a start time. Cannot execute this trigger.');
    } else {
      int delay = configuration!.elapsedTime.inMilliseconds -
          (DateTime.now().millisecondsSinceEpoch -
              deployment!.deployed!.millisecondsSinceEpoch);

      if (delay > 0) {
        Timer(Duration(milliseconds: delay), () => super.onResume());
      } else {
        warning(
            '$runtimeType - delay is negative, i.e. the trigger time is in the past and should have happend already.');
      }
    }
  }
}

abstract class TimerTriggerExecutor<TConfig extends Trigger>
    extends ScheduleableTriggerExecutor<TConfig> {
  Timer? timer;

  @override
  Future<void> onPause() async {
    timer?.cancel();
    await super.onPause();
  }
}

/// Executes a [IntervalTrigger], i.e. resumes sampling on a regular basis.
class IntervalTriggerExecutor extends TimerTriggerExecutor<IntervalTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    final List<DateTime> schedule = [];
    DateTime timestamp = from;

    while (timestamp.isBefore(to)) {
      schedule.add(timestamp);
      timestamp = timestamp.add(configuration!.period);
    }

    return schedule;
  }

  @override
  Future<void> onResume() async {
    timer = Timer.periodic(configuration!.period, (t) {
      super.onResume();
      Timer(const Duration(seconds: 3), () => super.onPause());
    });
  }
}

/// Executes a [PeriodicTrigger], i.e. resumes sampling on a regular basis for
/// a given period of time.
///
/// It is required that both the [period] and the [duration] of the
/// [PeriodicTrigger] is specified to make sure that this executor is properly
/// resumed and paused again.
class PeriodicTriggerExecutor extends TimerTriggerExecutor<PeriodicTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    final List<DateTime> schedule = [];
    DateTime timestamp = from;

    while (timestamp.isBefore(to)) {
      schedule.add(timestamp);
      timestamp = timestamp.add(configuration!.period);
    }

    return schedule;
  }

  @override
  Future<void> onResume() async {
    // create a recurrent timer that resume periodically
    timer = Timer.periodic(configuration!.period, (t) {
      super.onResume();
      // create a timer that pause the sampling after the specified duration.
      Timer(configuration!.duration, () {
        super.onPause();
      });
    });
  }
}

/// Executes a [DateTimeTrigger] on the specified date and time.
class DateTimeTriggerExecutor extends TimerTriggerExecutor<DateTimeTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) =>
      (configuration!.schedule.isAfter(from) &&
              configuration!.schedule.isBefore(to))
          ? [configuration!.schedule]
          : [];

  @override
  Future<void> onResume() async {
    if (configuration!.schedule.isAfter(DateTime.now())) {
      warning('The schedule of the DateTimeTrigger cannot be in the past.');
    } else {
      var delay = configuration!.schedule.difference(DateTime.now());
      var duration = configuration?.duration;
      timer = Timer(delay, () {
        // after the waiting time (delay) is over, resume this trigger
        super.onResume();
        if (duration != null) {
          // create a timer that stop the sampling after the specified duration.
          // if the duration is null, the sampling never stops, i.e. runs forever.
          Timer(duration, () {
            stop();
          });
        }
      });
    }
  }
}

/// Executes a [RecurrentScheduledTrigger].
class RecurrentScheduledTriggerExecutor
    extends TimerTriggerExecutor<RecurrentScheduledTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    List<DateTime> schedule = [];
    DateTime timestamp = configuration!.firstOccurrence;

    while (timestamp.isBefore(to)) {
      if (timestamp.isAfter(from)) schedule.add(timestamp);
      timestamp = timestamp.add(configuration!.period);
    }

    return schedule;
  }

  @override
  Future<void> onResume() async {
    Duration _delay = configuration!.firstOccurrence.difference(DateTime.now());
    if (configuration!.end == null ||
        configuration!.end!.isAfter(DateTime.now())) {
      Timer(_delay, () async {
        await super.onResume();
      });
    }
  }
}

/// Executes a [CronScheduledTrigger] based on the specified cron job.
class CronScheduledTriggerExecutor
    extends ScheduleableTriggerExecutor<CronScheduledTrigger> {
  late cron.Cron _cron;
  cron.ScheduledTask? _scheduledTask;

  CronScheduledTriggerExecutor() : super() {
    _cron = cron.Cron();
  }

  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    var cronIterator = Cron().parse(
        configuration!.cronExpression,
        Settings().timezone,
        tz.TZDateTime.from(from, tz.getLocation(Settings().timezone)));
    final List<DateTime> schedule = [];
    while (cronIterator.next().isBefore(to)) {
      schedule.add(cronIterator.current());
    }
    return schedule;
  }

  @override
  Future<void> onResume() async {
    debug('creating cron job : $configuration');
    var _schedule = cron.Schedule.parse(configuration!.cronExpression);
    _scheduledTask = _cron.schedule(_schedule, () async {
      debug('resuming cron job : ${DateTime.now().toString()}');
      await super.onResume();
      Timer(configuration!.duration, () => super.onPause());
    });
  }

  @override
  Future<void> onPause() async {
    await _scheduledTask?.cancel();
    await super.onPause();
  }
}

/// Executes a [SamplingEventTrigger] based on the specified
/// [SamplingEventTrigger.measureType] and [SamplingEventTrigger.resumeCondition].
class SamplingEventTriggerExecutor
    extends TriggerExecutor<SamplingEventTrigger> {
  late StreamSubscription<DataPoint>? _subscription;

  @override
  Future<void> onResume() async {
    _subscription = SmartPhoneClientManager()
        .lookupStudyRuntime(deployment!.studyDeploymentId,
            deployment!.deviceDescriptor.roleName)
        ?.dataByType(configuration!.measureType)
        .listen((dataPoint) {
      if ((configuration!.resumeCondition != null) &&
          (dataPoint.carpBody as Datum)
              .equivalentTo(configuration!.resumeCondition)) super.onResume();
      if (configuration!.pauseCondition != null &&
          (dataPoint.carpBody as Datum)
              .equivalentTo(configuration!.pauseCondition)) super.onPause();
    });
  }

  @override
  Future<void> onPause() async {
    await _subscription?.cancel();
    await super.onPause();
  }
}

/// Executes a [ConditionalSamplingEventTrigger] based on the specified
/// [ConditionalSamplingEventTrigger.measureType] and their
/// [ConditionalSamplingEventTrigger.resumeCondition] and
/// [ConditionalSamplingEventTrigger.pauseCondition].
class ConditionalSamplingEventTriggerExecutor
    extends TriggerExecutor<ConditionalSamplingEventTrigger> {
  StreamSubscription<DataPoint>? _subscription;

  @override
  Future<void> onResume() async {
    // listen for event of the specified type and resume/pause as needed
    _subscription = SmartPhoneClientManager()
        .lookupStudyRuntime(deployment!.studyDeploymentId,
            deployment!.deviceDescriptor.roleName)
        ?.dataByType(configuration!.measureType)
        .listen((dataPoint) {
      if (configuration!.resumeCondition != null &&
          configuration!.resumeCondition!(dataPoint)) super.onResume();
      if (configuration!.pauseCondition != null &&
          configuration!.pauseCondition!(dataPoint)) super.onPause();
    });
  }

  @override
  Future<void> onPause() async {
    await _subscription?.cancel();
    await super.onPause();
  }
}

/// Executes a [ConditionalPeriodicTrigger].
class ConditionalPeriodicTriggerExecutor
    extends TriggerExecutor<ConditionalPeriodicTrigger> {
  Timer? timer;

  @override
  Future<void> onResume() async {
    // create a recurrent timer that checks the conditions periodically
    timer = Timer.periodic(configuration!.period, (_) {
      debug(
          '$runtimeType - checking; resumeCondition: ${configuration!.resumeCondition}, pauseCondition: ${configuration!.pauseCondition}');
      if (configuration!.resumeCondition != null &&
          configuration!.resumeCondition!()) super.onResume();
      if (configuration!.pauseCondition != null &&
          configuration!.pauseCondition!()) super.onPause();
    });
  }

  @override
  Future<void> onPause() async {
    timer?.cancel();
    await super.onPause();
  }
}

/// Executes a [RandomRecurrentTrigger] triggering N times per day within a
/// defined period of time.
class RandomRecurrentTriggerExecutor
    extends ScheduleableTriggerExecutor<RandomRecurrentTrigger> {
  final cron.Cron _cron = cron.Cron();
  late cron.ScheduledTask _scheduledTask;
  List<Timer> _timers = [];

  TimeOfDay get startTime => configuration!.startTime;
  TimeOfDay get endTime => configuration!.endTime;
  int get minNumberOfTriggers => configuration!.minNumberOfTriggers;
  int get maxNumberOfTriggers => configuration!.maxNumberOfTriggers;
  Duration get duration => configuration!.duration;

  /// Get a random number of samples for the day
  int get numberOfSampling =>
      Random().nextInt(maxNumberOfTriggers) + minNumberOfTriggers;

  /// Get N random times between startTime and endTime
  List<TimeOfDay> get samplingTimes {
    List<TimeOfDay> _samplingTimes = [];
    for (int i = 0; i <= numberOfSampling; i++) {
      _samplingTimes.add(randomTime);
    }
    debug('Random sampling times: $_samplingTimes');
    return _samplingTimes;
  }

  /// Get a random time between startTime and endTime
  TimeOfDay get randomTime {
    TimeOfDay randomTime = TimeOfDay();
    do {
      int randomHour = startTime.hour +
          ((endTime.hour - startTime.hour == 0)
              ? 0
              : Random().nextInt(endTime.hour - startTime.hour));
      int randomMinutes = Random().nextInt(60);
      randomTime = TimeOfDay(hour: randomHour, minute: randomMinutes);
    } while (!(randomTime.isAfter(startTime) && randomTime.isBefore(endTime)));

    return randomTime;
  }

  String get todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool get hasBeenScheduledForToday {
    // fast out if no timestamp is set previously
    if (configuration?.lastTriggerTimestamp == null) return false;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final sinceLastTime =
        now.millisecond - configuration!.lastTriggerTimestamp!.millisecond;
    final sinceMidnight = now.millisecond - midnight.millisecond;

    return (sinceLastTime < sinceMidnight);
  }

  @override
  List<DateTime> getSchedule(DateTime from, DateTime to) {
    assert(to.isAfter(from));
    final List<DateTime> schedule = [];

    final startDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    var day = startDay;

    while (day.isBefore(toDay)) {
      samplingTimes.forEach((time) {
        final date = DateTime(
            day.year, day.month, day.day, time.hour, time.minute, time.second);
        if (date.isAfter(from) && date.isBefore(to)) schedule.add(date);
      });

      day = day.add(const Duration(days: 1));
    }
    return schedule;
  }

  @override
  Future<void> onResume() async {
    // sampling might be resumed after [startTime] or the app wasn't running at [startTime]
    // therefore, first check if the random timers have been scheduled for today
    if (TimeOfDay.now().isAfter(startTime)) {
      if (!hasBeenScheduledForToday) {
        debug(
            '$runtimeType - timers has not been scheduled for today ($todayString) - scheduling now');
        _scheduleTimers();
      }
    }

    // set up a cron job that generates the random triggers once pr day at [startTime]
    final cronJob = '${startTime.minute} ${startTime.hour} * * *';
    debug('$runtimeType - creating cron job : $cronJob');

    _scheduledTask = _cron.schedule(cron.Schedule.parse(cronJob), () async {
      debug('$runtimeType - resuming cron job : ${DateTime.now().toString()}');
      _scheduleTimers();
    });
  }

  void _scheduleTimers() {
    // empty the list of timers.
    _timers = [];

    // get a random number of trigger time for today, and for each set up a
    // timer that triggers the super.onResume() method.
    samplingTimes.forEach((time) {
      // find the delay - note, that none of the delays can be negative,
      // since we are at [startTime] or after
      Duration delay = time.difference(TimeOfDay.now());
      debug('$runtimeType - setting up timer for : $time, delay: $delay');
      Timer timer = Timer(delay, () async {
        await super.onResume();
        // now set up a timer that waits until the sampling duration ends
        Timer(duration, () => super.onPause());
      });
      _timers.add(timer);
    });

    // mark this day as scheduled
    configuration!.lastTriggerTimestamp = DateTime.now();
  }

  @override
  Future<void> onPause() async {
    // cancel all the timers that might have been started
    for (var timer in _timers) {
      timer.cancel();
    }
    // cancel the daily cron job
    await _scheduledTask.cancel();
    await super.onPause();
  }
}
