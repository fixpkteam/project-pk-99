import 'package:fixpk/core/storage/app_storage.dart';

class MemoryPreferences implements PreferencesStore {
  MemoryPreferences({this.completed = false});
  bool completed;
  bool failReads = false;
  bool failWrites = false;
  int writes = 0;

  @override
  Future<bool> getOnboardingCompleted() async {
    if (failReads) throw StateError('Cannot read preferences');
    return completed;
  }

  @override
  Future<void> setOnboardingCompleted({required bool completed}) async {
    if (failWrites) throw StateError('Cannot write preferences');
    this.completed = completed;
    writes++;
  }
}
