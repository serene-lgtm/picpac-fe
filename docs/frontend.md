# picpac Frontend Guide

本项目是 picpac 手机端 Flutter 前端，只保留 Android 与 iOS 平台工程。

## 目录架构

```text
lib/
  main.dart
  app/
  core/
  features/
assets/
docs/
test/
android/
ios/
```

### `lib/main.dart`

Flutter 入口文件，只负责启动 `PicpacApp`。

### `lib/app/`

应用级配置。

- `app.dart`: 创建 `MaterialApp`，挂载首页和全局依赖
- `theme.dart`: 全局主题、颜色、输入框和 AppBar 样式

### `lib/core/`

跨业务复用的底层能力，不依赖具体功能模块。

- `config/`: 环境配置，例如 API base URL
- `network/`: HTTP client、multipart 请求、统一异常

### `lib/features/`

按业务功能拆分代码。当前已有：

- `items/`: 物品资产功能

`items/` 内部结构：

```text
items/
  data/
    item.dart
    item_repository.dart
  presentation/
    pages/
    widgets/
```

- `data/`: Item model 与 API repository
- `presentation/pages/`: 完整页面
- `presentation/widgets/`: 页面内组件

### `assets/`

本地 SVG 和图片资源。已在 `pubspec.yaml` 中注册整个 `assets/` 目录。

### `docs/`

项目文档。

- `design.md`: 产品和领域概念
- `api.md`: 后端 API 契约
- `frontend.md`: 当前文档

### `android/` / `ios/`

手机端平台工程。业务代码不写在这里，只有平台权限、打包配置、原生能力接入时才修改。

## 当前已接入接口

后端默认端口为 `9090`。

```text
GET  /api/v1/item
POST /api/v1/item
```

`GET /api/v1/item` 用于加载 Items 列表。返回空数组时显示空状态。

`POST /api/v1/item` 用于添加 Item。请求类型为 `multipart/form-data`，字段包括：

- `name`: 必填
- `description`: 可选
- `image`: 可选

## 启动方法

先安装依赖：

```bash
flutter pub get
```

查看可用设备：

```bash
flutter devices
```

### iOS 模拟器

```bash
flutter run -d ios --dart-define=PICPAC_API_BASE_URL=http://localhost:9090
```

### Android 模拟器

Android 模拟器访问电脑本机服务时不能用 `localhost`，需要用 `10.0.2.2`。

```bash
flutter run -d android --dart-define=PICPAC_API_BASE_URL=http://10.0.2.2:9090
```

### 手机真机

真机需要使用电脑在同一 Wi-Fi 下的局域网 IP。

示例：

```bash
flutter run --dart-define=PICPAC_API_BASE_URL=http://192.168.1.23:9090
```

## 验证命令

```bash
flutter analyze
flutter test
```

## Figma 连接代理

如果需要通过 MCP / agent 连接 Figma，先确认本机代理已开启，并在当前终端设置代理端口。

示例：

```bash
export HTTPS_PROXY=http://127.0.0.1:6268
export HTTP_PROXY=http://127.0.0.1:6268
export ALL_PROXY=socks5h://127.0.0.1:6268
```

端口号以本机代理软件实际显示为准。
