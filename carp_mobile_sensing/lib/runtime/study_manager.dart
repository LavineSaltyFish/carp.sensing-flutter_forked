/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of runtime;

/// An interface defining a manger of a [StudyProtocol].
///
/// Is mainly used to get and save a [StudyProtocol].
/// See [FileStudyManager] for an implementation which can load and save
/// study json configurations on the local file system.
abstract class StudyManager {
  /// Initialize the study manager.
  Future initialize();

  /// Get a [StudyProtocol] based on its ID.
  Future<StudyProtocol> getStudy(String studyId);

  /// Save a [StudyProtocol].
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> saveStudy(StudyProtocol study);
}
