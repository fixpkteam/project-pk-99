import 'package:fixpk/features/jobs/data/jobs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps customer-visible job progress without staff fields', () {
    final job = JobRecord.fromRow({
      'id': 'job-1',
      'request_id': 'request-1',
      'status': 'in_progress',
      'scheduled_start': '2026-10-15T09:00:00Z',
      'scheduled_end': '2026-10-15T12:00:00Z',
      'completed_at': null,
      'updated_at': '2026-10-15T10:00:00Z',
      'staff_notes': 'Internal assignment note',
    });

    expect(job.requestId, 'request-1');
    expect(job.status, 'in_progress');
    expect(job.scheduledStart, DateTime.utc(2026, 10, 15, 9));
    expect(job.completedAt, isNull);
    expect(job.updatedAt, DateTime.utc(2026, 10, 15, 10));
  });
}
