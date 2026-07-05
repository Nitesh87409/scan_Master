import 'package:flutter/material.dart';
import '../utils/file_filter_util.dart';

class FileFilterBar extends StatelessWidget {
  final FileFilterType currentFilter;
  final ValueChanged<FileFilterType> onFilterChanged;

  const FileFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: FileFilterType.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade300 
                          : Colors.grey.shade800),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12, // Reduced size by 20%
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.purple,
              backgroundColor: Colors.transparent, // Transparent background
              showCheckmark: false, // Cleaner look without checkmark
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Curved corners
                side: BorderSide(
                  color: isSelected ? Colors.purple : Colors.grey.shade600,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
