import 'package:flutter_test/flutter_test.dart';
import 'package:fixpk/features/requests/data/request_repository.dart';

void main() {
  group('request records', () {
    test('maps request fields and falls back to the id for its reference', () {
      final request = RequestRecord.fromRow({
        'id': 'request-1',
        'service_id': 'service-1',
        'address_id': 'address-1',
        'status': 'submitted',
        'customer_notes': 'Please call first',
        'preferred_date': '2026-10-15',
        'preferred_time': '10:30:00',
        'created_at': '2026-10-11T10:00:00Z',
      });

      expect(request.reference, 'request-1');
      expect(request.serviceId, 'service-1');
      expect(request.addressId, 'address-1');
      expect(request.notes, 'Please call first');
      expect(request.preferredDate, '2026-10-15');
      expect(request.preferredTime, '10:30:00');
      expect(request.createdAt, DateTime.utc(2026, 10, 11, 10));
    });

    test('maps survey and appointment times without staff-only fields', () {
      final survey = SurveyRecord.fromRow({
        'id': 'survey-1',
        'status': 'scheduled',
        'requested_at': '2026-10-14T09:00:00Z',
        'completed_at': null,
      });
      final appointment = AppointmentRecord.fromRow({
        'id': 'appointment-1',
        'status': 'confirmed',
        'starts_at': '2026-10-14T09:00:00Z',
        'ends_at': '2026-10-14T10:00:00Z',
        'customer_note': 'Please ring the bell',
      });

      expect(survey.status, 'scheduled');
      expect(survey.completedAt, isNull);
      expect(appointment.status, 'confirmed');
      expect(appointment.startsAt, DateTime.utc(2026, 10, 14, 9));
      expect(appointment.customerNote, 'Please ring the bell');
    });
  });

  test('maps quote totals, numeric strings, and quote items', () {
    final quote = QuoteRecord.fromRow(
      {
        'id': 'quote-1',
        'revision': '2',
        'status': 'sent',
        'currency': 'PKR',
        'subtotal': '12000.00',
        'tax': 0,
        'total': '12000.00',
        'valid_until': null,
        'customer_decision_note': null,
      },
      items: [
        QuoteLine.fromRow({
          'description': 'Installation',
          'quantity': '1',
          'unit_price': '12000',
          'line_total': '12000',
        }),
      ],
    );

    expect(quote.revision, 2);
    expect(quote.total, 12000);
    expect(quote.items.single.description, 'Installation');
    expect(quote.items.single.lineTotal, 12000);
    expect(quote.isActionable, isTrue);
  });
}
