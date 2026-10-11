import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';

class JobRecord {
  const JobRecord({
    required this.id,
    required this.requestId,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.completedAt,
    required this.updatedAt,
  });

  final String id;
  final String requestId;
  final String status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  factory JobRecord.fromRow(Map<String, dynamic> row) => JobRecord(
    id: '${row['id'] ?? ''}',
    requestId: '${row['request_id'] ?? ''}',
    status: '${row['status'] ?? 'scheduled'}',
    scheduledStart: DateTime.tryParse('${row['scheduled_start'] ?? ''}'),
    scheduledEnd: row['scheduled_end'] == null
        ? null
        : DateTime.tryParse('${row['scheduled_end']}'),
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.tryParse('${row['completed_at']}'),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.tryParse('${row['updated_at']}'),
  );
}

class JobsRepository {
  const JobsRepository(this._client);
  final SupabaseClient _client;

  Future<List<JobRecord>> fetchRequestJobs(String requestId) async {
    final rows = await _client
        .from('jobs')
        .select(
          'id,request_id,status,scheduled_start,scheduled_end,completed_at,created_at,updated_at',
        )
        .eq('request_id', requestId)
        .order('scheduled_start');
    return rows.map(JobRecord.fromRow).toList(growable: false);
  }

  Future<List<JobRecord>> fetchStaffJobs() async {
    final rows = await _client
        .from('jobs')
        .select(
          'id,request_id,status,scheduled_start,scheduled_end,completed_at,updated_at',
        )
        .order('scheduled_start')
        .limit(100);
    return rows.map(JobRecord.fromRow).toList(growable: false);
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    if (!const {
      'scheduled',
      'in_progress',
      'completed',
      'cancelled',
    }.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final updates = <String, dynamic>{'status': status, 'updated_at': now};
    if (status == 'completed') {
      updates['completed_at'] = now;
    }
    await _client.from('jobs').update(updates).eq('id', jobId);
  }
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepository(ref.watch(supabaseClientProvider)),
);

final requestJobsProvider = FutureProvider.family<List<JobRecord>, String>(
  (ref, requestId) =>
      ref.watch(jobsRepositoryProvider).fetchRequestJobs(requestId),
);

final staffJobListProvider = FutureProvider<List<JobRecord>>(
  (ref) => ref.watch(jobsRepositoryProvider).fetchStaffJobs(),
);
