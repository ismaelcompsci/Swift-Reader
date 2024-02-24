//
//  SearchBar.swift
//  Read
//
//  Created by Mirna Olvera on 2/23/24.
//

import SwiftUI

struct SearchBar: View {
    var placeholderText: String?

    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.accent)
            TextField(placeholderText ?? "", text: $searchText)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.smooth) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(Color.accent)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .clipShape(.capsule)
    }
}

#Preview {
    SearchBar(searchText: .constant("Hello"))
}
