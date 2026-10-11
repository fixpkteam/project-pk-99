import 'package:fixpk/features/care/data/care_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification mapping uses the approved deep-link fields', () {
    final notification = NotificationRecord.fromRow({
      'id': 'notification-1',
      'title': 'Quote ready',
      'body': 'Your FixPK quote is ready to review.',
      'notification_type': 'quote',
      'deep_link': '/requests/request-1',
      'read_at': null,
      'created_at': '2026-10-11T09:30:00Z',
    });

    expect(notification.title, 'Quote ready');
    expect(notification.deepLink, '/requests/request-1');
    expect(notification.isRead, isFalse);
  });

  test('support ticket mapping includes owner message and workflow status', () {
    final ticket = SupportTicketRecord.fromRow({
      'id': 'ticket-1',
      'subject': 'Appointment question',
      'message': 'Can I change the time?',
      'status': 'waiting_for_customer',
      'priority': 'normal',
      'created_at': '2026-10-10T10:00:00Z',
    });

    expect(ticket.subject, 'Appointment question');
    expect(ticket.status, 'waiting_for_customer');
    expect(ticket.priority, 'normal');
  });

  test('FAQ mapping handles published language rows', () {
    final faq = FaqRecord.fromRow({
      'id': 'faq-1',
      'question': 'How do I request a survey?',
      'answer': 'Open your request and choose Request survey.',
      'language_code': 'en',
      'sort_order': 4,
    });

    expect(faq.languageCode, 'en');
    expect(faq.sortOrder, 4);
  });

  test(
    'preferences default to enabled channels and serialize own settings',
    () {
      final defaults = UserPreferencesRecord.defaults('profile-1');
      expect(defaults.pushEnabled, isTrue);
      expect(defaults.emailEnabled, isTrue);
      expect(defaults.smsEnabled, isTrue);

      final saved = UserPreferencesRecord.fromRow({
        'profile_id': 'profile-1',
        'push_enabled': false,
        'email_enabled': true,
        'sms_enabled': false,
        'language_code': 'ur',
      });
      expect(saved.toRow(), {
        'profile_id': 'profile-1',
        'push_enabled': false,
        'email_enabled': true,
        'sms_enabled': false,
        'language_code': 'ur',
      });
    },
  );

  test('review and staff-role records map policy fields', () {
    final review = ReviewRecord.fromRow({
      'id': 'review-1',
      'job_id': 'job-1',
      'rating': 5,
      'review_text': 'Great work.',
      'status': 'pending',
      'created_at': '2026-10-10T10:00:00Z',
    });
    final role = StaffRoleRecord.fromRow({
      'user_id': 'profile-2',
      'role': 'operations',
    });

    expect(review.jobId, 'job-1');
    expect(review.rating, 5);
    expect(review.status, 'pending');
    expect(role.role, 'operations');
  });
}
