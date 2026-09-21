# Dashboard 应用看板（Apple 原生版）

`dashboard-apple` 是 Harmony Gallery / Dashboard 应用看板的 SwiftUI 原生客户端，与 `dashboard-HarmonyOS` 共用 `harmony_markget_get` 后端。iPhone、iPad 和 macOS 的数据浏览、搜索、图表与应用详情均由原生界面完成；S站及外部文档使用受限 WebView。

- Bundle ID：`top.rayawa.dashboard.apple`
- 版本：`3.1.0`（构建号 `30100001`）
- 平台：iPhone、iPad、macOS
- 技术：SwiftUI、Swift Charts、WebKit、URLSession
- 第三方依赖：无

## 功能

### 原生首页

- 应用、元服务、开发者和专题数量
- 由后端配置控制显示的鸿蒙装机量
- 后端同步状态、进度和版本
- 最近收录应用
- 开发者排行
- 每日下载历史与开发者排行
- 下拉刷新与离线缓存提示

### 市场概况与应用总表

- 目标 SDK、最低 SDK 和评分分布图
- API 版本占比历史折线图
- 总下载榜、非华为应用下载榜和 1/7/30 天下载增长榜（分别遵循服务端展示开关）
- 图表拖动选点、横向滚动、时间范围缩放和明确的数值说明
- 应用/元服务类型筛选
- 名称、分类、类型、标签和开发者筛选
- 更新时间、评分数量、大小和上架时间排序；下载量字段与排序由服务端开关控制
- 20/50/100 条分页、上下页导航和页码跳转
- AND/OR 高级组合搜索，支持文本、数值、空值和数组操作符

### 搜索、投稿与详情

- 按应用名称、包名、App ID、华为应用市场链接或看板链接搜索
- 支持从一段分享文字中提取包名与 App ID，小写 `c` 前缀会被规范化
- 名称搜索遍历所有结果页并按相关性排序；提供热门推荐
- 本地保存最近 10 条搜索历史
- 未收录的明确包名或 App ID 会自动尝试投稿
- 原生应用详情、字段信息、评分分布、应用介绍、新版特性和截图
- 下载量、评分历史折线图；支持选点、横向滚动和显示范围缩放
- 打开华为应用市场、隐私政策和系统分享
- 按包名或 App ID 投稿更新，投稿用户名与“我的”设置同步
- 支持 `hmdashboard://` 与 HTTPS 应用详情深链

### 我的与辅助页面

- 用户名、触感偏好及缓存管理
- 教程、重要提示、更新日志、隐私政策和联系方式
- 项目首页、MeoW 频道、API 文档、Web 更新日志、完整友情链接和赞助入口
- Apple 平台开发者诊断信息，不采集或展示精确硬件型号
- 首次启动必须确认重要提示后才会请求市场数据

### S站

侧栏首项提供受限的 `WKWebView` 访问 S站，并使用系统工具栏提供返回、刷新和分享操作。应用数据浏览与搜索仍由原生页面完成。

## 响应式布局

根界面使用 `NavigationSplitView`：

- iPhone：侧栏自动折叠为紧凑导航。
- iPad：侧栏与详情双栏显示，卡片和图表按可用宽度重排。
- macOS：可调整侧栏宽度，内容限制最大阅读宽度，列表、图表和工具栏使用桌面布局。

侧栏从上到下固定为 S站、首页、应用、我的。导航采用 Apple Landmarks 示例一致的值导航模式：侧栏 `NavigationLink(value:)` 更新当前栏目，详情列只保留一个统一的 `NavigationStack`，默认显示首页；系统根据窗口宽度自动决定侧栏、返回按钮与列切换行为。搜索不占用一级入口，而是由“应用”页工具栏进入。

导航栏、工具栏、分段控件、搜索入口、弹窗和按钮全部采用 iOS 26 / macOS 26 原生组件，由系统自动应用 Liquid Glass、交互反馈和可访问性行为。内容卡片遵循 Apple 的内容层设计，不重复叠加玻璃材质；内容区域使用系统分组背景、标准内容底色、分隔线与单一 Accent Color，只有状态警告和图表数据使用对应语义色。

返回、刷新、搜索、分享、筛选等平台操作统一使用 SF Symbols；Dashboard、MeoW、友情链接应用与站点等具有品牌识别意义的图标复用 `dashboard-HarmonyOS` 原始资源，并通过 Apple Asset Catalog 统一管理尺寸、圆角和深浅色环境下的显示。应用远程图标加载失败时也使用与鸿蒙版一致的 Dashboard 占位图。

应用页的“概况 / 总表”切换器与 HarmonyOS 版一致：宽度充足时位于工具栏中央；紧凑宽度、小窗口或辅助功能字号下自动转移到页面顶部，并保持可见。统计卡片、排行榜、应用列表和详情字段使用自适应网格或 `ViewThatFits`，同时支持深色模式、Dynamic Type 和辅助功能标签。

## 数据与缓存

所有业务请求集中在 `AppAPIService`，页面不自行拼接 API：

| 数据 | 新鲜缓存时间 |
| --- | ---: |
| 首页、排行 | 5 分钟 |
| 应用列表、搜索 | 2 分钟 |
| 详情、指标、评分和图表 | 30 分钟 |

网络失败时可回退到最多 30 天内的磁盘缓存，界面会显示缓存时间。缓存文件采用原子写入，超过 128 MiB 时按最旧文件清理至约 96 MiB，读取时也会删除过期项；“我的 → 清除缓存”会同时删除 API 缓存、WebKit 存储和 Cookie，但保留用户名与设置。

客户端使用的主要接口：

- `GET /api/v0/market_info`
- `GET /api/v0/apps/list/{page}`
- `POST /api/v0/apps/query`
- `GET /api/v0/apps/app_id/{app_id}`
- `GET /api/v0/apps/pkg_name/{pkg_name}`
- `GET /api/v0/apps/metrics/{pkg_name}`
- `GET /api/v0/rankings/rate_history`
- `GET /api/v0/rankings/max_download`
- `GET /api/v0/rankings/download_increase`
- `GET /api/v0/rankings/developers`
- `GET /api/v0/charts/rating`
- `GET /api/v0/charts/min_sdk`
- `GET /api/v0/charts/target_sdk`
- `GET /api/v0/charts/api_history`
- `GET /api/v0/dashboard/config`
- `POST /api/v0/submit`

## 项目结构

```text
dashboard/
├── common/
│   ├── AppAPIService.swift     # API、校验、响应限制与缓存策略
│   ├── MarketModels.swift      # 后端 Codable 数据契约
│   ├── MarketCache.swift       # 磁盘缓存
│   ├── DashboardInputParser.swift # 链接、分享文字和标识解析
│   ├── DashboardDeepLink.swift # App URL 路由
│   ├── Formatters.swift        # 数量、大小和日期格式化
│   ├── UserRoutes.swift        # NavigationStack 路由
│   └── constants.swift         # URL、元数据与环境配置
├── component/
│   ├── AdvancedSearchPanel.swift
│   ├── DashboardUI.swift
│   └── LegacyWebView.swift     # 受限的备用 WebView
├── pages/
│   ├── Dashboard.swift         # NavigationSplitView 根入口
│   ├── native/                 # 首页、概况、列表、搜索、投稿、详情、我的
│   └── user/                   # 隐私政策、日志等辅助页面
└── Assets.xcassets/

scripts/ContractProbe/          # 使用真实响应验证 Codable 契约
```

## 安全边界

- App Transport Security 保持系统默认策略，不允许任意明文网络请求。
- WebView 只允许 HTTPS 和应用内本地文件，阻止自定义 scheme 与网页自动弹窗。
- API 路径参数、包名和 App ID 在发出请求前验证。
- 列表与高级搜索限制字段白名单、条件数、页码和输入长度。
- API 响应上限为 8 MB，并设置请求与资源超时。
- 自定义 User-Agent 不包含设备型号或精确系统版本。
- Apple 版不移植鸿蒙设备标识遥测，不创建跨安装追踪标识。
- 本地隐私政策禁用 JavaScript，并通过 CSP 阻止远程资源。
- macOS 沙盒只启用出站网络，不开放入站网络服务。
- 后端可见性配置失败时使用全部关闭的受限配置。

## 构建

要求 Xcode 26 或更高版本，以及项目设置中声明的 iOS 26 / macOS 26 SDK。

1. 使用 Xcode 打开 `dashboard.xcodeproj`。
2. 选择 `dashboard` scheme。
3. 真机运行前，在 Signing & Capabilities 中选择有效的开发团队。
4. 分别选择 iPhone、iPad 模拟器和 My Mac 构建。

命令行构建示例：

```sh
xcodebuild -project dashboard.xcodeproj -scheme dashboard \
  -destination 'platform=macOS' build

xcodebuild -project dashboard.xcodeproj -scheme dashboard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## 验证

静态语法和资源检查：

```sh
swiftc -frontend -parse $(rg --files dashboard -g '*.swift' | sort)
plutil -lint dashboard/Info.plist
git diff --check
```

从实际后端下载测试响应后，可运行数据契约探针：

```sh
swiftc dashboard/common/MarketModels.swift \
  dashboard/common/DashboardInputParser.swift \
  dashboard/common/DashboardDeepLink.swift \
  scripts/ContractProbe/main.swift \
  -o /tmp/dashboard-contract-probe
/tmp/dashboard-contract-probe
```

契约探针覆盖市场概览、普通/高级列表、评分、SDK、API 历史、开发者、每日榜、下载增长、详情指标、评分历史、展示配置、深链和粘贴文本解析。它依赖 `/tmp/dashboard-*.json` 中从实际后端取得的测试响应。

仅安装 Command Line Tools 的环境缺少 SwiftUI 宏插件，无法替代完整 Xcode 构建。发布验收必须在完整 Xcode 中让 macOS、iPhone Simulator 和 iPad Simulator 三个目标均构建成功；不能把上面的语法解析当作构建成功。

发布前还应在浅色/深色模式下手动验证首页、图表选点与缩放、筛选分页、搜索、详情截图、离线缓存、清理缓存、系统分享，以及 iPhone/iPad/macOS 的窗口尺寸变化。

## 隐私说明

应用展示的数据来自公开网络信息，仅供参考，不保证准确性、完整性和即时性。用户填写的投稿用户名会随投稿请求发送；普通浏览不会发送精确设备型号、设备序列号或跨安装标识。完整说明见应用内隐私政策。

Copyright © 2026 Ray Chen (Rayawa). All rights reserved.
