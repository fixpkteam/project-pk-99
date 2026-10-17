import 'package:fixpk/features/care/data/public_content_repository.dart';
import 'package:fixpk/features/foundation/presentation/home_campaigns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'legal page renders the editable text field and handles malformed content',
    () {
      final policy = LegalContent.fromRow({
        'content_key': 'privacy_policy',
        'title': 'Privacy',
        'body': {'text': 'Approved policy'},
      });
      expect(policy.text, 'Approved policy');
      expect(
        LegalContent.fromRow({
          'body': ['invalid'],
        }).text,
        isEmpty,
      );
    },
  );
  test(
    'scheduled campaigns respect start and end times, including cached rows',
    () {
      final campaign = HomeCampaign({
        'starts_at': '2026-10-13T10:00:00Z',
        'ends_at': '2026-10-14T10:00:00Z',
      });
      expect(campaign.isActive(DateTime.parse('2026-10-13T09:00:00Z')), false);
      expect(campaign.isActive(DateTime.parse('2026-10-13T10:00:00Z')), true);
      expect(campaign.isActive(DateTime.parse('2026-10-14T10:00:00Z')), false);
    },
  );
  test(
    'campaign navigation only accepts internal paths and secure image URLs',
    () {
      expect(
        const HomeCampaign({
          'target_path': '//outside.test',
          'image_path': 'file:///private',
        }).destination,
        isNull,
      );
      expect(
        const HomeCampaign({'image_path': 'http://example.test/image.png'})
            .imageUrl,
        isNull,
      );
      expect(
        const HomeCampaign({'target_path': '/services'}).destination,
        '/services',
      );
      expect(
        const HomeCampaign({'image_path': 'https://example.test/image.png'})
            .imageUrl,
        isNotNull,
      );
    },
  );
}
