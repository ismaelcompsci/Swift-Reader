//
//  TagField.swift
//  Read
//
//  Created by Mirna Olvera on 4/23/24.
//

import SwiftUI

struct Tag: Identifiable, Hashable {
    var id: UUID = .init()
    var value: String
}

struct TagField: View {
    @Binding var tags: [Tag]
    var header: String?
    var placeholder: String

    @FocusState private var isFocused: Bool
    @State var text: String = ""

    @ViewBuilder
    func createTagView(_ tag: Tag) -> some View {
        HStack {
            Text(tag.value)

            Button {
                withAnimation {
                    tags.removeAll(where: { $0.id == tag.id })
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .colorInvert()
    }

    var body: some View {
        WrappingStackLayout(alignment: .leading) {
            if let header = header {
                Text(header)
                    .foregroundStyle(.secondary)
            }

            ForEach(tags) { tag in
                createTagView(tag)
            }
            .id(tags.count)

            TextField(placeholder, text: $text)
                .focused($isFocused)
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
        .clipShape(.rect(cornerRadius: 12))
        .onTapGesture {
            if isFocused == false {
                isFocused = true
            }
        }
        .onSubmit {
            guard !text.isEmpty else { return }

            let newTag = Tag(value: text)
            withAnimation {
                tags.append(newTag)
            }
            text = ""
        }
    }
}

#Preview {
    struct Test: View {
        @State var tags: [Tag] = [
            .init(value: "first")
        ]
        var body: some View {
            VStack {
                TagField(tags: $tags, header: "Authors", placeholder: "Author")

                SRFromInput(text: .constant("test"), inputTitle: "yes")
            }
            .padding()
        }
    }

    return Test()
}
