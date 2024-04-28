//
//  SourceExtensionDetails.swift
//  Read
//
//  Created by Mirna Olvera on 4/24/24.
//

import SwiftUI

struct SourceExtensionDetails: View {
    @Environment(SourceManager.self) var sourceManger

    let sourceId: String

    var source: Source? {
        sourceManger.sources.first(where: { $0.id == sourceId })
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
