//
//  ReadingNowView.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import RealmSwift
import SwiftUI

struct ReadingNowView: View {
    @ObservedResults(
        Book.self,
        filter: NSPredicate(
            format: "ANY lists CONTAINS %@",
            ListName.wantToRead.rawValue
        )
    ) var wantToReadBooks

    var body: some View {
        ScrollView {
            LastEngagedView()

            if wantToReadBooks.isEmpty == false {
                wantToRead
            }
        }
        .navigationBarTitle("Reading Now", displayMode: .large)
    }

    var wantToRead: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Want To Read")
                        .font(.headline)
                        .fontDesign(.serif)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }

                Text("Books you'd like to read next.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 24)

            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(wantToReadBooks) { book in
                        BookGridItem(book: book, onEvent: { _ in })
                    }
                }
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .scrollIndicators(.hidden)
            .frame(height: 300)
        }
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                colors: [Color(hex: "1E1E1E"), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ReadingNowView()
        .preferredColorScheme(.dark)
}
