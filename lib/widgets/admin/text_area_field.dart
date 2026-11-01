import 'package:flutter/material.dart';

/// Champ de texte sur plusieurs lignes (description, avantages).
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.isRequired = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
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
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}