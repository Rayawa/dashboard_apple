# dashboard_apple

[English](README.md) | 简体中文

面向 Apple 平台的应用市场浏览、搜索与趋势图 SwiftUI 客户端。

## 项目概述

客户端通过原生页面展示市场概况、总表、高级搜索、应用详情及缓存数据，使用 Swift Charts 绘制趋势，并保留受限 WebView 服务入口。市场数据由外部 Dashboard 后端提供。

## 技术栈与依赖

Swift、SwiftUI、Swift Charts、WebKit、URLSession，未声明第三方运行时包。Xcode 工程的部署目标为 iOS 26 和 macOS 26，需要兼容的 Xcode/SDK。

## 文件结构

- `dashboard/` — 原生应用与资源
- `dashboard/common/` — API、模型与缓存
- `dashboard.xcodeproj/` — Xcode 工程
- `scripts/` — 数据契约及开发工具

## 快速上手

打开 `dashboard.xcodeproj`，选择 `dashboard` scheme 及兼容目标。真机安装前在本地配置开发团队。macOS 构建示例：

```bash
xcodebuild -project dashboard.xcodeproj -scheme dashboard   -destination 'platform=macOS' build
```

加载数据前检查服务层 API 地址；模拟器构建选择本机已安装的 iOS 模拟器目标。
