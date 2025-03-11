import 'package:flutter/material.dart';

class FeedFilter extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const FeedFilter({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: currentFilter,
      onSelected: onFilterChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All')),
        const PopupMenuItem(value: 'academic', child: Text('Academic')),
        const PopupMenuItem(value: 'social', child: Text('Social')),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(currentFilter.toUpperCase()),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
