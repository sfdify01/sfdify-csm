import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ustaxx_csm/features/consumer/domain/entities/consumer_entity.dart';

class ConsumerSelector extends StatelessWidget {
  const ConsumerSelector({
    super.key,
    required this.consumers,
    required this.selectedConsumerId,
    required this.onChanged,
  });

  final List<ConsumerEntity> consumers;
  final String? selectedConsumerId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: selectedConsumerId,
      decoration: InputDecoration(
        labelText: 'Consumer *',
        hintText: 'Select a consumer',
        prefixIcon: const Icon(Icons.person_outline),
        border: const OutlineInputBorder(),
        helperText: consumers.isEmpty ? 'No consumers available' : null,
      ),
      items: consumers.map((consumer) {
        return DropdownMenuItem<String>(
          value: consumer.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  consumer.initials,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Gap(8),
              Text(consumer.fullName),
              const Gap(8),
              Text(
                consumer.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a consumer';
        }
        return null;
      },
    );
  }
}
