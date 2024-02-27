//
//  Test.swift
//  Read
//
//  Created by Mirna Olvera on 2/24/24.
//

import SwiftUI

struct Test: View {
    @State var loading = false

    @State var searchText = ""

    @State var results = [SearchResult]()

    var body: some View {
        ScrollView {
            HStack {
                TextField("Search", text: $searchText)
                    .padding(.horizontal, 6)
                    .padding(10)
                    .background(.black.opacity(0.70))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 24)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white, lineWidth: 1.0)
                    }

                Button {
                    Task {
                        if loading {
                            return
                        }

                        loading = true
                        let results = await AnnasArchiveAPI.searchBooks(query: searchText)

                        self.results = results

                        loading = false
                    }

                } label: {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.red)
                        .padding()
                }
            }

            HStack {
                if !loading && results.count > 0 {
                    Text("\(results.count) Books")
                        .foregroundStyle(.gray)

                    Spacer()
                }
            }

            LazyVStack {
                if loading {
                    ProgressView()
                        .padding(.vertical, 24)

                } else {
                    ForEach(results) { book in

                        HStack {
                            if let thumbnail = book.thumbnail {
                                AsyncImage(url: URL(string: thumbnail)) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 50, height: 80)
                                .border(.gray, width: 0.5)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 6)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.gray, lineWidth: 0.3)
                                }
                            }
                            VStack(alignment: .leading) {
                                Text(book.title)
                                    .lineLimit(2)

                                Text(book.author ?? "")
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)

                                if let bookInfo = book.info {
                                    Spacer()

                                    Text(bookInfo)
                                        .font(.system(size: 8, weight: .light))
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
    }
}

#Preview {
    Test()
}
