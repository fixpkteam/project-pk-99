import 'package:fixpk/features/admin/data/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin content registry only exposes supported app sections', () {
    expect(adminTableByKey('products')?.table, 'products');
    expect(adminTableByKey('projects')?.table, 'projects');
    expect(adminTableByKey('service-questions')?.table, 'service_questions');
    expect(adminTableByKey('unknown'), isNull);
    expect(adminContentTables.length, greaterThanOrEqualTo(12));
  });

  test('content editor keeps database-managed fields read only', () {
    expect(isAdminEditableField('name'), isTrue);
    expect(isAdminEditableField('is_published'), isTrue);
    expect(isAdminEditableField('id'), isFalse);
    expect(isAdminEditableField('created_at'), isFalse);
    expect(isAdminEditableField('updated_at'), isFalse);
    final products = adminTableByKey('products')!;
    expect(isAdminTableFieldEditable(products, 'name'), isTrue);
    expect(isAdminTableFieldEditable(products, 'profile_id'), isFalse);
  });

  test('admin foreign-key fields resolve to the correct picker sources', () {
    expect(
      adminReferenceTableForField('services', 'category_id'),
      'service-categories',
    );
    expect(
      adminReferenceTableForField('service_questions', 'service_id'),
      'services',
    );
    expect(
      adminReferenceTableForField('product_images', 'product_id'),
      'products',
    );
    expect(adminReferenceTableForField('unknown', 'profile_id'), isNull);
  });

  test('admin user response maps account, role and suspension fields', () {
    final record = AdminUserRecord.fromJson({
      'id': 'profile-1',
      'email': 'customer@example.com',
      'user_metadata': {'full_name': 'Test Customer', 'phone': '+923000000000'},
      'roles': ['support'],
      'banned_until': null,
      'created_at': '2026-10-01T10:00:00Z',
      'last_sign_in_at': '2026-10-10T10:00:00Z',
    });

    expect(record.id, 'profile-1');
    expect(record.email, 'customer@example.com');
    expect(record.name, 'Test Customer');
    expect(record.phone, '+923000000000');
    expect(record.roles, ['support']);
    expect(record.isSuspended, isFalse);
  });
}
