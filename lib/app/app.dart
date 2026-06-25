import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../features/checklists/data/checklist_repository.dart';
import '../features/items/data/item_repository.dart';
import '../features/items/presentation/pages/items_page.dart';
import '../features/packs/data/pack_repository.dart';
import 'theme.dart';

class PicpacApp extends StatelessWidget {
  PicpacApp({
    super.key,
    ChecklistRepository? checklistRepository,
    ItemRepository? itemRepository,
    PackRepository? packRepository,
  }) : checklistRepository =
           checklistRepository ??
           ApiChecklistRepository(ApiClient(baseUrl: ApiConfig.baseUrl)),
       itemRepository =
           itemRepository ??
           ApiItemRepository(ApiClient(baseUrl: ApiConfig.baseUrl)),
       packRepository =
           packRepository ??
           ApiPackRepository(ApiClient(baseUrl: ApiConfig.baseUrl));

  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '物品',
      debugShowCheckedModeBanner: false,
      theme: PicpacTheme.light(),
      home: ItemsPage(
        repository: itemRepository,
        packRepository: packRepository,
        checklistRepository: checklistRepository,
      ),
    );
  }
}
