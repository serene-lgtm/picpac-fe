# picpic coding reference

这是一个用于给 AI assistant 提供 UI reference 以及阐述页面功能的 reference，旨在让 AI 更好理解每一个页面的样式和功能。

| 页面名称 | UI 参考图路径 | API endpoint | 交互说明 ｜
| --- | --- | --- | --- ｜
| 我的套组列表 | `assets/pages/Packs.png` | `GET /api/v1/pack` |
| 搜索套组初始态 | `assets/pages/PackSearchInitial.png` | `GET /api/v1/pack` |
| 搜索套组结果态 | `assets/pages/PackSearch.png` | `GET /api/v1/pack?q={keyword}` |
| 搜索套组空态 | `assets/pages/PackSearchEmpty.png` | `GET /api/v1/pack?q={keyword}` |
| 套组详情 | `assets/pages/PackInfo.png` | `GET /api/v1/pack/:pack_id` |
| 更多套组操作 | `assets/pages/PackEditMore.png` | `GET /api/v1/pack/:pack_id` |
| 编辑套组名 | `assets/pages/PackEditName.png` | `PUT /api/v1/pack/:pack_id` |
| 我的清单空态 | `assets/pages/checklist/ChecklistBlank.png` | `GET /api/v1/checklist` |
| 我的清单列表 | `assets/pages/checklist/Checklists.png` | `GET /api/v1/checklist` | 点击会跳转到清单详情页，tile的图片用checklist_tile_deco.png ｜
| 新增清单基础信息 | `assets/pages/checklist/AddChecklistMeta.png` | `POST /api/v1/checklist` |
| 新增清单-从套组导入 | `assets/pages/checklist/AddChecklistPack.png` | `GET /api/v1/pack` + `POST /api/v1/checklist` |
| 新增清单-从物品导入 | `assets/pages/checklist/AddChecklistItem.png` | `GET /api/v1/item` + `POST /api/v1/checklist` |
| 清单详情 | `assets/pages/checklist/ChecklistDetail.png` | `GET /api/v1/checklist/:checklist_id` | 创建清单成功跳转到详情页，底部banner显示2s消失；物品是否被check上取决于items的status字段（checked / unchecked），user可以check / uncheck对应PATCH /api/v1/checklist/:checklist_id/items/:line_item_id/status｜

## Checklist Implementation Notes

### 数据层

- 新增 `Checklist` model，对应 `docs/api.md` 中 checklist 响应结构：
  - `id`
  - `userId`
  - `name`
  - `description`
  - `targetDate`
  - `items`
  - `status`
- 新增 `ChecklistLineItem` model：
  - `id`
  - `referenceType`: `item` 或 `snapshot`
  - `referenceId`
  - `snapshot`
  - `status`: 初始为 `unchecked`
- 新增 `ChecklistRepository`：
  - `listChecklists({String? userId, String? q})` -> `GET /api/v1/checklist`
  - `getChecklist(String checklistId)` -> `GET /api/v1/checklist/:checklist_id`
  - `createChecklist(...)` -> `POST /api/v1/checklist`
  - `updateChecklist(...)` -> `PUT /api/v1/checklist/:checklist_id`
  - `addLineItems(...)` -> `POST /api/v1/checklist/:checklist_id/items`
  - `removeLineItems(...)` -> `DELETE /api/v1/checklist/:checklist_id/items`
  - `deleteChecklist(String checklistId)` -> `DELETE /api/v1/checklist/:checklist_id`

### 我的清单空态

- UI 参考：`assets/pages/checklist/ChecklistBlank.png`
- 进入底部导航 `清单` tab 后展示。
- 顶部使用和 pack 页面一致的渐变 header：
  - 标题：`我的清单`
  - 右侧搜索 icon
- 空态文案：`是时候罗列一些清单咯`
- 中间使用现有空态插画风格。
- 右下角 floating `+` 按钮，点击打开“新增清单基础信息” bottom sheet。
- 底部 nav 当前选中 `清单`。

### 新增清单基础信息

- UI 参考：`assets/pages/checklist/AddChecklistMeta.png`
- 通过 `showModalBottomSheet` 从清单页底部弹出，背景页面变暗。
- 表单字段：
  - `name`: 必填，对应 API `name`
  - `target_date`: 必填，API 要求 `YYYY-MM-DD`；UI 文案可显示 `日期（选填）`，但提交 API 前必须提供合法日期，未选择时需要阻止下一步或补默认日期。
  - `description`: 可选，对应 API `description`
- 点击 `下一步` 后进入“导入物品”页面，不立即创建 checklist。
- 本步骤保存 metadata 到内存状态，下一步选择 item/pack 后一起提交 `POST /api/v1/checklist`。

### 新增清单-导入物品

- UI 参考：
  - `assets/pages/checklist/AddChecklistItem.png`
  - `assets/pages/checklist/AddChecklistPack.png`
- 页面标题：`导入物品`
- 顶部左侧 back 返回基础信息步骤。
- 顶部使用 segmented control：
  - `从物品导入`
  - `从套组导入`
- `从物品导入`：
  - 搜索框接 `GET /api/v1/item?q={keyword}`
  - 空搜索接 `GET /api/v1/item`
  - 列表展示 item name、description/tag 信息。
  - 点击 item 切换选中状态。
  - 选中后提交的 line item：
    ```json
    {
      "reference_type": "item",
      "reference_id": "{item_id}"
    }
    ```
- `从套组导入`：
  - 搜索框接 `GET /api/v1/pack?q={keyword}`
  - 空搜索接 `GET /api/v1/pack`
  - 列表展示 pack name、description、items count。
  - 点击 pack 后应把该 pack 内 item 展开为 checklist line items。
  - 如果当前前端只有 pack item id，而没有 item 详情，可以直接用 item id 构造 `reference_type=item` line item。
- 底部固定显示：
  - `已选 N 项（X 件物品，Y 个套组）`
  - 主按钮：`添加并创建清单`
- 点击主按钮调用 `POST /api/v1/checklist`：
  ```json
  {
    "name": "...",
    "description": "...",
    "target_date": "YYYY-MM-DD",
    "items": [
      {
        "reference_type": "item",
        "reference_id": "..."
      }
    ]
  }
  ```
- 创建成功后跳转 `ChecklistDetail`，并显示黑色成功 banner。

### 清单详情

- UI 参考：`assets/pages/checklist/ChecklistDetail.png`
- 进入详情页调用 `GET /api/v1/checklist/:checklist_id`。
- 顶部：
  - 左侧 back 返回上一页。
  - 右侧 `...` 预留更多操作。
- 内容：
  - 标题显示 checklist `name`
  - 日期显示 `target_date`
  - 完成统计显示：`已完成 checked_count/total_count 项`
  - section label：`装备清单`
- line item 展示：
  - `reference_type=item`：优先通过 `reference_id` 匹配本地/接口 item 数据，显示 item name、description、图片。
  - `reference_type=snapshot`：显示 `snapshot.name`，无图片时使用占位。
  - `status=checked` 时显示选中 icon，并使用较弱文字颜色。
  - `status=unchecked` 时显示未选状态。
- 当前 `docs/api.md` 只提供新增/移除 line item，没有提供 toggle checked 状态接口；因此勾选状态如果需要可点击，需要后端补充 line item status update API。当前实现可先只读展示。

### 修改清单 Metadata

- API：`PUT /api/v1/checklist/:checklist_id`
- 只允许更新：
  - `name`
  - `description`
  - `target_date`
- 注意：`items` 不允许通过该接口更新。
- 如果要新增/移除清单条目，必须使用：
  - `POST /api/v1/checklist/:checklist_id/items`
  - `DELETE /api/v1/checklist/:checklist_id/items`
