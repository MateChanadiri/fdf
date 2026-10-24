import SwiftUI

/// The whole app, dressed like Spotify: four plain tabs under a mini player. Used only while the player look is Spotify.
struct SpotifyShell: View {
    @Environment(Router.self) private var router
    @Environment(LibraryStore.self) private var library
    @Environment(PlayerModel.self) private var player
    var playerNS: Namespace.ID
    @State private var createOpen = false

    static let green = Color(hex: "#1ED760")
    static let ground = Color(hex: "#121212")

    private var selected: AppTab {
        switch router.tab {
        case .home, .search: router.tab
        default: .library
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ZStack {
                        page(.home) { HomePage() }
                        page(.search) { SpotifySearchPage() }
                        page(.library) { SpotifyLibraryPage(createOpen: $createOpen) }
                    }
                    if player.current != nil {
                        SpotifyMiniPlayer().matchedTransitionSource(id: "miniPlayer", in: playerNS)
                            .padding(.horizontal, 8).padding(.bottom, 6)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                if createOpen {
                    Color.black.opacity(0.72).ignoresSafeArea().onTapGesture { withAnimation(.smooth(duration: 0.28)) { createOpen = false } }
                        .transition(.opacity)
                    createCard.padding(.horizontal, 8).padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            tabBar
        }
        .background(Self.ground.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .animation(.smooth(duration: 0.3), value: player.current != nil)
    }

    /// Every tab stays alive (so scroll positions survive); only the chosen one is seen.
    private func page<C: View>(_ tab: AppTab, @ViewBuilder _ content: () -> C) -> some View {
        content()
            .opacity(selected == tab ? 1 : 0)
            .allowsHitTesting(selected == tab)
            .accessibilityHidden(selected != tab)
    }

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem("Home", tab: .home) { on in Image(systemName: on ? "house.fill" : "house").font(.system(size: 23)) }
            tabItem("Search", tab: .search) { on in Image(systemName: "magnifyingglass").font(.system(size: 23, weight: on ? .bold : .regular)) }
            tabItem("Your Library", tab: .library) { on in SpotifyLibraryGlyph(filled: on).frame(width: 26, height: 26) }
            Button {
                withAnimation(.smooth(duration: 0.28)) { createOpen.toggle() }
            } label: {
                VStack(spacing: 3) {
                    ZStack {
                        if createOpen {
                            Circle().fill(Color.white).frame(width: 34, height: 34)
                            Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.black)
                        } else {
                            Image(systemName: "plus").font(.system(size: 26, weight: .light)).foregroundStyle(Color.white.opacity(0.62))
                        }
                    }
                    .frame(height: 34)
                    if !createOpen { Text("Create").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.white.opacity(0.62)) }
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .background(Self.ground.opacity(0.98).ignoresSafeArea(edges: .bottom))
    }

    private func tabItem<I: View>(_ title: String, tab: AppTab, @ViewBuilder icon: (Bool) -> I) -> some View {
        let on = selected == tab && !createOpen
        return Button {
            withAnimation(.smooth(duration: 0.25)) { createOpen = false }
            if router.tab == tab, tab == .library { router.libraryPath = [] }
            else if router.tab == tab { router.paths[router.tabKey(tab)] = [] }
            router.tab = tab
        } label: {
            VStack(spacing: 3) {
                icon(on).frame(height: 28)
                Text(title).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(on ? Color.white : Color.white.opacity(createOpen ? 0.3 : 0.62))
            .frame(maxWidth: .infinity).frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Create card

    private var createCard: some View {
        VStack(spacing: 0) {
            createRow("music.note", "Playlist", "Create a playlist with songs or episodes") { newPlaylist() }
            createRow("person.2.fill", "Collaborative playlist", "Create a playlist together with friends") { newPlaylist() }
            createRow("circle.lefthalf.filled", "Blend", "Combine your friends' tastes into a playlist") { createOpen = false }
        }
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "#282828")))
    }

    private func createRow(_ symbol: String, _ title: String, _ subtitle: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44).background(Circle().fill(Color.white.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .bold))
                    Text(subtitle).font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.65))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func newPlaylist() {
        withAnimation(.smooth(duration: 0.28)) { createOpen = false }
        let p = library.createPlaylist(name: "My playlist #\(library.playlists.count + 1)")
        router.open(.playlist(p.id))
    }
}

// MARK: - Home

/// The existing Home, under Spotify's avatar and filter chips.
private struct HomePage: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: Binding(get: { router.paths["home"] ?? [] }, set: { router.paths["home"] = $0 })) {
            HomeView()
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack(spacing: 8) {
                        SpotifyAvatar().padding(.trailing, 4)
                        chip("All", on: true)
                        chip("Music", on: false)
                        chip("Podcasts", on: false)
                        chip("Audiobooks", on: false)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(SpotifyShell.ground)
                }
                .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
        .background(SpotifyShell.ground)
    }

    private func chip(_ title: String, on: Bool) -> some View {
        Text(title).font(.system(size: 13, weight: .semibold))
            .foregroundStyle(on ? Color.black : Color.white)
            .padding(.horizontal, 14).frame(height: 34)
            .background(Capsule().fill(on ? SpotifyShell.green : Color.white.opacity(0.12)))
    }
}

// MARK: - Search

private struct SpotifySearchPage: View {
    @Environment(Router.self) private var router
    @Environment(LibraryStore.self) private var library
    @FocusState private var focused: Bool

    private static let palette = ["#E13300", "#8D67AB", "#1E3264", "#148A08", "#E91429", "#BA5D07", "#509BF5", "#E8115B", "#477D95", "#D84000", "#7358FF", "#2D46B9"]

    private var searching: Bool { focused || !router.searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    private var genres: [(String, Track)] {
        var seen: [String: [Track]] = [:]
        for t in library.tracks { if let g = t.genre, !g.trimmingCharacters(in: .whitespaces).isEmpty { seen[g, default: []].append(t) } }
        return seen.sorted { $0.value.count > $1.value.count }.compactMap { k, v in v.first.map { (k, $0) } }
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: Binding(get: { router.paths["search"] ?? [] }, set: { router.paths["search"] = $0 })) {
            Group {
                if searching {
                    SearchView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            LazyVGrid(columns: cols, spacing: 12) {
                                tile("Songs", 0, library.tracks.first, .songs)
                                tile("Albums", 3, library.albumEntries.first?.tracks.first, .albums)
                                tile("Artists", 2, library.artistEntries.first?.tracks.first, .artists)
                                tile("Playlists", 1, library.playlistEntries.first?.tracks.first, .playlists)
                            }
                            if !genres.isEmpty {
                                Text("Browse all").font(.system(size: 18, weight: .bold)).padding(.top, 6)
                                LazyVGrid(columns: cols, spacing: 12) {
                                    ForEach(Array(genres.enumerated()), id: \.offset) { i, g in
                                        tile(g.0, i + 4, g.1, nil)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) { header }
            .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
        .background(SpotifyShell.ground)
    }

    private var cols: [GridItem] { [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)] }

    private var header: some View {
        @Bindable var router = router
        return VStack(spacing: 10) {
            if !searching {
                HStack(spacing: 10) {
                    SpotifyAvatar()
                    Text("Search").font(.system(size: 24, weight: .bold))
                    Spacer()
                    Image(systemName: "camera").font(.system(size: 21))
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 18, weight: .medium)).foregroundStyle(Color.black)
                TextField("", text: $router.searchText, prompt: Text("What do you want to listen to?").foregroundColor(Color.black.opacity(0.62)))
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.black).tint(Color.black)
                    .focused($focused).submitLabel(.search).autocorrectionDisabled()
                if searching {
                    Button { router.searchText = ""; focused = false } label: {
                        Text("Cancel").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.black)
                    }
                }
            }
            .padding(.horizontal, 12).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(SpotifyShell.ground)
        .animation(.smooth(duration: 0.25), value: searching)
    }

    private func tile(_ title: String, _ index: Int, _ track: Track?, _ route: Route?) -> some View {
        let color = Color(hex: Self.palette[index % Self.palette.count])
        let body = ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color)
            Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Color.white).padding(12).lineLimit(2)
            if let track {
                ArtworkView(track: track, radius: 4).thumbnail()
                    .frame(width: 66, height: 66)
                    .rotationEffect(.degrees(25))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: 120, y: 54)
            }
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        return Group {
            if let route {
                NavigationLink(value: route) { body }.buttonStyle(.plain)
            } else {
                Button { router.searchText = title; focused = true } label: { body }.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Your Library

private struct SpotifyLibraryPage: View {
    @Environment(Router.self) private var router
    @Environment(LibraryStore.self) private var library
    @Binding var createOpen: Bool

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.libraryPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Playlists").font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14).frame(height: 34)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .padding(.horizontal, 12).padding(.top, 6)
                    HStack {
                        Image(systemName: "arrow.up.arrow.down").font(.system(size: 14, weight: .semibold))
                        Text("Recents").font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "square.grid.2x2").font(.system(size: 16))
                    }
                    .padding(.horizontal, 14).padding(.top, 18).padding(.bottom, 10)

                    NavigationLink(value: Route.favorites) {
                        row(AnyView(SPLibraryHeart()), "Liked Songs", pin: true, "Playlist • \(songCount(library.tracks.filter(\.isFavorite).count))")
                    }.buttonStyle(.plain)
                    ForEach(library.playlistEntries) { entry in
                        NavigationLink(value: entry.route) {
                            row(AnyView(ArtworkView(entry: entry, radius: 4).thumbnail().frame(width: 64, height: 64)), entry.title, pin: false, "Playlist • \(songCount(entry.tracks.count))")
                        }.buttonStyle(.plain)
                    }
                    NavigationLink(value: Route.artists) { addRow("Add artists", circle: true) }.buttonStyle(.plain)
                    addRow("Add podcasts", circle: false)
                    addRow("Add events & venues", circle: false)
                    Button { router.showSongListImport = true } label: { addRow("Import your music", circle: false, symbol: "square.and.arrow.down") }.buttonStyle(.plain)
                }
                .padding(.bottom, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 12) {
                    SpotifyAvatar()
                    Text("Your Library").font(.system(size: 24, weight: .bold))
                    Spacer()
                    Image(systemName: "magnifyingglass").font(.system(size: 22))
                    Button { withAnimation(.smooth(duration: 0.28)) { createOpen.toggle() } } label: {
                        Image(systemName: "plus").font(.system(size: 24, weight: .light)).frame(width: 36, height: 36)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(SpotifyShell.ground)
            }
            .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
        .background(SpotifyShell.ground)
    }

    private func row(_ art: AnyView, _ title: String, pin: Bool, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            art.frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .bold)).lineLimit(1)
                HStack(spacing: 5) {
                    if pin { Image(systemName: "pin.fill").font(.system(size: 11)).foregroundStyle(SpotifyShell.green).rotationEffect(.degrees(45)) }
                    Text(subtitle).font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.65)).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func addRow(_ title: String, circle: Bool, symbol: String = "plus") -> some View {
        HStack(spacing: 14) {
            ZStack {
                if circle { Circle().fill(Color.white.opacity(0.1)) }
                else { RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.white.opacity(0.1)) }
                Image(systemName: symbol).font(.system(size: symbol == "plus" ? 26 : 20, weight: .light)).foregroundStyle(Color.white.opacity(0.7))
            }
            .frame(width: 64, height: 64)
            Text(title).font(.system(size: 16, weight: .bold))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

private struct SPLibraryHeart: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: "#4F2BFF"), Color(hex: "#A6B4FF")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay { Image(systemName: "heart.fill").font(.system(size: 26)).foregroundStyle(Color.white) }
    }
}

/// Spotify's profile bubble.
struct SpotifyAvatar: View {
    @Environment(Router.self) private var router
    var body: some View {
        Button { router.showSettings = true } label: {
            Text("M").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.black)
                .frame(width: 32, height: 32).background(Circle().fill(Color(hex: "#F0592B")))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}

/// "Your Library": two bars and a tilted book; solid when selected.
private struct SpotifyLibraryGlyph: View {
    var filled: Bool
    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 24
            let ink = GraphicsContext.Shading.color(.white)
            let lw = 2.0 * k
            for x in [3.5, 8.5] {
                let r = CGRect(x: x * k, y: 3 * k, width: 2.6 * k, height: 18 * k)
                filled ? ctx.fill(Path(roundedRect: r, cornerRadius: 0.6 * k), with: ink) : ctx.stroke(Path(roundedRect: r.insetBy(dx: lw / 2, dy: lw / 2), cornerRadius: 0.6 * k), with: ink, lineWidth: lw)
            }
            var book = Path()
            book.move(to: CGPoint(x: 14.2 * k, y: 3.4 * k))
            book.addLine(to: CGPoint(x: 20.2 * k, y: 5.2 * k))
            book.addLine(to: CGPoint(x: 20.2 * k, y: 21 * k))
            book.addLine(to: CGPoint(x: 14.2 * k, y: 21 * k))
            book.closeSubpath()
            filled ? ctx.fill(book, with: ink) : ctx.stroke(book, with: ink, style: StrokeStyle(lineWidth: lw, lineJoin: .round))
        }
    }
}

// MARK: - Mini player

/// Spotify's mini player: the cover, the song, connect, add, play; a thin progress line along the bottom.
struct SpotifyMiniPlayer: View {
    @Environment(PlayerModel.self) private var player
    @Environment(Router.self) private var router
    @Environment(LibraryStore.self) private var library

    var body: some View {
        if let track = player.current {
            let live = library.trackByID[track.id] ?? track
            let tint = ArtworkCache.tint(for: track)
            HStack(spacing: 10) {
                ArtworkView(track: track, radius: 4).thumbnail().frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.system(size: 14, weight: .bold)).lineLimit(1)
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous).fill(SpotifyShell.green).frame(width: 13, height: 13)
                            .overlay { Image(systemName: "sparkle").font(.system(size: 7, weight: .black)).foregroundStyle(Color.black.opacity(0.8)) }
                        Text(track.artist).font(.system(size: 13)).foregroundStyle(Color.white.opacity(0.7)).lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                Image("ConnectGlyph").renderingMode(.template).resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24).foregroundStyle(Color.white.opacity(0.9))
                Button { library.toggleFavorite(live) } label: {
                    ZStack {
                        if live.isFavorite {
                            Circle().fill(SpotifyShell.green)
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(Color(white: 0.16))
                        } else {
                            Circle().strokeBorder(Color.white, lineWidth: 1.8)
                            Image(systemName: "plus").font(.system(size: 14, weight: .regular)).foregroundStyle(Color.white)
                        }
                    }
                    .frame(width: 26, height: 26).frame(width: 40, height: 40).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button { player.togglePlay() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 24)).foregroundStyle(Color.white)
                        .frame(width: 40, height: 40).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transaction { $0.animation = nil }
            }
            .padding(.leading, 6).padding(.trailing, 6).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(tint.mix(with: Color.black, by: 0.25)))
            .overlay(alignment: .bottom) { SpotifyMiniProgress().padding(.horizontal, 8).padding(.bottom, 3) }
            .contentShape(Rectangle())
            .onTapGesture { router.showPlayer = true }
            .miniPlayerSwipes()
        }
    }
}

private struct SpotifyMiniProgress: View {
    @Environment(PlayerModel.self) private var player
    var body: some View {
        let f = player.duration > 0 ? min(1, max(0, player.position / player.duration)) : 0
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.28))
                Capsule().fill(Color.white).frame(width: g.size.width * f)
            }
        }
        .frame(height: 2)
    }
}
