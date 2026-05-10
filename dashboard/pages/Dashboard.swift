import SwiftUI

struct DashboardView: View {
    @AppStorage(DashboardSettings.buttonRight) private var buttonRight = SettingsStorage.defaultButtonRight
    @AppStorage(DashboardSettings.immersiveTexture) private var immersiveTexture = SettingsStorage.defaultImmersiveTexture
    @AppStorage(DashboardSettings.pageURL) private var pageURL = SiteEndpoint.s.url.absoluteString

    @State private var path: [AppRoute] = []
    @State private var selectedSite = SiteEndpoint.s
    @State private var reloadToken = UUID()
    @State private var scrollTopToken = UUID()
    @State private var showWarn = false
    @State private var showTutorial = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.white.ignoresSafeArea()
                browserRoot
            }
            .navigationTitle("Hm应用看板")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
            }
            .onAppear {
                if UserDefaults.standard.object(forKey: "has_seen_warn") == nil {
                    showWarn = true
                    UserDefaults.standard.set(true, forKey: "has_seen_warn")
                }
            }
        }
    }

    private var browserRoot: some View {
        ZStack(alignment: buttonRight ? .bottomTrailing : .bottomLeading) {
            VStack(spacing: 0) {
                Web(
                    url: selectedSite.url,
                    reloadToken: reloadToken,
                    scrollTopToken: scrollTopToken,
                    immersive: immersiveTexture
                )
                .id(selectedSite.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                siteTabBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            floatingButtons
                .padding(.horizontal, 18)
                .padding(.bottom, 88)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func navigate(_ route: AppRoute) {
        path.append(route)
    }

    private var siteTabBar: some View {
        HStack(spacing: 12) {
            ForEach(SiteEndpoint.allCases) { site in
                Button {
                    selectedSite = site
                    pageURL = site.url.absoluteString
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: site.icon)
                        Text(site.title)
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedSite == site ? Color.black.opacity(0.08) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .applyGlassEffectIfAvailable()
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var floatingButtons: some View {
        VStack(spacing: 12) {
            actionButton("arrow.up.to.line") {
                scrollTopToken = UUID()
            }
            actionButton("arrow.clockwise") {
                reloadToken = UUID()
            }
        }
    }

    private func actionButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .frame(width: 50, height: 50)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
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
