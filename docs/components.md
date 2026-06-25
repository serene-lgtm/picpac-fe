# 复用组件报告

本文档记录当前前端代码中已经复用或承担复用职责的 UI 组件、页面内组件和少量界面基础设施。`_` 开头的组件是 Dart 私有类，目前只能在所在文件内复用；如果后续多个页面需要共用，建议再移动到 `lib/shared/widgets` 或对应 feature 的 `widgets` 目录。

## 全局共享组件

| 组件 | 代表什么 | 形状 / 视觉 | 代码位置 | 当前使用场景 |
| --- | --- | --- | --- | --- |
| `BottomNav` | App 底部四个主入口：清单、套组、物品、我的 | 半透明白色圆角胶囊，高 64，圆角 32，带阴影；每个 tab 是 SVG 图标 + 文字 | [`lib/shared/widgets/bottom_nav.dart:6`](../lib/shared/widgets/bottom_nav.dart#L6) | 物品列表、套组列表、清单列表等主 tab 页面 |
| `BottomTab` | 底部导航 tab 枚举 | 非视觉组件，定义 tab 名称和 icon asset 映射 | [`lib/shared/widgets/bottom_nav.dart:4`](../lib/shared/widgets/bottom_nav.dart#L4) | `BottomNav` 和各主页面的 tab 切换逻辑 |
| `TopControls` | 列表页顶部搜索入口和添加按钮 | 左侧白色圆角搜索胶囊，高 56，圆角 28；右侧白色圆形 `+` 按钮 | [`lib/shared/widgets/top_controls.dart:3`](../lib/shared/widgets/top_controls.dart#L3) | 物品列表页顶部控制区 |
| `noAnimationRoute` | 无转场页面路由 | 非视觉组件；页面切换时没有左右滑动方向感 | [`lib/shared/navigation/no_animation_route.dart:3`](../lib/shared/navigation/no_animation_route.dart#L3) | bottom nav 切换、部分详情页跳转 |
| `PicpacTheme.light` | App 全局主题 | Material 3；主色 `#48B3AF`，浅绿色辅助色，默认输入框圆角 18 | [`lib/app/theme.dart:6`](../lib/app/theme.dart#L6) | 全 App 的颜色、字体、输入框默认样式 |

## 物品模块组件

| 组件 | 代表什么 | 形状 / 视觉 | 代码位置 | 当前使用场景 |
| --- | --- | --- | --- | --- |
| `ItemsPage` | 我的物品主页面 | 渐变背景、顶部标题、搜索/添加控制、网格或空态、底部导航 | [`lib/features/items/presentation/pages/items_page.dart:25`](../lib/features/items/presentation/pages/items_page.dart#L25) | bottom nav 的“物品”页 |
| `AddItemSheet` | 添加物品表单 bottom sheet | 白色圆角上边 sheet，包含输入项、选择项和提交按钮 | [`lib/features/items/presentation/widgets/add_item_sheet.dart:8`](../lib/features/items/presentation/widgets/add_item_sheet.dart#L8) | 物品列表点击添加时弹出 |
| `_FieldLabel` | 添加物品 sheet 内的字段标签 | 文本 label，可带必填星号 | [`lib/features/items/presentation/widgets/add_item_sheet.dart:211`](../lib/features/items/presentation/widgets/add_item_sheet.dart#L211) | `AddItemSheet` 表单字段 |
| `_TreasureBackground` | 物品页底部插画背景 | SVG 插画定位在页面下方，可通过 `Positioned` 调整位置 | [`lib/features/items/presentation/pages/items_page.dart:246`](../lib/features/items/presentation/pages/items_page.dart#L246) | 物品空态 / 列表背景 |
| `ItemDetailPage` | 物品详情页 | 渐变顶部 + 白色详情面板，展示物品图片、名称、描述等 | [`lib/features/items/presentation/pages/items_page.dart:259`](../lib/features/items/presentation/pages/items_page.dart#L259) | 点击物品卡片后的详情 |
| `_ItemDetailHeader` | 物品详情页顶部栏 | 左侧返回按钮，中间标题 | [`lib/features/items/presentation/pages/items_page.dart:387`](../lib/features/items/presentation/pages/items_page.dart#L387) | `ItemDetailPage` |
| `_ItemDetailPanel` | 物品详情信息容器 | 白色面板，承载图片和详情行 | [`lib/features/items/presentation/pages/items_page.dart:431`](../lib/features/items/presentation/pages/items_page.dart#L431) | `ItemDetailPage` |
| `_ItemDetailRow` | 物品详情信息行 | 左侧 icon，右侧 label/value 纵向文本 | [`lib/features/items/presentation/pages/items_page.dart:480`](../lib/features/items/presentation/pages/items_page.dart#L480) | `ItemDetailPage` 多个信息字段 |
| `_ItemsBlank` | 物品空态 | 居中文案 + 背景插画 + bottom nav + 添加入口 | [`lib/features/items/presentation/pages/items_page.dart:540`](../lib/features/items/presentation/pages/items_page.dart#L540) | 没有物品时 |
| `_ItemsGrid` | 物品网格 | 4 列网格，固定间距，承载 `_ItemIcon` | [`lib/features/items/presentation/pages/items_page.dart:574`](../lib/features/items/presentation/pages/items_page.dart#L574) | 有物品时 |
| `_ItemIcon` | 单个物品入口 | 绿色圆角方块图标区域 + 下方物品名称 | [`lib/features/items/presentation/pages/items_page.dart:635`](../lib/features/items/presentation/pages/items_page.dart#L635) | 物品网格 cell |
| `_ItemImageFrame` | 物品图片/占位图框 | 圆角矩形，图片裁剪或默认手机 icon 占位 | [`lib/features/items/presentation/pages/items_page.dart:679`](../lib/features/items/presentation/pages/items_page.dart#L679) | 物品网格、物品详情 |
| `_ErrorState` | 物品模块错误态 | 居中文案 + 重试按钮 | [`lib/features/items/presentation/pages/items_page.dart:734`](../lib/features/items/presentation/pages/items_page.dart#L734) | 物品列表加载失败 |
| `_AddItemSuccessBanner` | 添加物品成功提示 | 底部黑色小横幅，圆角胶囊，左侧 check icon + 成功文案 | [`lib/features/items/presentation/pages/items_page.dart:768`](../lib/features/items/presentation/pages/items_page.dart#L768) | 添加物品成功后 |

## 套组模块组件

| 组件 | 代表什么 | 形状 / 视觉 | 代码位置 | 当前使用场景 |
| --- | --- | --- | --- | --- |
| `PacksPage` | 我的套组主页面 | 顶部渐变栏、搜索入口、空态或列表、悬浮添加按钮、bottom nav | [`lib/features/packs/presentation/pages/create_pack_page.dart:18`](../lib/features/packs/presentation/pages/create_pack_page.dart#L18) | bottom nav 的“套组”页 |
| `CreatePackPage` | 创建套组入口页面 | 包装创建流程，主要触发命名 sheet | [`lib/features/packs/presentation/pages/create_pack_page.dart:184`](../lib/features/packs/presentation/pages/create_pack_page.dart#L184) | 从套组添加入口进入 |
| `_PackEmptyState` | 套组空态 | 居中文案 + 打包插画 | [`lib/features/packs/presentation/pages/create_pack_page.dart:239`](../lib/features/packs/presentation/pages/create_pack_page.dart#L239) | 没有套组时 |
| `_PackList` | 套组列表 | 可刷新列表，承载 `_PackCard` | [`lib/features/packs/presentation/pages/create_pack_page.dart:277`](../lib/features/packs/presentation/pages/create_pack_page.dart#L277) | 有套组时 |
| `PackSearchPage` | 套组搜索页 | 顶部搜索框 + 搜索结果列表 | [`lib/features/packs/presentation/pages/create_pack_page.dart:310`](../lib/features/packs/presentation/pages/create_pack_page.dart#L310) | 套组搜索 |
| `_PackLoadError` | 套组加载错误态 | 文案 + 重试按钮 | [`lib/features/packs/presentation/pages/create_pack_page.dart:468`](../lib/features/packs/presentation/pages/create_pack_page.dart#L468) | 套组列表/搜索失败 |
| `_PackSearchInput` | 套组搜索输入框 | 圆角搜索框，带搜索 icon 和清除按钮 | [`lib/features/packs/presentation/pages/create_pack_page.dart:496`](../lib/features/packs/presentation/pages/create_pack_page.dart#L496) | 套组搜索页 |
| `_PackCard` | 套组列表卡片 | 绿色渐变圆角卡片，展示套组名和箱子插画 | [`lib/features/packs/presentation/pages/create_pack_page.dart:545`](../lib/features/packs/presentation/pages/create_pack_page.dart#L545) | 套组列表和搜索结果 |
| `_PackBoxArt` | 套组卡片箱子插画容器 | 固定尺寸绘制区域 | [`lib/features/packs/presentation/pages/create_pack_page.dart:625`](../lib/features/packs/presentation/pages/create_pack_page.dart#L625) | `_PackCard` |
| `_PackBoxPainter` | 套组卡片箱子自绘图形 | CustomPainter 绘制红色箱子图形 | [`lib/features/packs/presentation/pages/create_pack_page.dart:634`](../lib/features/packs/presentation/pages/create_pack_page.dart#L634) | `_PackBoxArt` |
| `_CreatePackNameSheet` | 创建套组第一步命名 sheet | 页面变暗后从底部弹出的白色圆角 sheet，包含拖拽条、关闭按钮、输入框和下一步按钮 | [`lib/features/packs/presentation/pages/create_pack_page.dart:658`](../lib/features/packs/presentation/pages/create_pack_page.dart#L658) | 点击套组页 floating button 后 |
| `PackItemPickerPage` | 套组导入/添加物品选择页 | 渐变顶栏、搜索框、已选数量、可选择物品行 | [`lib/features/packs/presentation/pages/create_pack_page.dart:810`](../lib/features/packs/presentation/pages/create_pack_page.dart#L810) | 创建套组第二步、套组详情添加物品 |
| `_PackItemsEditResult` | 套组物品编辑结果 | 非视觉数据对象，携带编辑后的物品和操作结果 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1024`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1024) | 添加/移除套组物品后的页面回传 |
| `_PackRemoveItemsPage` | 套组移除物品页 | 顶部“移除”操作，列表项初始未选，勾选后执行移除 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1036`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1036) | 套组详情点击移除 |
| `_PickerTopBar` | 选择页顶部栏 | 渐变背景；左侧返回，中间标题，右侧 check 或文字操作 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1160`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1160) | 选择物品、移除物品页 |
| `_PackSearchField` | 物品选择搜索框 | 白底圆角边框输入框，左侧搜索 icon | [`lib/features/packs/presentation/pages/create_pack_page.dart:1248`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1248) | `PackItemPickerPage` |
| `_SelectableItemRow` | 可选物品行 | 浅灰圆角矩形行；右侧圆形 check / 空心圆，支持 disabled | [`lib/features/packs/presentation/pages/create_pack_page.dart:1289`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1289) | 添加物品、移除物品、创建套组导入物品 |
| `_PickerError` | 选择页错误态 | 居中文案 + 重试按钮 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1375`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1375) | 物品选择列表加载失败 |
| `PackDetailPage` | 套组详情页 | 顶部渐变栏、套组名、套组内物品列表、底部添加/移除操作 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1400`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1400) | 点击套组后 |
| `_PackTopBar` | 套组模块顶部栏 | 渐变矩形顶栏，可配置左侧返回和右侧搜索/更多操作 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1702`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1702) | 套组列表、搜索、详情 |
| `_PackDetailBottomActions` | 套组详情底部操作 | 底部两个文字按钮：添加、移除 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1769`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1769) | `PackDetailPage` |
| `_PackMoreActionsSheet` | 套组更多操作 sheet | 白色底部弹层，提供编辑名称等操作 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1822`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1822) | 套组详情右上角更多 |
| `_EditPackNameSheet` | 编辑套组名 sheet | 白色底部圆角 sheet，输入新名称并提交 | [`lib/features/packs/presentation/pages/create_pack_page.dart:1888`](../lib/features/packs/presentation/pages/create_pack_page.dart#L1888) | 更多操作中的编辑套组名 |
| `_PackDetailItemCard` | 套组详情物品卡片 | 浅灰圆角矩形，展示 item name 和 description，可点击 | [`lib/features/packs/presentation/pages/create_pack_page.dart:2051`](../lib/features/packs/presentation/pages/create_pack_page.dart#L2051) | `PackDetailPage` |
| `_PackItemDetailPage` | 套组流程内物品详情 | 简化详情页，支持返回 | [`lib/features/packs/presentation/pages/create_pack_page.dart:2106`](../lib/features/packs/presentation/pages/create_pack_page.dart#L2106) | 套组详情点击物品 |
| `_PackSuccessBanner` | 套组成功提示 | 底部黑色圆角小横幅，check icon + 成功文案 | [`lib/features/packs/presentation/pages/create_pack_page.dart:2158`](../lib/features/packs/presentation/pages/create_pack_page.dart#L2158) | 创建/添加/移除套组物品成功 |

## 清单模块组件

| 组件 | 代表什么 | 形状 / 视觉 | 代码位置 | 当前使用场景 |
| --- | --- | --- | --- | --- |
| `ChecklistsPage` | 我的清单主页面 | 顶部渐变栏、空态或列表、floating button、bottom nav | [`lib/features/checklists/presentation/pages/checklists_page.dart:19`](../lib/features/checklists/presentation/pages/checklists_page.dart#L19) | bottom nav 的“清单”页 |
| `_ChecklistTopBar` | 清单模块顶部栏 | 渐变矩形顶栏，可配置返回、标题、右侧操作 | [`lib/features/checklists/presentation/pages/checklists_page.dart:182`](../lib/features/checklists/presentation/pages/checklists_page.dart#L182) | 清单列表、导入、详情页 |
| `_ChecklistEmptyState` | 清单空态 | 居中文字和插画 | [`lib/features/checklists/presentation/pages/checklists_page.dart:250`](../lib/features/checklists/presentation/pages/checklists_page.dart#L250) | 没有清单时 |
| `_ChecklistList` | 清单列表 | 可刷新列表，承载 `_ChecklistCard` | [`lib/features/checklists/presentation/pages/checklists_page.dart:286`](../lib/features/checklists/presentation/pages/checklists_page.dart#L286) | 有清单时 |
| `_ChecklistCard` | 清单卡片 | 浅色圆角卡片，展示清单名称、日期等信息 | [`lib/features/checklists/presentation/pages/checklists_page.dart:320`](../lib/features/checklists/presentation/pages/checklists_page.dart#L320) | 清单列表 |
| `_ChecklistDraft` | 创建清单草稿 | 非视觉数据对象，临时保存名称、时间、导入项等 | [`lib/features/checklists/presentation/pages/checklists_page.dart:367`](../lib/features/checklists/presentation/pages/checklists_page.dart#L367) | 创建清单流程 |
| `_ChecklistMetaSheet` | 创建清单基础信息 sheet | 底部白色圆角 sheet，填写清单名、备注、日期等 | [`lib/features/checklists/presentation/pages/checklists_page.dart:379`](../lib/features/checklists/presentation/pages/checklists_page.dart#L379) | 清单创建第一步 |
| `_ChecklistImportPage` | 清单导入页 | 顶部栏、tab、搜索框、可选列表 | [`lib/features/checklists/presentation/pages/checklists_page.dart:546`](../lib/features/checklists/presentation/pages/checklists_page.dart#L546) | 导入物品或套组到清单 |
| `_ChecklistImportMode` | 清单导入模式 | 非视觉枚举，区分 item / pack | [`lib/features/checklists/presentation/pages/checklists_page.dart:563`](../lib/features/checklists/presentation/pages/checklists_page.dart#L563) | `_ChecklistImportPage` |
| `ChecklistDetailPage` | 清单详情页 | 顶部栏、清单信息、已导入物品/套组内容 | [`lib/features/checklists/presentation/pages/checklists_page.dart:843`](../lib/features/checklists/presentation/pages/checklists_page.dart#L843) | 点击清单后 |
| `_ChecklistImportTabs` | 清单导入 tab 控件 | 分段切换按钮，切换物品/套组导入 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1080`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1080) | `_ChecklistImportPage` |
| `_ChecklistSearchField` | 清单导入搜索框 | 浅灰圆角搜索输入框，支持 q 查询 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1136`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1136) | 导入物品/套组搜索 |
| `_ImportItemRow` | 清单导入选择行 | 浅灰圆角矩形行；右侧圆形 check / 空心圆 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1220`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1220) | 清单导入物品和套组 |
| `_SheetLabel` | sheet 表单标签 | 文本 label，可显示必填星号 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1305`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1305) | `_ChecklistMetaSheet` |
| `_SheetTextField` | sheet 文本输入框 | 浅灰填充圆角输入框 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1333`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1333) | `_ChecklistMetaSheet` |
| `_SheetTapField` | sheet 可点击字段 | 浅灰圆角伪输入框，右侧可带 icon | [`lib/features/checklists/presentation/pages/checklists_page.dart:1373`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1373) | 日期等非键盘输入字段 |
| `_ChecklistSuccessBanner` | 清单成功提示 | 底部黑色圆角小横幅，check icon + 成功文案 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1413`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1413) | 清单创建成功 |
| `_ChecklistError` | 清单错误态 | 居中文案 + 重试按钮 | [`lib/features/checklists/presentation/pages/checklists_page.dart:1450`](../lib/features/checklists/presentation/pages/checklists_page.dart#L1450) | 清单列表/导入加载失败 |

## 重复视觉模式

| 模式 | 代表什么 | 当前形状 | 主要代码位置 |
| --- | --- | --- | --- |
| 顶部渐变栏 | 当前页面标题和导航动作 | 从青绿色到浅绿色的顶部横条，标题居中，可放返回/搜索/更多 | `_PackTopBar`、`_ChecklistTopBar` |
| 底部成功 banner | 操作完成反馈 | 黑色或深灰圆角胶囊，居底显示，左侧 check icon | `_AddItemSuccessBanner`、`_PackSuccessBanner`、`_ChecklistSuccessBanner` |
| 选择列表行 | 从 item/pack 中选择多个对象 | 浅灰圆角行，左侧名称/描述，右侧圆形选中态 | `_SelectableItemRow`、`_ImportItemRow` |
| 表单 bottom sheet | 创建或编辑对象 | 页面遮罩变暗，白色圆角 sheet 从底部弹出，顶部拖拽条和关闭按钮 | `AddItemSheet`、`_CreatePackNameSheet`、`_EditPackNameSheet`、`_ChecklistMetaSheet` |
| 搜索框 | 通过 list API 的 `q` 参数筛选 | 圆角输入框，左侧搜索 icon，部分场景有清除按钮 | `TopControls`、`_PackSearchInput`、`_PackSearchField`、`_ChecklistSearchField` |

## 后续抽取建议

| 建议抽取组件 | 原因 | 可参考现有实现 |
| --- | --- | --- |
| `SuccessBanner` | 物品、套组、清单都有几乎一致的底部成功提示 | `_AddItemSuccessBanner`、`_PackSuccessBanner`、`_ChecklistSuccessBanner` |
| `GradientTopBar` | 套组和清单顶部栏结构接近 | `_PackTopBar`、`_ChecklistTopBar` |
| `SelectableListRow` | 套组选择物品和清单导入行视觉相近 | `_SelectableItemRow`、`_ImportItemRow` |
| `RoundedSearchField` | 多处搜索框形状相似，只是颜色、边框和回调略有差异 | `_PackSearchInput`、`_PackSearchField`、`_ChecklistSearchField` |
| `FormBottomSheetScaffold` | 多个创建/编辑 sheet 都有相同遮罩、圆角、拖拽条和按钮结构 | `AddItemSheet`、`_CreatePackNameSheet`、`_ChecklistMetaSheet` |
