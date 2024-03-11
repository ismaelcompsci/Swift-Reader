//
//  EditDetailsView.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import RealmSwift
import SwiftUI
import TagForm

struct EditDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor

    var book: Book

    @State var title: String
    @State var description: String
    @State var tagInfoList: [TagInfo]

    init(book: Book) {
        self.book = book

        _title = State(initialValue: book.title)
        _description = State(initialValue: book.summary ?? "")

        var initialAuthorTags = [TagInfo]()

        book.authors.forEach { author in
            initialAuthorTags.append(.init(label: author.name, color: .black))
        }

        _tagInfoList = State(initialValue: initialAuthorTags)
    }

    var body: some View {
        VStack {
            SheetHeader(title: "Edit your book")

            ScrollView {
                BookCover(coverPath: book.coverPath)
                    .frame(width: 100, height: 140)
                    .padding(.vertical)

                FormInput(text: $title, inputTitle: "Title")

                HStack {
                    Text("Authors")
                        .foregroundStyle(.gray)

                    TagForm(tagInfoList: $tagInfoList, placeholder: "name...", tagColer: .black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.backgroundSecondary)
                .clipShape(.rect(cornerRadius: 12))

                FormInput(text: $description, inputTitle: "Description", axis: .vertical)

                Spacer()
            }

            HStack {
                AppButton(text: "Save") {
                    guard let realm = book.realm?.thaw() else {
                        return
                    }

                    guard let thawedBook = book.thaw() else {
                        return
                    }

                    try? realm.write {
                        thawedBook.title = title
                        thawedBook.summary = description

                        var updatedAuthors: RealmSwift.List<Author> = RealmSwift.List()

                        tagInfoList.forEach { tag in
                            var author = Author()
                            author.name = tag.label

                            updatedAuthors.append(author)
                        }

                        thawedBook.authors = updatedAuthors
                    }

                    dismiss()
                }

                Spacer()

                AppButton(text: "Cancel") {
                    dismiss()
                }
            }
        }
        .padding()
    }
}

#Preview {
    EditDetailsView(book: .example1)
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
        .environmentObject(AppColor())
}