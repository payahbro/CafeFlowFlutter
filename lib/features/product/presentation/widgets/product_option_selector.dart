import 'package:flutter/material.dart';

class ProductOptionSelector extends StatelessWidget {
  const ProductOptionSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF26211F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isActive = option == selected;
            return ChoiceChip(
              label: Text(option.replaceAll('_', ' ')),
              selected: isActive,
              onSelected: (_) => onChanged(option),
              selectedColor: const Color(0x1AD88A16),
              labelStyle: TextStyle(
                color: isActive ? const Color(0xFFD88A16) : const Color(0xFF7B716E),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isActive ? const Color(0xFFD88A16) : const Color(0xFFCAC3C0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

