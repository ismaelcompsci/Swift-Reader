//
//  SourceExtensionDetails.swift
//  Read
//
//  Created by Mirna Olvera on 4/24/24.
//

import SwiftUI

struct SourceExtensionDetails: View {
    @Environment(SourceManager.self) var sourceManager

    let sourceId: String

    @State var uiSection: UISection?

    var source: Source? {
        sourceManager.sources.first(where: { $0.id == sourceId })
    }

    var body: some View {
        List {
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    sourceImage

                    Text(source?.sourceInfo.name ?? "Unknown Source")
                    Text(source?.sourceInfo.version ?? "")
                }
                Spacer()
            }
            .listRowBackground(Color.clear)

            Section("Information") {
                HStack {
                    Text("Identifier")
                        .foregroundStyle(.secondary)

                    Spacer()
                    Text(source?.sourceInfo.name ?? "Unknown")
                }

                VStack(alignment: .leading) {
                    Text("Info")
                        .foregroundStyle(.secondary)
                    Text(source?.sourceInfo.info ?? "Unknown")
                }

                VStack(alignment: .leading) {
                    Text("Source URL")
                        .foregroundStyle(.secondary)

                    Text(source?.sourceInfo.sourceUrl?.absoluteString ?? "Unknown")
                }
            }

            if let uiSection = uiSection {
                uiSection.render()
            }
        }
        .task {
            uiSection = await sourceManager.extensions[source?.sourceInfo.id ?? ""]?.getSourceMenu()
        }
    }

    var sourceImage: some View {
        Image(systemName: "puzzlepiece.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(4)
            .frame(width: 64, height: 64)
            .background(.black)
            .clipShape(.rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.ultraThinMaterial, lineWidth: 1)
            }
    }
}

#Preview {
    SourceExtensionDetails(sourceId: "")
}
