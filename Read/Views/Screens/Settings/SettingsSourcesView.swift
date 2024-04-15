//
//  SettingsSourcesView.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import SwiftUI

struct InterfaceTag: View {
    var systemName: String
    var background: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .padding(4)
            .background(background)
            .clipShape(.rect(cornerRadius: 6))
    }
}

struct SourceRow: View {
    @Environment(AppTheme.self) var theme

    var source: SourceInfo
    var needsUpdate: Bool
    var isInstalled: Bool = false
    var showButton: Bool = true

    @State var buttonState: ButtonState
    var onEvent: ((ButtonEvent) async -> Void)?

    enum ButtonEvent {
        case download(URL)
        case uninstall(SourceInfo)
        case reload
    }

    init(
        source: SourceInfo,
        isInstalled: Bool,
        needsUpdate: Bool = false,
        showButton: Bool = true,
        onEvent: ((ButtonEvent) async -> Void)? = nil
    ) {
        self.source = source
        self.needsUpdate = needsUpdate
        self.isInstalled = isInstalled
        self.onEvent = onEvent
        self.showButton = showButton

        self._buttonState = State(initialValue: isInstalled ? .reload : .get)
    }

    enum ButtonState {
        case get
        case loading
        case reload
        case error
    }

    var buttonLabel: some View {
        Group {
            switch buttonState {
            case .get:
                Text("GET")
            case .loading:
                ProgressView()
            case .reload:
                Text("RELOAD")
            case .error:
                Text("ERROR")
            }
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "puzzlepiece.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(4)
                .frame(width: 54, height: 54)
                .background(.black)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(source.name)

                HStack(spacing: 4) {
                    Text("\(source.info) | \(source.version)")
                        .foregroundStyle(.gray)
                        .font(.system(size: 8))

                    if needsUpdate {
                        Text("\(needsUpdate ? " -> update" : "")")
                            .font(.system(size: 8))
                            .lineLimit(1)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(theme.tintColor)
                            )
                            .padding(1)
                    }
                }

                HStack {
                    if source.interfaces.downloads {
                        InterfaceTag(systemName: "arrow.down.app.fill", background: .orange)
                    }

                    if source.interfaces.homePage {
                        InterfaceTag(systemName: "newspaper.circle.fill", background: .black)
                    }

                    if source.interfaces.search {
                        InterfaceTag(systemName: "magnifyingglass.circle.fill", background: .cyan)
                    }
                }
            }

            if showButton {
                Spacer()

                Button {
                    Task {
                        await action()
                    }
                } label: {
                    buttonLabel
                }
                .font(.system(size: 15, weight: .bold))
                .clipShape(.capsule)
                .controlSize(.mini)
                .buttonStyle(.bordered)
                .disabled(buttonState == .loading)
                .foregroundStyle(theme.tintColor)
            }
        }
        .if(isInstalled) { view in
            view.contextMenu(menuItems: {
                Button("Uninstall", role: .destructive) {
                    Task {
                        await onEvent?(.uninstall(source))
                        buttonState = .get
                    }
                }

            })
        }
    }

    func action() async {
        switch buttonState {
        case .get:
            await getSource(source)
        case .loading:
            break
        case .reload:
            buttonState = .loading
            await onEvent?(.reload)
            buttonState = .reload
        case .error:
            // todo
            break
        }
    }

    func getSource(_ externalSource: SourceInfo) async {
        guard let url = externalSource.sourceUrl else { return }

        withAnimation {
            buttonState = .loading
        }

        let sourceURL = url
            .appending(path: externalSource.name.appending(".zip"))

        await onEvent?(.download(sourceURL))

        withAnimation {
            buttonState = .reload
        }
    }
}

struct SourceView: View {
    @Environment(SourceManager.self) var sourceManager
    @Environment(\.dismiss) private var dismiss
    @Environment(AppTheme.self) var theme

    var sourceUrl: URL

    @State var sources: [SourceInfo] = []
    @State var installedSourcesDict: [String: SourceInfo] = [:]
    @State var needsUpdateSources: [String: Bool] = [:]

    var body: some View {
        VStack {
            List {
                Section("Sources") {
                    ForEach(sources, id: \.self) { source in
                        let installed = installedSourcesDict[source.id]
                        let needsUpdate = needsUpdateSources[source.id] ?? false

                        SourceRow(
                            source: source,
                            isInstalled: installed != nil,
                            needsUpdate: needsUpdate
                        ) { event in
                            switch event {
                            case .download(let url):
                                await downloadSource(from: url)
                            case .uninstall(let sourceInfo):
                                await uninstall(source: sourceInfo)
                            case .reload:
                                await reloadSource(for: source)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Sources")
                }
                .tint(theme.tintColor)
            }
        }
        .task {
            await loadSources()
        }
    }

    func reloadSource(for sourceInfo: SourceInfo) async {
        let url = sourceUrl.pathExtension.isEmpty ? sourceUrl : sourceUrl.deletingLastPathComponent()
        let importURL = url.appending(path: sourceInfo.name.appending(".zip"))

        guard let oldSource = sourceManager.source(for: sourceInfo.id) else {
            return
        }

        installedSourcesDict.removeValue(forKey: sourceInfo.id)
        sourceManager.remove(source: oldSource)

        let source = await sourceManager.importSource(from: importURL)
        if let source, let index = sources.firstIndex(where: { $0.id == source.id }) {
            installedSourcesDict.updateValue(source.sourceInfo, forKey: source.id)
            sources.remove(at: index)
            sources.insert(source.sourceInfo, at: index)
        }

        await loadSources()
    }

    func loadSources() async {
        var installedSources = sourceManager.sources
            .filter {
                if let url = $0.sourceInfo.sourceUrl {
                    return url.deletingLastPathComponent() == sourceUrl.deletingLastPathComponent()
                } else {
                    return false
                }
            }
            .compactMap {
                $0.sourceInfo
            }

        for instSource in installedSources {
            installedSourcesDict[instSource.id] = instSource
            installedSourcesDict.updateValue(instSource, forKey: instSource.id)
        }

        let url = sourceUrl.pathExtension.isEmpty ? sourceUrl : sourceUrl.deletingLastPathComponent()

        guard var externalSources = await sourceManager.loadSourceList(url: url) else {
            return
        }

        externalSources = externalSources.filter { externalSource in
            let installedSource = installedSources.first(where: { $0.id == externalSource.id })

            if let installedSource = installedSource, installedSource.version != externalSource.version {
                Log("\(installedSource.name) needs update")
                needsUpdateSources[installedSource.id] = true
            }

            return installedSources.contains { $0.id == externalSource.id } == false
        }

        for index in externalSources.indices {
            externalSources[index].sourceUrl = url
        }

        installedSources.append(contentsOf: externalSources)
        installedSources.sort(by: { $0.name < $1.name })

        sources = installedSources
    }

    func uninstall(source: SourceInfo) async {
        guard let source = sourceManager.source(for: source.id) else {
            return
        }

        sourceManager.remove(source: source)
        installedSourcesDict.removeValue(forKey: source.id)

        await loadSources()
    }

    func downloadSource(from url: URL) async {
        let source = await sourceManager.importSource(from: url)

        if let sourceInfo = source?.sourceInfo {
            installedSourcesDict[sourceInfo.id] = sourceInfo
        }

        await loadSources()
    }
}

struct SettingsSourcesView: View {
    @Environment(SourceManager.self) private var sourceManager
    @Environment(AppTheme.self) var theme
    @Environment(\.editMode) var editMode
    @Environment(\.dismiss) var dismiss

    @State var showAddSourceSheet = false
    @State var sourceUrl = "https://raw.githubusercontent.com/ismaelcompsci/Swift-Reader-Extensions-JS/main/bundles/sources.json"

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(sourceManager.sources) { source in
                        SourceRow(source: source.sourceInfo, isInstalled: true, showButton: false)
                    }
                    .onDelete(perform: deleteSource)
                } header: {
                    Text("Installed Extensions")
                }

                Section {
                    ForEach(sourceManager.sourceLists, id: \.self) { source in
                        NavigationLink {
                            SourceView(sourceUrl: source)
                        } label: {
                            Text(source.absoluteString)
                                .lineLimit(1)
                        }
                    }
                    .onDelete(perform: deleteSourceList)
                } header: {
                    Text("Sources")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Sources")
        .sheet(isPresented: $showAddSourceSheet, content: {
            VStack(spacing: 18) {
                Image(systemName: "shippingbox.circle.fill")
                    .resizable()
                    .frame(width: 78, height: 78)

                TextField("Source base url", text: $sourceUrl)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.backgroundSecondary)
                    .clipShape(.rect(cornerRadius: 12))
                    .tint(theme.tintColor)

                Spacer()

                SRButton(text: "Add to Read") {
                    Task {
                        await addSource()
                    }
                }
            }
            .padding()
            .presentationDetents([.medium])
            .presentationBackground(.thinMaterial)

        })
        .toolbar {
            if let editMode, editMode.wrappedValue == .active {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showAddSourceSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(theme.tintColor)
                }
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Settings")
                        }
                    }
                    .tint(theme.tintColor)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .tint(theme.tintColor)
            }
        }
    }

    func deleteSource(indexSet: IndexSet) {
        for index in indexSet {
            let source = sourceManager.sources[index]

            sourceManager.remove(source: source)
        }
    }

    func deleteSourceList(indexSet: IndexSet) {
        for index in indexSet {
            let url = sourceManager.sourceLists[index]

            sourceManager.removeSourceList(url: url)
        }
    }

    func addSource() async {
        guard let url = URL(string: sourceUrl) else {
            return
        }

        let _ = await sourceManager.addSourceList(url: url)

        showAddSourceSheet = false
        sourceUrl = ""
    }
}

#Preview {
    SettingsSourcesView()
}
