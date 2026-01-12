import 'package:flutter/material.dart';
import 'package:sfdify_scm/core/constants/dispute_constants.dart';

class BureauFilterChips extends StatelessWidget {
  const BureauFilterChips({
    required this.selectedBureau,
    required this.onBureauSelected,
    super.key,
  });

  final String? selectedBureau;
  final ValueChanged<String?> onBureauSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('All Bureaus'),
          selected: selectedBureau == null,
          onSelected: (_) => onBureauSelected(null),
        ),
        FilterChip(
          label: const Text('Equifax'),
          selected: selectedBureau == DisputeConstants.bureauEquifax,
          onSelected: (_) => onBureauSelected(DisputeConstants.bureauEquifax),
        ),
        FilterChip(
          label: const Text('Experian'),
          selected: selectedBureau == DisputeConstants.bureauExperian,
          onSelected: (_) => onBureauSelected(DisputeConstants.bureauExperian),
        ),
        FilterChip(
          label: const Text('TransUnion'),
          selected: selectedBureau == DisputeConstants.bureauTransUnion,
          onSelected: (_) =>
              onBureauSelected(DisputeConstants.bureauTransUnion),
        ),
      ],
    );
  }
}
