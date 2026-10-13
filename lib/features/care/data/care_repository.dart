import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/storage/read_cache.dart';

class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.deepLink,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String? deepLink;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory NotificationRecord.fromRow(Map<String, dynamic> row) =>
      NotificationRecord(
        id: '${row['id'] ?? ''}',
        title: '${row['title'] ?? 'FixPK update'}',
        body: '${row['body'] ?? ''}',
        type: '${row['notification_type'] ?? 'general'}',
        deepLink: row['deep_link']?.toString(),
        readAt: row['read_at'] == null
            ? null
            : DateTime.tryParse('${row['read_at']}'),
        createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
      );
}

class SupportTicketRecord {
  const SupportTicketRecord({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final DateTime? createdAt;

  factory SupportTicketRecord.fromRow(Map<String, dynamic> row) =>
      SupportTicketRecord(
        id: '${row['id'] ?? ''}',
        subject: '${row['subject'] ?? ''}',
        message: '${row['message'] ?? ''}',
        status: '${row['status'] ?? 'open'}',
        priority: '${row['priority'] ?? 'normal'}',
        createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
      );
}

class FaqRecord {
  const FaqRecord({
    required this.id,
    required this.question,
    required this.answer,
    required this.languageCode,
    required this.sortOrder,
  });

  final String id;
  final String question;
  final String answer;
  final String languageCode;
  final int sortOrder;

  factory FaqRecord.fromRow(Map<String, dynamic> row) => FaqRecord(
    id: '${row['id'] ?? ''}',
    question: '${row['question'] ?? ''}',
    answer: '${row['answer'] ?? ''}',
    languageCode: '${row['language_code'] ?? 'en'}',
    sortOrder: _asInt(row['sort_order']),
  );
}

class UserPreferencesRecord {
  const UserPreferencesRecord({
    required this.profileId,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.languageCode,
  });

  final String profileId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final String languageCode;

  factory UserPreferencesRecord.defaults(String profileId) =>
      UserPreferencesRecord(
        profileId: profileId,
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: true,
        languageCode: 'en',
      );

  factory UserPreferencesRecord.fromRow(Map<String, dynamic> row) =>
      UserPreferencesRecord(
        profileId: '${row['profile_id'] ?? ''}',
        pushEnabled: row['push_enabled'] != false,
        emailEnabled: row['email_enabled'] != false,
        smsEnabled: row['sms_enabled'] != false,
        languageCode: '${row['language_code'] ?? 'en'}',
      );

  Map<String, dynamic> toRow() => {
    'profile_id': profileId,
    'push_enabled': pushEnabled,
    'email_enabled': emailEnabled,
    'sms_enabled': smsEnabled,
    'language_code': languageCode,
  };
}

class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.jobId,
    required this.rating,
    required this.reviewText,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final int rating;
  final String reviewText;
  final String status;
  final DateTime? createdAt;

  factory ReviewRecord.fromRow(Map<String, dynamic> row) => ReviewRecord(
    id: '${row['id'] ?? ''}',
    jobId: '${row['job_id'] ?? ''}',
    rating: _asInt(row['rating']),
    reviewText: '${row['review_text'] ?? ''}',
    status: '${row['status'] ?? 'pending'}',
    createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
  );
}

class StaffRoleRecord {
  const StaffRoleRecord({required this.userId, required this.role});
  final String userId;
  final String role;

  factory StaffRoleRecord.fromRow(Map<String, dynamic> row) => StaffRoleRecord(
    userId: '${row['user_id'] ?? ''}',
    role: '${row['role'] ?? ''}',
  );
}

class StaffRequestSummary {
  const StaffRequestSummary({
    required this.id,
    required this.reference,
    required this.serviceId,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String reference;
  final String serviceId;
  final String status;
  final DateTime? createdAt;

  factory StaffRequestSummary.fromRow(Map<String, dynamic> row) =>
      StaffRequestSummary(
        id: '${row['id'] ?? ''}',
        reference: '${row['public_reference'] ?? row['id'] ?? ''}',
        serviceId: '${row['service_id'] ?? ''}',
        status: '${row['status'] ?? 'submitted'}',
        createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
      );
}

class CareRepository {
  const CareRepository(this._client, this._cache);
  final SupabaseClient _client;
  final ReadCache _cache;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Stream<List<NotificationRecord>> watchNotifications(String profileId) =>
      _cache.watch(
        'user.$profileId.notifications',
        () async {
          final rows = await _client
              .from('notifications')
              .select(
                'id,title,body,notification_type,deep_link,read_at,created_at',
              )
              .eq('profile_id', profileId)
              .order('created_at', ascending: false)
              .limit(100);
          return rows;
        },
        (data) => (data as List)
            .cast<Map<String, dynamic>>()
            .map(NotificationRecord.fromRow)
            .toList(growable: false),
      );

  Future<void> markNotificationRead(String profileId, String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('profile_id', profileId);
  }

  Stream<List<SupportTicketRecord>> watchTickets(String profileId) =>
      _cache.watch(
        'user.$profileId.tickets',
        () async {
          final rows = await _client
              .from('support_tickets')
              .select(
                'id,subject,message,status,priority,created_at,updated_at',
              )
              .eq('profile_id', profileId)
              .order('created_at', ascending: false)
              .limit(50);
          return rows;
        },
        (data) => (data as List)
            .cast<Map<String, dynamic>>()
            .map(SupportTicketRecord.fromRow)
            .toList(growable: false),
      );

  Future<void> createTicket({
    required String subject,
    required String message,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('Sign in required.');
    await _client.from('support_tickets').insert({
      'profile_id': userId,
      'subject': subject.trim(),
      'message': message.trim(),
      'status': 'open',
    });
  }

  Stream<List<FaqRecord>> watchFaq(String languageCode) => _cache.watch(
    'faq.$languageCode',
    () async {
      final rows = await _client
          .from('faq')
          .select('id,question,answer,language_code,sort_order')
          .eq('is_published', true)
          .eq('language_code', languageCode)
          .order('sort_order');
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(FaqRecord.fromRow)
        .toList(growable: false),
  );

  Future<UserPreferencesRecord> fetchPreferences(String profileId) async {
    final row = await _client
        .from('user_preferences')
        .select(
          'profile_id,push_enabled,email_enabled,sms_enabled,language_code',
        )
        .eq('profile_id', profileId)
        .maybeSingle();
    return row == null
        ? UserPreferencesRecord.defaults(profileId)
        : UserPreferencesRecord.fromRow(row);
  }

  Future<void> savePreferences(UserPreferencesRecord value) async {
    await _client.from('user_preferences').upsert(value.toRow());
  }

  Stream<List<ReviewRecord>> watchOwnReviews(String profileId) => _cache.watch(
    'user.$profileId.reviews',
    () async {
      final rows = await _client
          .from('reviews')
          .select('id,job_id,rating,review_text,status,created_at')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false);
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(ReviewRecord.fromRow)
        .toList(growable: false),
  );

  Future<void> submitReview({
    required String jobId,
    required int rating,
    required String reviewText,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('Sign in required.');
    await _client.from('reviews').insert({
      'profile_id': userId,
      'job_id': jobId,
      'rating': rating,
      'review_text': reviewText.trim().isEmpty ? null : reviewText.trim(),
    });
  }

  Future<List<StaffRoleRecord>> fetchStaffRoles(String userId) async {
    final rows = await _client
        .from('user_roles')
        .select('user_id,role')
        .eq('user_id', userId);
    return rows.map(StaffRoleRecord.fromRow).toList(growable: false);
  }

  Future<List<StaffRequestSummary>> fetchStaffRequests() async {
    final rows = await _client
        .from('service_requests')
        .select('id,public_reference,service_id,status,created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(StaffRequestSummary.fromRow).toList(growable: false);
  }

  Future<List<SupportTicketRecord>> fetchStaffTickets() async {
    final rows = await _client
        .from('support_tickets')
        .select('id,subject,message,status,priority,created_at,updated_at')
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(SupportTicketRecord.fromRow).toList(growable: false);
  }

  Future<List<ReviewRecord>> fetchPendingReviews() async {
    final rows = await _client
        .from('reviews')
        .select('id,job_id,rating,review_text,status,created_at')
        .eq('status', 'pending')
        .order('created_at', ascending: true)
        .limit(50);
    return rows.map(ReviewRecord.fromRow).toList(growable: false);
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    if (!const {
      'open',
      'in_progress',
      'waiting_for_customer',
      'resolved',
      'closed',
    }.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await _client
        .from('support_tickets')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  Future<void> moderateReview(String reviewId, String status) async {
    if (status != 'published' && status != 'rejected') {
      throw ArgumentError.value(status, 'status');
    }
    await _client
        .from('reviews')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reviewId);
  }
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

final careRepositoryProvider = Provider<CareRepository>((ref) {
  // Drop in-memory private reads when the authenticated account changes.
  ref.watch(authUserProvider.select((state) => state.value?.id));
  return CareRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(readCacheProvider),
  );
});

final notificationListProvider =
    StreamProvider.family<List<NotificationRecord>, String>(
      (ref, profileId) =>
          ref.watch(careRepositoryProvider).watchNotifications(profileId),
    );

final supportTicketListProvider =
    StreamProvider.family<List<SupportTicketRecord>, String>(
      (ref, profileId) =>
          ref.watch(careRepositoryProvider).watchTickets(profileId),
    );

final faqListProvider = StreamProvider.family<List<FaqRecord>, String>(
  (ref, languageCode) =>
      ref.watch(careRepositoryProvider).watchFaq(languageCode),
);

final userPreferencesProvider =
    FutureProvider.family<UserPreferencesRecord, String>(
      (ref, profileId) =>
          ref.watch(careRepositoryProvider).fetchPreferences(profileId),
    );

final ownReviewListProvider = StreamProvider.family<List<ReviewRecord>, String>(
  (ref, profileId) =>
      ref.watch(careRepositoryProvider).watchOwnReviews(profileId),
);

final staffRoleListProvider =
    FutureProvider.family<List<StaffRoleRecord>, String>(
      (ref, profileId) =>
          ref.watch(careRepositoryProvider).fetchStaffRoles(profileId),
    );

final staffRequestListProvider = FutureProvider<List<StaffRequestSummary>>(
  (ref) => ref.watch(careRepositoryProvider).fetchStaffRequests(),
);

final staffTicketListProvider = FutureProvider<List<SupportTicketRecord>>(
  (ref) => ref.watch(careRepositoryProvider).fetchStaffTickets(),
);

final pendingReviewListProvider = FutureProvider<List<ReviewRecord>>(
  (ref) => ref.watch(careRepositoryProvider).fetchPendingReviews(),
);
