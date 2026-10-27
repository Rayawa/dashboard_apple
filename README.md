# dashboard_apple

English | [简体中文](README_zh.md)

A SwiftUI client for application-market browsing, search and trend charts on Apple platforms.

## Overview

The client presents market summaries, tables, advanced search, application details and cached data through native views. Swift Charts renders trends and a restricted WebView provides the related web-service entry. The external Dashboard backend supplies market data.

## Technology and Dependencies

Swift, SwiftUI, Swift Charts, WebKit and URLSession; no third-party runtime package is declared. The Xcode project declares iOS 26 and macOS 26 deployment targets and requires compatible Xcode/SDK versions.

## Repository Structure

- `dashboard/` — native application and resources
- `dashboard/common/` — API, models and cache
- `dashboard.xcodeproj/` — Xcode project
- `scripts/` — data-contract and development tools

## Quick Start

Open `dashboard.xcodeproj`, select the `dashboard` scheme and a compatible destination. Configure a development team locally for physical devices. A macOS build can be started with:

```bash
xcodebuild -project dashboard.xcodeproj -scheme dashboard   -destination 'platform=macOS' build
```

Review the API endpoint in the service layer before loading data. Use an installed iOS simulator destination for simulator builds.
