/*
 * Copyright 2019-2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of movisens;

/// A probe collecting data from the Movisens device using a [StreamProbe].
class MovisensProbe extends StreamProbe {
  MovisensDeviceManager get deviceManager =>
      super.deviceManager as MovisensDeviceManager;

  Stream<MovisensDatum>? get stream =>
      (deviceManager.movisens?.movisensStream != null)
          ? deviceManager.movisens!.movisensStream
              .map((event) => MovisensDatum.fromMap(
                    event,
                    deviceManager.deviceDescriptor.sensorName,
                  ))
          : null;
}
