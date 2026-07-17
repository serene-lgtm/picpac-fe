import 'package:flutter/material.dart';

class SearchPillField extends StatelessWidget {
  const SearchPillField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.hintText = '请输入关键词',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final bool autofocus;
  final bool enabled;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller?.text.isNotEmpty == true;
    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFC4C7CC),
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.cancel_rounded),
                  color: const Color(0xFFC4C7CC),
                  iconSize: 18,
                )
              : null,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFC4C7CC), fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
