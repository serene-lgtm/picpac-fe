import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../checklists/data/checklist_repository.dart';
import '../../../checklists/presentation/pages/checklists_page.dart';
import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../items/presentation/widgets/item_detail_result.dart';
import '../../../items/presentation/widgets/item_detail_sheet.dart';
import '../../../me/data/me_repository.dart';
import '../../../me/presentation/pages/me_page.dart';
import '../../data/pack.dart';
import '../../data/pack_repository.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/module_floating_add_button.dart';
import '../../../../shared/widgets/module_top_bar.dart';
import '../../../../shared/widgets/search_empty_state.dart';
import '../../../../shared/widgets/search_pill_field.dart';

part 'packs_page_part.dart';
part 'pack_search_page_part.dart';
part 'pack_item_picker_page_part.dart';
part 'pack_detail_page_part.dart';
part '../widgets/pack_name_sheets.dart';
part '../widgets/pack_edit_name_sheet.dart';
part '../widgets/pack_list_widgets.dart';
part '../widgets/pack_selectable_item_row.dart';
part '../widgets/pack_shared_widgets.dart';

const _packGradientColors = [Color(0xFF48B3AF), Color(0xFFA7E399)];
const _packNameMaxLength = 20;
const _packCardColor = Color(0xDDF0FFF9);
