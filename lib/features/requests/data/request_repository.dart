import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';

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
  const RequestRepository(this._client);
  final SupabaseClient _client;

  static const requestFields =
      'id,profile_id,service_id,address_id,service_area_id,public_reference,status,customer_notes,preferred_date,preferred_time,created_at,updated_at';

  Future<List<CustomerAddress>> fetchAddresses(String profileId) async {
    final rows = await _client
        .from('addresses')
        .select(
          'id,label,recipient_name,phone,address_line,area,city,province,postal_code,is_default,created_at',
        )
        .eq('profile_id', profileId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows
        .map((row) => CustomerAddress.fromRow(row))
        .toList(growable: false);
  }

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

  Future<List<ServiceQuestion>> fetchQuestions(String serviceId) async {
    final rows = await _client
        .from('service_questions')
        .select(
          'id,service_id,question_key,label,help_text,input_type,is_required,sort_order',
        )
        .eq('service_id', serviceId)
        .order('sort_order');
    if (rows.isEmpty) return const [];
    final questionIds = rows.map((row) => row['id'].toString()).toList();
    final optionRows = await _client
        .from('service_question_options')
        .select('id,question_id,option_value,option_label,sort_order')
        .inFilter('question_id', questionIds)
        .order('sort_order');
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
  }

  Future<List<RequestRecord>> fetchRequests(String profileId) async {
    final rows = await _client
        .from('service_requests')
        .select(requestFields)
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(RequestRecord.fromRow).toList(growable: false);
  }

  Future<RequestRecord?> fetchRequest(
    String profileId,
    String requestId,
  ) async {
    final row = await _client
        .from('service_requests')
        .select(requestFields)
        .eq('profile_id', profileId)
        .eq('id', requestId)
        .maybeSingle();
    return row == null ? null : RequestRecord.fromRow(row);
  }

  Future<List<SurveyRecord>> fetchSurveys(String requestId) async {
    final rows = await _client
        .from('site_surveys')
        .select('id,request_id,status,requested_at,completed_at,created_at')
        .eq('request_id', requestId)
        .order('created_at', ascending: false);
    return rows.map(SurveyRecord.fromRow).toList(growable: false);
  }

  Future<List<AppointmentRecord>> fetchAppointments(String requestId) async {
    final rows = await _client
        .from('appointments')
        .select(
          'id,request_id,survey_id,starts_at,ends_at,status,customer_note,created_at,updated_at',
        )
        .eq('request_id', requestId)
        .order('starts_at', ascending: true);
    return rows.map(AppointmentRecord.fromRow).toList(growable: false);
  }

  Future<List<QuoteRecord>> fetchQuotes(String requestId) async {
    final rows = await _client
        .from('quotes')
        .select(
          'id,request_id,revision,status,currency,subtotal,tax,total,valid_until,customer_decision_note,decided_at,document_path,created_at,updated_at',
        )
        .eq('request_id', requestId)
        .neq('status', 'draft')
        .order('revision', ascending: false);
    if (rows.isEmpty) return const [];
    final quoteIds = rows.map((row) => row['id'].toString()).toList();
    final itemRows = await _client
        .from('quote_items')
        .select(
          'id,quote_id,description,quantity,unit_price,line_total,sort_order',
        )
        .inFilter('quote_id', quoteIds)
        .order('sort_order');
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
  }

  Future<String> submitRequest({
    required String profileId,
    required String serviceId,
    required String addressId,
    required Map<ServiceQuestion, dynamic> answers,
    required List<PickedAttachment> attachments,
    required String customerNotes,
    DateTime? preferredAt,
  }) async {
    final inserted = await _client
        .from('service_requests')
        .insert({
          'profile_id': profileId,
          'service_id': serviceId,
          'address_id': addressId,
          'status': 'submitted',
          'customer_notes': customerNotes.trim().isEmpty
              ? null
              : customerNotes.trim(),
          'preferred_date': preferredAt == null ? null : _dateOnly(preferredAt),
          'preferred_time': preferredAt == null
              ? null
              : '${preferredAt.hour.toString().padLeft(2, '0')}:${preferredAt.minute.toString().padLeft(2, '0')}:00',
        })
        .select('id')
        .single();
    final requestId = inserted['id'].toString();
    try {
      if (answers.isNotEmpty) {
        await _client
            .from('service_request_answers')
            .insert(
              answers.entries
                  .map(
                    (entry) => {
                      'request_id': requestId,
                      'question_id': entry.key.id,
                      'answer_value': entry.value,
                    },
                  )
                  .toList(),
            );
      }
      for (final attachment in attachments) {
        await _uploadAttachment(profileId, requestId, attachment);
      }
    } on Object {
      // The request row is already durable. Surface its ID so the UI can
      // direct the customer to the saved request rather than create a duplicate.
      throw PartialRequestSubmissionException(requestId);
    }
    return requestId;
  }

  Future<void> _uploadAttachment(
    String profileId,
    String requestId,
    PickedAttachment attachment,
  ) async {
    final safeName = attachment.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final objectPath =
        '$profileId/$requestId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    await _client.storage
        .from('request-attachments')
        .uploadBinary(
          objectPath,
          attachment.bytes,
          fileOptions: FileOptions(
            contentType: attachment.contentType,
            upsert: false,
          ),
        );
    await _client.from('request_attachments').insert({
      'request_id': requestId,
      'uploaded_by': profileId,
      'bucket_id': 'request-attachments',
      'object_path': objectPath,
      'file_name': attachment.name,
      'content_type': attachment.contentType,
      'byte_size': attachment.byteSize,
    });
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

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
num _asNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepository(ref.watch(supabaseClientProvider)),
);

final customerAddressesProvider =
    FutureProvider.family<List<CustomerAddress>, String>(
      (ref, profileId) =>
          ref.watch(requestRepositoryProvider).fetchAddresses(profileId),
    );

final serviceQuestionsProvider =
    FutureProvider.family<List<ServiceQuestion>, String>(
      (ref, serviceId) =>
          ref.watch(requestRepositoryProvider).fetchQuestions(serviceId),
    );

final customerRequestsProvider =
    FutureProvider.family<List<RequestRecord>, String>(
      (ref, profileId) =>
          ref.watch(requestRepositoryProvider).fetchRequests(profileId),
    );

final requestDetailProvider =
    FutureProvider.family<
      RequestRecord?,
      ({String profileId, String requestId})
    >(
      (ref, args) => ref
          .watch(requestRepositoryProvider)
          .fetchRequest(args.profileId, args.requestId),
    );

final surveyListProvider = FutureProvider.family<List<SurveyRecord>, String>(
  (ref, requestId) =>
      ref.watch(requestRepositoryProvider).fetchSurveys(requestId),
);

final appointmentListProvider =
    FutureProvider.family<List<AppointmentRecord>, String>(
      (ref, requestId) =>
          ref.watch(requestRepositoryProvider).fetchAppointments(requestId),
    );

final requestQuotesProvider = FutureProvider.family<List<QuoteRecord>, String>(
  (ref, requestId) =>
      ref.watch(requestRepositoryProvider).fetchQuotes(requestId),
);
