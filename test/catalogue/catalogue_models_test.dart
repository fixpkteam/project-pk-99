import 'package:fixpk/features/catalogue/data/catalogue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps product price, availability and ordered specifications', () {
    final product = ProductRecord.fromRow(
      {
        'id': 'product-1',
        'category_id': 'category-1',
        'name': 'Hybrid inverter',
        'slug': 'hybrid-inverter',
        'summary': 'Efficient energy conversion',
        'description': 'For residential solar systems.',
        'sku': 'FIX-HYB-01',
        'price': '125000.00',
        'currency': 'PKR',
        'is_available': true,
      },
      images: const [
        ProductImageRecord(
          url: 'https://cdn.example.com/inverter.jpg',
          altText: 'Hybrid inverter',
          sortOrder: 0,
        ),
      ],
      specifications: const [
        ProductSpecificationRecord(
          name: 'Capacity',
          value: '5 kW',
          sortOrder: 0,
        ),
      ],
    );

    expect(product.id, 'product-1');
    expect(product.price, 125000);
    expect(product.isAvailable, isTrue);
    expect(product.images.single.altText, 'Hybrid inverter');
    expect(product.specifications.single.value, '5 kW');
  });

  test('maps published project details and completion date', () {
    final project = ProjectRecord.fromRow({
      'id': 'project-1',
      'title': 'Commercial solar installation',
      'slug': 'commercial-solar-installation',
      'category': 'Solar',
      'summary': 'Solar installation for a commercial property.',
      'description': 'Design, supply and commissioning.',
      'location': 'Islamabad',
      'completed_on': '2026-09-20',
      'sort_order': 2,
    });

    expect(project.title, 'Commercial solar installation');
    expect(project.location, 'Islamabad');
    expect(project.completedOn, DateTime(2026, 9, 20));
  });
}
