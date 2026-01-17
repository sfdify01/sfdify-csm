import 'package:flutter/material.dart';

class ConsumerSearchBar extends StatefulWidget {
  const ConsumerSearchBar({
    super.key,
    required this.onSearchChanged,
    this.initialQuery = '',
  });

  final ValueChanged<String> onSearchChanged;
  final String initialQuery;

  @override
  State<ConsumerSearchBar> createState() => _ConsumerSearchBarState();
}

class _ConsumerSearchBarState extends State<ConsumerSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 400,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {});
          widget.onSearchChanged(value);
        },
      ),
    );
  }
}
