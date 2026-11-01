import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Liste déroulante avec le même style que CustomTextField.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.icon,
    this.hint,
    this.validator,
    this.isRequired = true,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final IconData? icon;
  final String? hint;
  final String? Function(T?)? validator;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i,
                    child: Text(itemLabel(i), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null ? null : Icon(icon),
          ),
        ),
      ],
    );
  }
}