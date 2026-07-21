import 'package:flutter/material.dart';

import '../../data/checklist.dart';
import 'checklist_common_widgets.dart';
import 'checklist_theme.dart';

class ChecklistEmptyState extends StatelessWidget {
  const ChecklistEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 76, 30, 150),
      children: const [
        Text(
          '是时候罗列一些清单咯',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF258B85),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 26),
        ChecklistEmptyIllustration(),
      ],
    );
  }
}

class ChecklistList extends StatelessWidget {
  const ChecklistList({
    super.key,
    required this.checklists,
    required this.onRefresh,
    required this.onTap,
  });

  final List<Checklist> checklists;
  final Future<void> Function() onRefresh;
  final ValueChanged<Checklist> onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 156),
        itemCount: checklists.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final checklist = checklists[index];
          return ChecklistCard(
            checklist: checklist,
            onTap: () => onTap(checklist),
          );
        },
      ),
    );
  }
}

class ChecklistCard extends StatelessWidget {
  const ChecklistCard({
    super.key,
    required this.checklist,
    required this.onTap,
  });

  final Checklist checklist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = checklist.items.length;
    final checked = checklist.items.where((item) => item.checked).length;
    final progress = total == 0 ? 0.0 : checked / total;
    return Material(
      color: checklistCardColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 126,
          child: Row(
            children: [
              const SizedBox(width: 18),
              Image.asset(
                checklistCoverAsset,
                width: 74,
                height: 74,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      checklistDisplayDate(checklist.targetDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5F7372),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '已完成 $checked/$total 项',
                      style: const TextStyle(
                        color: Color(0xFF5F7372),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ChecklistProgressCircle(progress: progress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChecklistProgressCircle extends StatelessWidget {
  const ChecklistProgressCircle({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    if (value >= 1.0) {
      return const CircleAvatar(
        radius: 15,
        backgroundColor: checklistPrimary,
        child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
      );
    }
    return SizedBox.square(
      dimension: 34,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.65),
        color: checklistPrimary,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

class ChecklistErrorView extends StatelessWidget {
  const ChecklistErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
