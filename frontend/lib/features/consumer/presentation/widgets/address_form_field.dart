import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AddressFormField extends StatelessWidget {
  const AddressFormField({
    super.key,
    this.streetController,
    this.cityController,
    this.stateController,
    this.zipCodeController,
  });

  final TextEditingController? streetController;
  final TextEditingController? cityController;
  final TextEditingController? stateController;
  final TextEditingController? zipCodeController;

  static const List<String> _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),

        // Street Address
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(
            labelText: 'Street Address',
            hintText: '123 Main Street, Apt 4B',
            prefixIcon: Icon(Icons.home_outlined),
          ),
          textInputAction: TextInputAction.next,
        ),
        const Gap(16),

        // City, State, Zip Row
        Row(
          children: [
            // City
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'New York',
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const Gap(16),

            // State
            Expanded(
              child: DropdownButtonFormField<String>(
                value: stateController?.text.isEmpty ?? true
                    ? null
                    : stateController?.text,
                decoration: const InputDecoration(
                  labelText: 'State',
                ),
                items: _usStates
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (stateController != null && value != null) {
                    stateController!.text = value;
                  }
                },
              ),
            ),
            const Gap(16),

            // Zip Code
            Expanded(
              child: TextFormField(
                controller: zipCodeController,
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  hintText: '10001',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
                      return 'Invalid ZIP';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
