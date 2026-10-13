import 'package:flutter/material.dart';

/// Account location is entered by the customer; no GPS permission is needed.
/// It is separate from the full service address collected when booking.
class LocationFields extends StatelessWidget {
  const LocationFields({
    super.key,
    required this.country,
    required this.city,
    this.enabled = true,
  });

  final TextEditingController country;
  final TextEditingController city;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextFormField(
        key: const ValueKey('account-country'),
        controller: country,
        enabled: enabled,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.countryName],
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'Country',
          prefixIcon: Icon(Icons.public_outlined),
          counterText: '',
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Enter your country.'
            : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const ValueKey('account-city'),
        controller: city,
        enabled: enabled,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.addressCity],
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: 'City',
          hintText: 'e.g. Islamabad or Rawalpindi',
          prefixIcon: Icon(Icons.location_city_outlined),
          counterText: '',
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter your city.' : null,
      ),
    ],
  );
}
