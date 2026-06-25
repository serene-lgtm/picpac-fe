# Agent Guidelines

本文件用于约束本目录下的开发代理行为。项目目标是构建 picpac 手机 App 前端，技术栈以 Flutter 为主；后端预期为 Go + Gin + MongoDB。

## 项目定位

- 当前仓库优先作为 Flutter 移动端前端项目使用。
- 后端服务由 Go + Gin + MongoDB 提供，前端通过 RESTful HTTP API 与后端交互。
- 不在前端项目中直接实现后端业务逻辑、数据库访问或 MongoDB schema 管理。
- 产品领域、业务概念和 MVP 范围必须以 `docs/design.md` 为准。
- 涉及接口字段、endpoint、状态码、分页、鉴权、错误格式时，必须严格遵循 `docs/design.md` 的领域约束，并参考 `docs/api.md` 中已定义的 RESTful API 契约。

## 文档优先级

- `docs/design.md` 是产品和领域设计的最高优先级文档。涉及 Item、Item Snapshot、Pack、Checklist、Line Item 等概念时，必须先读取并遵循该文档。
- `docs/api.md` 是前后端 RESTful API 对接文档。涉及 API implementation、网络层、repository、model parsing、request/response DTO 时，必须读取并遵循该文档。
- 如果代码、注释或旧实现与 `docs/design.md` 或 `docs/api.md` 冲突，应先指出冲突，不要静默按旧实现继续扩展。
- 如果两个文档之间存在不一致，优先保持实现可隔离，并在最终说明中明确标出需要用户确认的差异。
- 每次前端实现涉及 API 层面改动时，都必须检查 `docs/design.md` 和 `docs/api.md`，不得凭记忆或猜测 endpoint、字段名、状态流转或业务关系。

## 技术栈约定

### Flutter

- 使用 Flutter stable 版本。
- 优先使用 Dart 空安全和强类型模型。
- UI 代码应遵循 Flutter 官方组件和 Material 设计习惯。
- 状态管理方案如项目尚未确定，优先采用简单、可维护的方案；避免过早引入复杂架构。
- 网络请求应集中封装，不要在页面组件中散落 raw HTTP 调用。
- 本地缓存、鉴权 token、环境变量等能力需要独立封装，避免与页面逻辑耦合。

### 后端协作

- 后端技术栈为 Go + Gin + MongoDB。
- 前后端使用 RESTful 风格对接。
- 前端不得假设接口已经存在；新增功能时需要同步定义或确认：
  - endpoint
  - HTTP method
  - request body/query/path params
  - response body
  - error response
  - auth requirement
  - pagination/filter/sort behavior, if any
- 已在 `docs/api.md` 中定义的接口必须按文档实现，不得擅自修改路径、方法、字段名或响应结构。
- MongoDB 的 `_id` 字段在前端模型中通常映射为 `id`，除非 API 契约另有约定。
- 时间字段优先使用 ISO 8601 字符串，并在 Dart 层统一解析。

## 推荐目录结构

Flutter 项目创建后，优先采用如下结构：

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    config/
    errors/
    network/
    storage/
    utils/
  features/
    <feature_name>/
      data/
        models/
        repositories/
        services/
      domain/
      presentation/
        pages/
        widgets/
  shared/
    widgets/
    constants/
    extensions/
test/
```

如果项目实际采用其他架构，应尊重现有结构，不为了匹配本文件而做无意义重构。

## 代码风格

- 优先保持改动小而清晰，避免混入无关重构。
- 命名应表达业务含义，不使用模糊缩写。
- 页面组件应保持可读；复杂 UI 拆分为局部 widget。
- 业务逻辑不要堆在 `build` 方法里。
- 重复的 API 错误处理、loading 状态、空状态和鉴权跳转应抽象复用。
- 不提交 secrets、token、私有 API key 或本地环境配置。

## 网络层约定

- 建议建立统一 API client，集中处理：
  - base URL
  - request headers
  - auth token injection
  - timeout
  - JSON encode/decode
  - error mapping
  - logging in debug mode
- API response model 应与后端契约保持一致。
- API 层实现必须将 RESTful endpoint、DTO/model、repository 和 UI 状态分离，避免页面直接拼接 URL 或解析裸 JSON。
- 对 `multipart/form-data`、图片上传、ObjectID、逻辑删除等已在 `docs/api.md` 中出现的行为，必须按文档实现。
- 对用户可见的错误信息应友好，对调试有用的错误细节应只在开发日志中暴露。

## 环境配置

- 区分开发、测试和生产环境。
- base URL 不应硬编码在页面组件中。
- 如使用 `.env` 或 build flavor，应提供示例文件，例如 `.env.example`，但不要提交真实密钥。

## UI/UX 约定

- App 首屏应直接呈现核心功能，不做无意义的营销页。
- 前端视觉风格应保持扁平、艺术化、色调统一。
- 颜色系统应有明确主色、辅助色、背景色和状态色，不使用杂乱的临时色值。
- 视觉表达应服务于个人物品管理和出行打包场景，保持轻量、清晰、可快速操作。
- 从 Figma 还原 UI 时，如果读取到的组件尺寸 `width` 或 `height` 不是 4 的倍数，可以自行 round 到最接近的 4 的倍数，以保持布局网格统一。
- 交互状态必须完整：loading、empty、error、success。
- 表单需要基本校验和清晰错误提示。
- 列表页应考虑分页、下拉刷新和网络失败重试。
- 移动端布局必须适配常见屏幕尺寸，避免固定宽高导致溢出。
- 当父级布局尺寸会随屏幕变化而子级使用固定宽高时，必须显式校验父子约束是否匹配；对于图标加文字、卡片网格等固定结构，优先使用 `mainAxisExtent`、`BoxConstraints`、`LayoutBuilder` 或断点策略明确尺寸关系，不要只依赖 `childAspectRatio` 等间接比例导致小屏 overflow。
- 同一个布局数值如果同时参与父级约束计算和子级实际渲染（例如 grid item 高度计算里的图文间距，以及子组件里的 `SizedBox` 间距），必须抽取为同一个命名常量或 token，避免后续只改一处造成约束和实际 UI 脱节。
- 新增页面或组件时，应优先复用统一 theme、spacing、typography 和 shared widgets，避免每个页面形成不同视觉语言。

## 测试与验证

改动完成后，根据影响范围选择合适验证：

- 运行 `flutter analyze` 检查静态问题。
- 运行 `flutter test` 验证单元测试和 widget 测试。
- 对网络层、model parsing、repository 逻辑添加聚焦测试。
- 对关键页面至少做基本手动验证。

如果因为依赖、环境或网络限制无法运行验证命令，需要在最终说明中明确说明。

## Git 与提交

- 不覆盖用户未提交的改动。
- 不执行破坏性 Git 操作，除非用户明确要求。
- 提交前检查工作区状态，确认只包含本任务相关改动。
- commit message 应简洁描述用户可见或工程上有意义的变化。

## Agent 工作方式

- 开始改动前先阅读相关文件，不凭空假设项目结构。
- 涉及产品概念、页面信息架构或 API implementation 时，必须先阅读 `docs/design.md`。
- 涉及网络请求、接口字段、HTTP 方法、错误处理或数据模型时，必须同时阅读 `docs/api.md`。
- 优先使用项目已有模式、依赖和工具链。
- 需要新增依赖时，应说明原因和替代方案，并尽量选择维护活跃、生态成熟的包。
- 遇到前后端契约不明确时，先给出合理假设，并在代码中隔离可变部分。
- 完成后说明改动内容、验证结果和剩余风险。

## 文档维护

- 如果 API 实现或后端契约发生变化，必须同步更新 `docs/api.md`。
- 如果产品概念、核心关系或 MVP 范围发生变化，必须同步更新 `docs/design.md`。
- 文档更新应保持面向前端实现可执行：包含明确字段、状态、关系和边界条件。
