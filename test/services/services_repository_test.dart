import 'package:fixpk/features/services/data/services_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service row maps catalogue and category identifiers', () {
    final service = ServiceItem.fromRow({
      'id': 'service-1',
      'service_category_id': 'category-1',
      'title': 'Solar installation',
      'short_description': 'Residential and commercial installation.',
      'sort_order': 3,
    });

    expect(service.id, 'service-1');
    expect(service.categoryId, 'category-1');
    expect(service.name, 'Solar installation');
    expect(service.description, 'Residential and commercial installation.');
    expect(service.sortOrder, 3);
  });

  test('category row supports title-based catalogue schemas', () {
    final category = ServiceCategory.fromRow({
      'slug': 'solar',
      'title': 'Solar Solutions',
      'description': 'Solar design and installation.',
      'sort_order': 1,
    });

    expect(category.id, 'solar');
    expect(category.name, 'Solar Solutions');
    expect(category.description, 'Solar design and installation.');
    expect(category.sortOrder, 1);
  });
}
