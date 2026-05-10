import SwiftUI

struct DashboardView: View {
    @AppStorage(DashboardSettings.buttonRight) private var buttonRight = SettingsStorage.defaultButtonRight
    @AppStorage(DashboardSettings.immersiveTexture) private var immersiveTexture = SettingsStorage.defaultImmersiveTexture
    @AppStorage(DashboardSettings.pageURL) private var pageURL = SiteEndpoint.s.url.absoluteString

    @State private var path: [AppRoute] = []
    @State private var selectedSite = SiteEndpoint.s
    @State private var isTMode = false
    @State private var reloadToken = UUID()
    @State private var scrollTopToken = UUID()
    @State private var showWarn = false
    @State private var showTutorial = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Color(red: 238 / 255, green: 246 / 255, blue: 254 / 255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Web(
                        url: selectedSite.url,
                        reloadToken: reloadToken,
                        scrollTopToken: scrollTopToken,
                        immersive: immersiveTexture
                    )
                    .safeAreaInset(edge: .top, spacing: 0) {
                        #if os(iOS)
                        Color(red: 238 / 255, green: 246 / 255, blue: 254 / 255)
                            .frame(height: 40)
                        #endif
                    }
                    .id(selectedSite.id)
                }
                .ignoresSafeArea()

                bottomControlBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        if !showWarn { showTutorial = true }
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }

                    ShareLink(item: selectedSite.url) {
                            Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(showWarn)

                    Button {
                        if !showWarn {
                            path.append(.user)
                        }
                    } label: {
                        Image(systemName: "person")
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .user:
                    UserPageView(onNavigate: navigate)
                case .submit:
                    AppSubmitComponent()
                case .query:
                    AppQueryComponent { payload in
                        path.append(.queryWeb(payload))
                    }
                case .friends:
                    FriendPageView(onNavigate: navigate)
                case .friendWeb(let payload):
                    FriendWebPageView(payload: payload)
                case .contact:
                    ContactComponent()
                case .about:
                    AboutPageView(onNavigate: navigate)
                case .aboutWeb(let payload):
                    AboutWebPageView(payload: payload)
                case .queryWeb(let payload):
                    QueryWebPageView(payload: payload)
                case .appLog:
                    AppLogPageView()
                case .htmlPage(let payload):
                    HTMLPageView(payload: payload)
                }
            }
            .sheet(isPresented: $showTutorial) {
                NavigationStack {
                    TutorialComponent()
                }
            }
            .sheet(isPresented: $showWarn) {
                NavigationStack {
                    WarnComponent()
                        .padding()
                        .navigationTitle("重要提示")
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                }
            }
            .task {
                selectedSite = SiteEndpoint.fromPersisted(pageURL)
                isTMode = selectedSite == .t
            }
            .onAppear {
                if UserDefaults.standard.object(forKey: "has_seen_warn") == nil {
                    showWarn = true
                    UserDefaults.standard.set(true, forKey: "has_seen_warn")
                }
            }
        }
    }

    private func navigate(_ route: AppRoute) {
        path.append(route)
    }

    private var bottomControlBar: some View {
        HStack(spacing: 10) {
            if buttonRight {
                actionButton("arrow.up.to.line") {
                    scrollTopToken = UUID()
                }

                siteSwitcher

                actionButton("arrow.clockwise") {
                    reloadToken = UUID()
                }
            } else {
                actionButton("arrow.clockwise") {
                    reloadToken = UUID()
                }

                siteSwitcher

                actionButton("arrow.up.to.line") {
                    scrollTopToken = UUID()
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule(style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 18, y: 6)
        .applyGlassEffectIfAvailable()
    }


    private var siteSwitcher: some View {
        HStack(spacing: 0) {
            Button {
                selectedSite = .t
                pageURL = SiteEndpoint.t.url.absoluteString
                isTMode = true
            } label: {
                Text("T站")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isTMode ? .white : .black)
                    .frame(width: 58, height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isTMode ? Color.black : Color.clear)
                    )
            }
            .buttonStyle(.plain)

            Button {
                selectedSite = .s
                pageURL = SiteEndpoint.s.url.absoluteString
                isTMode = false
            } label: {
                Text("S站")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isTMode ? .black : .white)
                    .frame(width: 58, height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isTMode ? Color.clear : Color.black)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule(style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .applyGlassEffectIfAvailable()
    }

    private func actionButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .applyGlassEffectIfAvailable()
    }
}

private extension View {
    @ViewBuilder
    func applyGlassEffectIfAvailable() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
