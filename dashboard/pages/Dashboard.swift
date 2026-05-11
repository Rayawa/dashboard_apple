import SwiftUI

enum DashboardSegment: String, CaseIterable, Identifiable {
    case t = "T站"
    case s = "S站"

    var id: String { rawValue }

    var endpoint: SiteEndpoint {
        switch self {
        case .t:
            return .t
        case .s:
            return .s
        }
    }
}

struct DashboardView: View {
    @State private var segment: DashboardSegment = .s

    @State private var path: [AppRoute] = []
    @State private var reloadToken = UUID()
    @State private var scrollTopToken = UUID()
    @State private var goBackToken = UUID()
    @State private var showWarn = false
    @State private var showTutorial = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                VStack {
                    Web(
                        url: segment.endpoint.url,
                        reloadToken: reloadToken,
                        scrollTopToken: scrollTopToken,
                    )
                    .id(segment.id)
                }
                .ignoresSafeArea()
                .background(Color.clear)
                .overlay(alignment: .top) {
                            Picker("Dashboard Segment", selection: $segment) {
                                ForEach(DashboardSegment.allCases) { item in
                                    Text(item.rawValue)
                                        .tag(item)
                                        .fontWeight(.bold)
                                }
                            }
                            .pickerStyle(.segmented)
                            .glassEffect()
                            .textCase(nil)
                            .frame(width: 200, height: 64)
                            .padding(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))

                }

                rightControlBar
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
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
                    QueryWeb(payload: payload)
                case .contact:
                    ContactComponent()
                case .about:
                    AboutPageView(onNavigate: navigate)
                case .aboutWeb(let payload):
                    AboutWebPageView(payload: payload)
                case .queryWeb(let payload):
                    QueryWeb(payload: payload)
                case .appLog:
                    AppLogPageView()
                case .htmlPage(let payload):
                    HTMLPageView(payload: payload)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if !showWarn {
                            showTutorial = true
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }

                    ShareLink(item: segment.endpoint.url) {
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
            .onAppear {
                if UserDefaults.standard.object(forKey: "has_seen_warn") == nil {
                    showWarn = true
                    UserDefaults.standard.set(true, forKey: "has_seen_warn")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func navigate(_ route: AppRoute) {
        path.append(route)
    }

    private var rightControlBar: some View {
        VStack(spacing: 12) {
            actionButton("chevron.backward") {
                goBackToken = UUID()
            }

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
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .frame(width: 48, height: 48)
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
