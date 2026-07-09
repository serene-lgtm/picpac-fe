import 'package:flutter/material.dart';

class TopControls extends StatelessWidget {
  const TopControls({
    super.key,
    required this.onAdd,
    this.onSearch,
    this.searchLabel = '搜索物品',
  });

  final VoidCallback onAdd;
  final VoidCallback? onSearch;
  final String searchLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.search_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      searchLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox.square(
            dimension: 56,
            child: FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                elevation: 10,
                shadowColor: const Color(0x44000000),
              ),
              child: const Icon(Icons.add_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
