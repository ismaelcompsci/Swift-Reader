//
//  SearchBar.swift
//  Read
//
//  Created by Mirna Olvera on 2/23/24.
//

import SwiftUI

struct SearchBar: View {
    @EnvironmentObject var appColor: AppColor

    var placeholderText: String?

    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(appColor.accent)
            TextField(placeholderText ?? "", text: $searchText)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.smooth) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(appColor.accent)
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
        .environmentObject(AppColor())
        .preferredColorScheme(.dark)
}
