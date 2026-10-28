# Dashboard (Native Apple Client)

English | [简体中文](README_zh.md)


`dashboard-apple` is the native SwiftUI client for Harmony Gallery / Dashboard, sharing the `harmony_markget_get` backend with `dashboard-HarmonyOS`. Data browsing, search, charts, and app details on iPhone, iPad, and macOS use native interfaces; S-site and external documentation use a restricted WebView.

- Bundle ID：`top.rayawa.dashboard.apple`
- Version: `3.1.0` (build `30100001`)
- Platforms: iPhone, iPad, macOS
- Technologies: SwiftUI, Swift Charts, WebKit, URLSession
- Third-party dependencies: None

## Features

### Native home page

- Counts of apps, atomic services, developers, and collections
- HarmonyOS installation counts displayed according to backend configuration
- Backend synchronization status, progress, and version
- Recently indexed apps
- Developer rankings
- Daily download history and developer rankings
- Pull-to-refresh and offline cache notices

### Market overview and app table

- Distributions of target SDK, minimum SDK, and ratings
- Historical API version share line charts
- Total download rankings, non-Huawei app download rankings, and 1/7/30-day download growth rankings, each following server visibility switches
- Drag to select chart points, horizontal scrolling, time-range zoom, and explicit value descriptions
- Filter by app / atomic service type
- Filter by name, category, type, tag, and developer
- Sort by update time, rating count, size, and release time; download fields and sorting follow server switches
- Pages of 20/50/100 entries, previous/next navigation, and page jumps
- Advanced AND/OR search with text, numeric, null, and array operators

### Search, submissions, and details

- Search by app name, package name, App ID, Huawei AppGallery link, or Dashboard link
- Extract package names and App IDs from shared text; normalize lowercase `c` prefixes
- Name searches traverse every results page and sort by relevance; popular recommendations are provided
- Store the last 10 searches locally
- Automatically attempt submission for explicit package names or App IDs that are not indexed
- Native app details, field information, rating distributions, descriptions, release notes, and screenshots
- Download and rating history line charts with point selection, horizontal scrolling, and visible-range zoom
- Open Huawei AppGallery and privacy policies, and use system sharing
- Submit updates by package name or App ID; the submission username follows the Profile setting
- Support `hmdashboard://` and HTTPS app-detail deep links

### Profile and supporting pages

- Username, haptic preferences, and cache management
- Tutorials, important notices, changelog, privacy policy, and contact information
- Project home page, MeoW channel, API documentation, web changelog, complete partner links, and sponsorship entry
- Apple platform developer diagnostics without collecting or displaying exact hardware models
- On first launch, market data is requested only after the important notice is acknowledged

### S-site

The first sidebar item opens S-site in a restricted `WKWebView`, with system toolbar actions for back, refresh, and sharing. App data browsing and search use native pages.

## Responsive layout

The root interface uses `NavigationSplitView`:

- iPhone: The sidebar collapses automatically, with four floating navigation items at the top of the page.
- iPad: Sidebar and detail columns appear side by side; cards and charts reflow to the available width.
- macOS: The sidebar width is adjustable, content has a maximum reading width, and lists, charts, and toolbars use desktop layouts.

When an iPad or macOS window narrows or the user collapses the sidebar, S-site, Home, Apps, and Profile move into a floating material component at the top. It hides automatically when the sidebar returns. The Profile page retains the HarmonyOS version's 14 pt page margins, 14 pt group spacing, 16 pt corner radii, and 54 pt list rows; wide layouts use fixed identity information on the left and independently scrolling settings on the right.

Haptic intensity has three levels: Off / Soft / Firm, selectable by slider or text. iPhone uses native UIKit soft/rigid haptics; macOS uses system trackpad alignment/generic feedback. The system safely ignores feedback on devices without haptic hardware. Switching to Off plays one final subtle notification, then all bound interactions remain silent.

The sidebar order is S-site, Home, Apps, Profile. Navigation follows the value-based pattern in Apple's Landmarks sample: sidebar `NavigationLink(value:)` updates the current section, while the detail column contains one shared `NavigationStack`, showing Home by default. The system manages sidebar visibility, back buttons, and column transitions according to window width. Search is accessed from the Apps toolbar rather than as a top-level section.

Navigation bars, toolbars, segmented controls, search entry points, dialogs, and buttons all use native iOS 26 / macOS 26 components, letting the system apply Liquid Glass, interaction feedback, and accessibility behavior. Content cards follow Apple's content-layer design without stacking extra glass materials. Content areas use system grouped backgrounds, standard content fills, separators, and a single Accent Color; semantic colors are reserved for status warnings and chart data.

Platform actions such as back, refresh, search, share, and filter consistently use SF Symbols. Brand-identifying icons for Dashboard, MeoW, partner apps, and sites reuse original `dashboard-HarmonyOS` assets, managed through Apple Asset Catalog for sizing, corner radii, and light/dark appearance. Failed remote app icon loads use the same Dashboard placeholder as the HarmonyOS version.

The Apps page's Overview / Table switch matches the HarmonyOS version: it sits in the center of the toolbar when space permits and moves to the top of the page for compact widths, small windows, or accessibility text sizes, remaining visible. Statistics cards, rankings, app lists, and detail fields use adaptive grids or `ViewThatFits`, with dark mode, Dynamic Type, and accessibility labels.

## Data and caching

All business requests are centralized in `AppAPIService`; pages do not construct APIs themselves:

| Data | Fresh cache duration |
| --- | ---: |
| Home, rankings | 5 minutes |
| App lists, search | 2 minutes |
| Details, metrics, ratings, charts | 30 minutes |

If the network fails, the client can fall back to disk caches up to 30 days old, displaying their timestamps. Cache files use atomic writes. Above 128 MiB, the oldest files are removed until usage is about 96 MiB; expired entries are also deleted on read. Profile → Clear Cache removes API caches, WebKit storage, and cookies while retaining the username and settings.

Main client endpoints:

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

## Project structure

```text
dashboard/
├── common/
│   ├── AppAPIService.swift     # API, validation, response limits, and caching policy
│   ├── MarketModels.swift      # Backend Codable data contracts
│   ├── MarketCache.swift       # Disk cache
│   ├── DashboardInputParser.swift # Link, shared-text, and identifier parsing
│   ├── DashboardDeepLink.swift # App URL routing
│   ├── Formatters.swift        # Count, size, and date formatting
│   ├── UserRoutes.swift        # NavigationStack routes
│   └── constants.swift         # URLs, metadata, and environment configuration
├── component/
│   ├── AdvancedSearchPanel.swift
│   ├── DashboardUI.swift
│   └── LegacyWebView.swift     # Restricted fallback WebView
├── pages/
│   ├── Dashboard.swift         # NavigationSplitView root
│   ├── native/                 # Home, overview, lists, search, submissions, details, Profile
│   └── user/                   # Privacy policy, changelog, and supporting pages
└── Assets.xcassets/

scripts/ContractProbe/          # Validate Codable contracts using real responses
```

## Security boundaries

- App Transport Security keeps the system default policy and does not allow arbitrary plaintext requests.
- The WebView allows only HTTPS and local in-app files, blocking custom schemes and automatic web popups.
- API path parameters, package names, and App IDs are validated before requests.
- Lists and advanced search restrict field allowlists, condition counts, page numbers, and input lengths.
- API responses are limited to 8 MB, with request and resource timeouts.
- The custom User-Agent excludes device models and exact OS versions.
- The Apple client does not port HarmonyOS device identifier telemetry or create identifiers for tracking across installations.
- The local privacy policy disables JavaScript and uses CSP to block remote resources.
- The macOS sandbox permits outbound networking only, without inbound network services.
- Failed backend visibility configuration falls back to a restricted configuration with everything disabled.

## Build

Requires Xcode 26 or later and the iOS 26 / macOS 26 SDKs declared in the project settings.

1. Open `dashboard.xcodeproj` in Xcode.
2. Select the `dashboard` scheme.
3. Before running on a physical device, select a valid development team in Signing & Capabilities.
4. Build for iPhone Simulator, iPad Simulator, and My Mac separately.

Command-line build examples:

```sh
xcodebuild -project dashboard.xcodeproj -scheme dashboard \
  -destination 'platform=macOS' build

xcodebuild -project dashboard.xcodeproj -scheme dashboard \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Validation

Static syntax and resource checks:

```sh
swiftc -frontend -parse $(rg --files dashboard -g '*.swift' | sort)
plutil -lint dashboard/Info.plist
git diff --check
```

After downloading test responses from the actual backend, run the data contract probe:

```sh
swiftc dashboard/common/MarketModels.swift \
  dashboard/common/DashboardInputParser.swift \
  dashboard/common/DashboardDeepLink.swift \
  scripts/ContractProbe/main.swift \
  -o /tmp/dashboard-contract-probe
/tmp/dashboard-contract-probe
```

The contract probe covers market overview, standard/advanced lists, ratings, SDKs, API history, developers, daily rankings, download growth, detail metrics, rating history, visibility configuration, deep links, and pasted-text parsing. It depends on test responses from the actual backend in `/tmp/dashboard-*.json`.

A Command Line Tools-only environment lacks SwiftUI macro plugins and cannot replace a full Xcode build. Release acceptance requires successful builds for macOS, iPhone Simulator, and iPad Simulator in full Xcode; the syntax parsing above is not proof of a successful build.

Before release, manually verify Home, chart point selection and zoom, filters and pagination, search, detail screenshots, offline caches, cache clearing, system sharing, and iPhone/iPad/macOS window-size changes in both light and dark modes.

## Privacy

The app displays publicly available online information for reference, without guarantees of accuracy, completeness, or timeliness. A user-provided submission username is sent with submission requests; ordinary browsing does not send exact device models, device serial numbers, or identifiers spanning installations. See the in-app privacy policy for the full explanation.

Copyright © 2026 Project maintainers. All rights reserved.
