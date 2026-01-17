import 'package:flutter/material.dart';

class BureauSelector extends StatelessWidget {
  const BureauSelector({
    super.key,
    required this.selectedBureau,
    required this.onChanged,
  });

  final String? selectedBureau;
  final ValueChanged<String?> onChanged;

  static const List<({String value, String label, String description})> bureaus = [
    (
      value: 'equifax',
      label: 'Equifax',
      description: 'One of the three major credit bureaus'
    ),
    (
      value: 'experian',
      label: 'Experian',
      description: 'One of the three major credit bureaus'
    ),
    (
      value: 'transunion',
      label: 'TransUnion',
      description: 'One of the three major credit bureaus'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedBureau,
      decoration: const InputDecoration(
        labelText: 'Bureau *',
        hintText: 'Select a credit bureau',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      items: bureaus.map((bureau) {
        return DropdownMenuItem<String>(
          value: bureau.value,
          child: Text(bureau.label),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a bureau';
        }
        return null;
      },
    );
  }
}
