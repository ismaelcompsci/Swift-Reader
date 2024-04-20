//
//  SearchBar.swift
//  Read
//
//  Created by Mirna Olvera on 2/23/24.
//

import SwiftUI

struct SearchBar: View {
    @Environment(AppTheme.self) var theme

    var placeholderText: String?

    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.tintColor)
            TextField(placeholderText ?? "", text: $searchText)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.smooth) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(theme.tintColor)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.bar)
        .clipShape(.capsule)
    }
}

#Preview {
    SearchBar(searchText: .constant("Hello"))

        .preferredColorScheme(.dark)
}
