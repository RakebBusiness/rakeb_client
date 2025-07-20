import 'package:flutter/material.dart';

class CodeInputField extends StatelessWidget {
  final void Function(String) onSubmit;
  const CodeInputField({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 5,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.green),
            onPressed: () => onSubmit(controller.text),
          ),
        ],
      ),
    );
  }
}
