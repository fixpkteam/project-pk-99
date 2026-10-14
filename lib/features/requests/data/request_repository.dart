import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import 'request_outbox.dart';
import '../../../core/storage/read_cache.dart';

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.area,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String area;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  factory CustomerAddress.fromRow(Map<String, dynamic> row) => CustomerAddress(
    id: '${row['id'] ?? ''}',
    label: '${row['label'] ?? 'Address'}',
    recipientName: '${row['recipient_name'] ?? ''}',
    phone: '${row['phone'] ?? ''}',
    addressLine: '${row['address_line'] ?? ''}',
    area: '${row['area'] ?? ''}',
    city: '${row['city'] ?? ''}',
    province: '${row['province'] ?? ''}',
    postalCode: '${row['postal_code'] ?? ''}',
    isDefault: row['is_default'] == true,
  );

  String get displayAddress => [
    addressLine,
    area,
    city,
    province,
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

class ServiceQuestionOption {
  const ServiceQuestionOption({required this.value, required this.label});
  final String value;
  final String label;

  factory ServiceQuestionOption.fromRow(Map<String, dynamic> row) =>
      ServiceQuestionOption(
        value: '${row['option_value'] ?? ''}',
        label: '${row['option_label'] ?? row['option_value'] ?? ''}',
      );
}

class ServiceQuestion {
  const ServiceQuestion({
    required this.id,
    required this.key,
    required this.label,
    required this.helpText,
    required this.inputType,
    required this.required,
    required this.options,
    required this.sortOrder,
  });

  final String id;
  final String key;
  final String label;
  final String helpText;
  final String inputType;
  final bool required;
  final List<ServiceQuestionOption> options;
  final int sortOrder;

  factory ServiceQuestion.fromRow(
    Map<String, dynamic> row, {
    List<ServiceQuestionOption> options = const [],
  }) => ServiceQuestion(
    id: '${row['id'] ?? ''}',
    key: '${row['question_key'] ?? row['id'] ?? ''}',
    label: '${row['label'] ?? 'Requirement'}',
    helpText: '${row['help_text'] ?? ''}',
    inputType: '${row['input_type'] ?? 'text'}',
    required: row['is_required'] == true,
    options: options,
    sortOrder: _asInt(row['sort_order']),
  );
}

class RequestRecord {
  const RequestRecord({
    required this.id,
    required this.reference,
    required this.serviceId,
    required this.addressId,
    required this.status,
    required this.notes,
    required this.preferredDate,
    required this.preferredTime,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String serviceId;
  final String addressId;
  final String status;
  final String notes;
  final String? preferredDate;
  final String? preferredTime;
  final DateTime? createdAt;

  factory RequestRecord.fromRow(Map<String, dynamic> row) => RequestRecord(
    id: '${row['id'] ?? ''}',
    reference: '${row['public_reference'] ?? row['id'] ?? ''}',
    serviceId: '${row['service_id'] ?? ''}',
    addressId: '${row['address_id'] ?? ''}',
    status: '${row['status'] ?? 'submitted'}',
    notes: '${row['customer_notes'] ?? ''}',
    preferredDate: row['preferred_date']?.toString(),
    preferredTime: row['preferred_time']?.toString(),
    createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
  );
}

class SurveyRecord {
  const SurveyRecord({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.completedAt,
  });

  final String id;
  final String status;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  factory SurveyRecord.fromRow(Map<String, dynamic> row) => SurveyRecord(
    id: '${row['id'] ?? ''}',
    status: '${row['status'] ?? 'requested'}',
    requestedAt: DateTime.tryParse('${row['requested_at'] ?? ''}'),
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.tryParse('${row['completed_at']}'),
  );
}

class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.customerNote,
  });

  final String id;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String customerNote;

  factory AppointmentRecord.fromRow(Map<String, dynamic> row) =>
      AppointmentRecord(
        id: '${row['id'] ?? ''}',
        status: '${row['status'] ?? 'requested'}',
        startsAt: DateTime.tryParse('${row['starts_at'] ?? ''}'),
        endsAt: row['ends_at'] == null
            ? null
            : DateTime.tryParse('${row['ends_at']}'),
        customerNote: '${row['customer_note'] ?? ''}',
      );
}

class QuoteLine {
  const QuoteLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  final String description;
  final num quantity;
  final num unitPrice;
  final num lineTotal;

  factory QuoteLine.fromRow(Map<String, dynamic> row) => QuoteLine(
    description: '${row['description'] ?? ''}',
    quantity: _asNum(row['quantity']),
    unitPrice: _asNum(row['unit_price']),
    lineTotal: _asNum(row['line_total']),
  );
}

class QuoteRecord {
  const QuoteRecord({
    required this.id,
    required this.revision,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.validUntil,
    required this.customerDecisionNote,
    required this.documentPath,
    required this.items,
  });

  final String id;
  final int revision;
  final String status;
  final String currency;
  final num subtotal;
  final num tax;
  final num total;
  final DateTime? validUntil;
  final String customerDecisionNote;
  final String? documentPath;
  final List<QuoteLine> items;

  bool get isActionable =>
      status == 'sent' &&
      (validUntil == null || validUntil!.isAfter(DateTime.now()));

  factory QuoteRecord.fromRow(
    Map<String, dynamic> row, {
    List<QuoteLine> items = const [],
  }) => QuoteRecord(
    id: '${row['id'] ?? ''}',
    revision: _asInt(row['revision']),
    status: '${row['status'] ?? 'draft'}',
    currency: '${row['currency'] ?? 'PKR'}'.trim(),
    subtotal: _asNum(row['subtotal']),
    tax: _asNum(row['tax']),
    total: _asNum(row['total']),
    validUntil: row['valid_until'] == null
        ? null
        : DateTime.tryParse('${row['valid_until']}'),
    customerDecisionNote: '${row['customer_decision_note'] ?? ''}',
    documentPath: row['document_path']?.toString(),
    items: items,
  );
}

class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.bytes,
    required this.contentType,
    required this.byteSize,
  });
  final String name;
  final Uint8List bytes;
  final String contentType;
  final int byteSize;
}

class PartialRequestSubmissionException implements Exception {
  const PartialRequestSubmissionException(this.requestId);
  final String requestId;
}

class RequestRepository {
  const RequestRepository(this._client, this._cache);
  final SupabaseClient _client;
  final ReadCache _cache;

  static const requestFields =
      'id,profile_id,service_id,address_id,service_area_id,public_reference,status,customer_notes,preferred_date,preferred_time,created_at,updated_at';

  Stream<List<CustomerAddress>> watchAddresses(
    String profileId,
  ) => _cache.watch(
    'user.$profileId.addresses',
    () async {
      final rows = await _client
          .from('addresses')
          .select(
            'id,label,recipient_name,phone,address_line,area,city,province,postal_code,is_default,created_at',
          )
          .eq('profile_id', profileId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(CustomerAddress.fromRow)
        .toList(growable: false),
  );

  Future<void> saveAddress({
    required String profileId,
    required String label,
    required String recipientName,
    required String phone,
    required String addressLine,
    required String area,
    required String city,
    required String province,
    required String postalCode,
    required bool makeDefault,
    String? addressId,
  }) async {
    if (makeDefault) {
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('profile_id', profileId);
    }
    final record = {
      'profile_id': profileId,
      'label': label.trim(),
      'recipient_name': recipientName.trim(),
      'phone': phone.trim(),
      'address_line': addressLine.trim(),
      'area': area.trim(),
      'city': city.trim(),
      'province': province.trim(),
      'postal_code': postalCode.trim().isEmpty ? null : postalCode.trim(),
      'is_default': makeDefault,
    };
    if (addressId == null) {
      await _client.from('addresses').insert(record);
    } else {
      await _client
          .from('addresses')
          .update(record)
          .eq('id', addressId)
          .eq('profile_id', profileId);
    }
  }

  Future<void> deleteAddress(String profileId, String addressId) async {
    await _client
        .from('addresses')
        .delete()
        .eq('id', addressId)
        .eq('profile_id', profileId);
  }

  Stream<List<ServiceQuestion>> watchQuestions(
    String serviceId,
  ) => _cache.watch(
    'questions.$serviceId',
    () async {
      final rows = await _client
          .from('service_questions')
          .select(
            'id,service_id,question_key,label,help_text,input_type,is_required,sort_order',
          )
          .eq('service_id', serviceId)
          .order('sort_order');
      if (rows.isEmpty) {
        return [<Map<String, dynamic>>[], <Map<String, dynamic>>[]];
      }
      final questionIds = rows.map((row) => row['id'].toString()).toList();
      final optionRows = await _client
          .from('service_question_options')
          .select('id,question_id,option_value,option_label,sort_order')
          .inFilter('question_id', questionIds)
          .order('sort_order');
      return [rows, optionRows];
    },
    (data) {
      final groups = data as List;
      final rows = (groups[0] as List).cast<Map<String, dynamic>>();
      final optionRows = (groups[1] as List).cast<Map<String, dynamic>>();
      final optionsByQuestion = <String, List<ServiceQuestionOption>>{};
      for (final row in optionRows) {
        optionsByQuestion
            .putIfAbsent(row['question_id'].toString(), () => [])
            .add(ServiceQuestionOption.fromRow(row));
      }
      return rows
          .map(
            (row) => ServiceQuestion.fromRow(
              row,
              options: optionsByQuestion[row['id'].toString()] ?? const [],
            ),
          )
          .toList(growable: false);
    },
  );

  Stream<List<RequestRecord>> watchRequests(String profileId) => _cache.watch(
    'user.$profileId.requests',
    () async {
      final rows = await _client
          .from('service_requests')
          .select(requestFields)
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(50);
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(RequestRecord.fromRow)
        .toList(growable: false),
  );

  Stream<RequestRecord?> watchRequest(String profileId, String requestId) =>
      _cache.watch(
        'user.$profileId.request.$requestId',
        () async {
          final row = await _client
              .from('service_requests')
              .select(requestFields)
              .eq('profile_id', profileId)
              .eq('id', requestId)
              .maybeSingle();
          return row;
        },
        (data) => data == null
            ? null
            : RequestRecord.fromRow(Map<String, dynamic>.from(data as Map)),
      );

  Stream<List<SurveyRecord>> watchSurveys(String requestId) => _cache.watch(
    'user.${_client.auth.currentUser?.id}.surveys.$requestId',
    () async {
      final rows = await _client
          .from('site_surveys')
          .select('id,request_id,status,requested_at,completed_at,created_at')
          .eq('request_id', requestId)
          .order('created_at', ascending: false);
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(SurveyRecord.fromRow)
        .toList(growable: false),
  );

  Stream<List<AppointmentRecord>> watchAppointments(
    String requestId,
  ) => _cache.watch(
    'user.${_client.auth.currentUser?.id}.appointments.$requestId',
    () async {
      final rows = await _client
          .from('appointments')
          .select(
            'id,request_id,survey_id,starts_at,ends_at,status,customer_note,created_at,updated_at',
          )
          .eq('request_id', requestId)
          .order('starts_at', ascending: true);
      return rows;
    },
    (data) => (data as List)
        .cast<Map<String, dynamic>>()
        .map(AppointmentRecord.fromRow)
        .toList(growable: false),
  );

  Stream<List<QuoteRecord>> watchQuotes(String requestId) => _cache.watch(
    'user.${_client.auth.currentUser?.id}.quotes.$requestId',
    () async {
      final rows = await _client
          .from('quotes')
          .select(
            'id,request_id,revision,status,currency,subtotal,tax,total,valid_until,customer_decision_note,decided_at,document_path,created_at,updated_at',
          )
          .eq('request_id', requestId)
          .neq('status', 'draft')
          .order('revision', ascending: false);
      if (rows.isEmpty) {
        return [<Map<String, dynamic>>[], <Map<String, dynamic>>[]];
      }
      final quoteIds = rows.map((row) => row['id'].toString()).toList();
      final itemRows = await _client
          .from('quote_items')
          .select(
            'id,quote_id,description,quantity,unit_price,line_total,sort_order',
          )
          .inFilter('quote_id', quoteIds)
          .order('sort_order');
      return [rows, itemRows];
    },
    (data) {
      final groups = data as List;
      final rows = (groups[0] as List).cast<Map<String, dynamic>>();
      final itemRows = (groups[1] as List).cast<Map<String, dynamic>>();
      final itemsByQuote = <String, List<QuoteLine>>{};
      for (final row in itemRows) {
        itemsByQuote
            .putIfAbsent(row['quote_id'].toString(), () => [])
            .add(QuoteLine.fromRow(row));
      }
      return rows
          .map(
            (row) => QuoteRecord.fromRow(
              row,
              items: itemsByQuote[row['id'].toString()] ?? const [],
            ),
          )
          .toList(growable: false);
    },
  );

  Future<void> sendQueuedRequest(
    QueuedRequest request,
    Future<Uint8List> Function(OutboxFile) readFile,
  ) async {
    void checkOwner() {
      if (_client.auth.currentUser?.id != request.ownerId) {
        throw const AuthException(
          'Sign in to the account that saved this request.',
        );
      }
    }

    checkOwner();
    await _client.rpc<dynamic>(
      'submit_service_request',
      params: {
        'p_request_id': request.id,
        'p_service_id': request.serviceId,
        'p_address_id': request.addressId,
        'p_customer_notes': request.notes,
        'p_preferred_date': request.preferredDate,
        'p_preferred_time': request.preferredTime,
        'p_answers': request.answers,
      },
    );
    for (final file in request.files) {
      checkOwner();
      final bytes = await readFile(file);
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '${request.ownerId}/${request.id}/${file.id}_$safeName';
      try {
        await _client.storage
            .from('request-attachments')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: file.contentType,
                upsert: false,
              ),
            );
      } on StorageException catch (error) {
        // A previous attempt may have completed before its response was lost.
        // Immutable UUID paths identify the exact same locally saved file.
        if (error.statusCode != '409' && error.error != 'Duplicate') rethrow;
      }
      checkOwner();
      await _client
          .from('request_attachments')
          .upsert(
            {
              'request_id': request.id,
              'uploaded_by': request.ownerId,
              'bucket_id': 'request-attachments',
              'object_path': path,
              'file_name': file.name,
              'content_type': file.contentType,
              'byte_size': file.size,
            },
            onConflict: 'object_path',
            ignoreDuplicates: true,
          );
    }
  }

  Future<String> requestSurvey({
    required String requestId,
    required DateTime preferredAt,
    String? note,
  }) async {
    final result = await _client.rpc<String>(
      'request_site_survey',
      params: {
        'p_request_id': requestId,
        'p_requested_at': preferredAt.toUtc().toIso8601String(),
        'p_notes': note?.trim().isEmpty == true ? null : note?.trim(),
      },
    );
    return result.toString();
  }

  Future<void> decideQuote({
    required String quoteId,
    required String decision,
    String? note,
  }) async {
    await _client.rpc<dynamic>(
      'decide_quote',
      params: {
        'p_quote_id': quoteId,
        'p_decision': decision,
        'p_note': note?.trim().isEmpty == true ? null : note?.trim(),
      },
    );
  }

  Future<String> createQuoteDocumentUrl(String path) =>
      _client.storage.from('quote-documents').createSignedUrl(path, 60 * 10);
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
num _asNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  // Drop in-memory private reads when the authenticated account changes.
  ref.watch(authUserProvider.select((state) => state.value?.id));
  return RequestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(readCacheProvider),
  );
});

final customerAddressesProvider =
    StreamProvider.family<List<CustomerAddress>, String>(
      (ref, profileId) =>
          ref.watch(requestRepositoryProvider).watchAddresses(profileId),
    );

final serviceQuestionsProvider =
    StreamProvider.family<List<ServiceQuestion>, String>(
      (ref, serviceId) =>
          ref.watch(requestRepositoryProvider).watchQuestions(serviceId),
    );

final customerRequestsProvider =
    StreamProvider.family<List<RequestRecord>, String>(
      (ref, profileId) =>
          ref.watch(requestRepositoryProvider).watchRequests(profileId),
    );

final requestDetailProvider =
    StreamProvider.family<
      RequestRecord?,
      ({String profileId, String requestId})
    >(
      (ref, args) => ref
          .watch(requestRepositoryProvider)
          .watchRequest(args.profileId, args.requestId),
    );

final surveyListProvider = StreamProvider.family<List<SurveyRecord>, String>(
  (ref, requestId) =>
      ref.watch(requestRepositoryProvider).watchSurveys(requestId),
);

final appointmentListProvider =
    StreamProvider.family<List<AppointmentRecord>, String>(
      (ref, requestId) =>
          ref.watch(requestRepositoryProvider).watchAppointments(requestId),
    );

final requestQuotesProvider = StreamProvider.family<List<QuoteRecord>, String>(
  (ref, requestId) =>
      ref.watch(requestRepositoryProvider).watchQuotes(requestId),
);
