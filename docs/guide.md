# picpic coding reference

这是一个用于给 AI assistant 提供 UI reference 以及阐述页面功能的 reference，旨在让 AI 更好理解每一个页面的样式和功能。

## Pack
- 路径：`assets/pages/pack`
| 页面名称 | UI 参考图路径 | API endpoint | 交互说明 ｜
| --- | --- | --- | --- ｜
| 我的套组列表 | `Packs.png` | `GET /api/v1/pack` | 底部 nav 当前选中 `套组`，右上角搜索图标跳转到搜索页，右下角 `+` 打开新建套组 bottom sheet ｜
| 搜索套组初始态 | `PackSearchInitial.png` | `GET /api/v1/pack` | 进入搜索页后的默认状态，展示全部套组 ｜
| 搜索套组结果态 | `PackSearch.png` | `GET /api/v1/pack?q={keyword}` | 输入关键词后实时展示搜索结果 ｜
| 搜索套组空态 | `PackSearchEmpty.png` | `GET /api/v1/pack?q={keyword}` | 无结果时展示空态文案和插画 ｜
| 套组详情 | `PackInfo.png` | `GET /api/v1/pack/:pack_id` | 点击套组 tile 跳转详情页，展示套组信息和物品列表 ｜
| 更多套组操作 | `PackEditMore.png` | `GET /api/v1/pack/:pack_id` | 详情页右上角 `...` 打开更多操作面板 ｜
| 编辑套组名 | `PackEditName.png` | `PUT /api/v1/pack/:pack_id` | 在更多操作中进入编辑名称弹窗，仅更新套组名 ｜

## Checklist
- 路径：`assets/pages/checklist`
| 页面名称 | UI 参考图路径 | API endpoint | 交互说明 ｜
| --- | --- | --- | --- ｜
| 我的清单空态 | `ChecklistBlank.png` | `GET /api/v1/checklist` | 进入底部导航 `清单` tab 后展示，顶部使用和 pack 一致的渐变 header，右下角 `+` 打开“新增清单基础信息” bottom sheet ｜
| 我的清单列表 | `Checklists.png` | `GET /api/v1/checklist` | 点击会跳转到清单详情页，tile 图片使用 `assets/checklist_tile_deco.png`，右上角搜索图标预留搜索入口 ｜
| 新增清单基础信息 | `AddChecklistMeta.png` | `POST /api/v1/checklist` | 通过 `showModalBottomSheet` 弹出；填写 `name`、`target_date`、`description`；点击 `下一步` 仅保存草稿并进入导入物品页，不立即创建 checklist ｜
| 新增清单-从套组导入 | `AddChecklistPack.png` | `GET /api/v1/pack` + `POST /api/v1/checklist` | 顶部 segmented control 切到 `从套组导入`；支持搜索 pack，选中 pack 后将 pack 内 item 展开成 checklist line items ｜
| 新增清单-从物品导入 | `AddChecklistItem.png` | `GET /api/v1/item` + `POST /api/v1/checklist` | 顶部 segmented control 切到 `从物品导入`；支持搜索 item，选中 item 后以 `reference_type=item`、`reference_id=item_id` 组装请求体 ｜
| 清单详情 | `ChecklistDetail.png` | `GET /api/v1/checklist/:checklist_id` | 创建成功后跳转到详情页并显示 2s 黑色成功 banner；底部列表根据 `items.status` 展示 `checked / unchecked`，用户切换状态调用 `PATCH /api/v1/checklist/:checklist_id/items/:line_item_id/status` ｜

## Me
- 路径：`assets/me`
| 页面名称 | UI 参考图路径 | API endpoint | 交互说明 ｜
| --- | --- | --- | --- ｜
| 个人中心 | `Me.png` | `GET /api/v1/me` | 展示的数据都是由api query出来的，右上角的设置图标跳转到设置页面 ｜
| 设置 | `MeSetting.png` | -- | 个人资料跳转到个人资料页 ｜
| 个人资料 | `MeProfile.png` | `GET /api/v1/me` + `PUT /api/v1/me/profile` | 点击头像可以从相册选择也可以手机拍照，会有一个正方形的裁剪框，点击保存修改触发edit profile ｜

## Login
- 路径：`assets/login`
| 页面名称 | UI 参考图路径 | API endpoint | 交互说明 ｜ 插图 ｜
| --- | --- | --- | --- ｜
| 登录| `UserLogin.png` | `POST /api/v1/auth/phone/code` + `POST /api/v1/auth/phone/login`| 目前只支持+86的大陆手机号，点击`获取验证码`会变灰并倒计时60s｜login_cover.png
