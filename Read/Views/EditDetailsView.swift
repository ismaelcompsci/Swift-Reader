//
//  EditDetailsView.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import RealmSwift
import SwiftUI

struct EditDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme

    var book: Book

    @State var title: String
    @State var description: String
    @State var authors: String
    
    init(book: Book) {
        self.book = book

        _title = State(initialValue: book.title)
        _description = State(initialValue: book.summary ?? "")
        let authors = book.authors.map { $0.name }
        
        _authors = State(initialValue: authors.joined(separator: ", "))
    }

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    BookCover(coverPath: book.coverPath)
                        .frame(width: 100, height: 140)
                        .padding(.vertical)
                    
                    SRFromInput(text: $title, inputTitle: "Title")
                    
                    SRFromInput(text: $authors, inputTitle: "Authors")
                    
                    SRFromInput(text: $description, inputTitle: "Description", axis: .vertical)
                    
                    Spacer()
                }
                
                HStack {
                    SRButton(text: "Save") {
                        guard let realm = book.realm?.thaw() else {
                            return
                        }
                        
                        guard let thawedBook = book.thaw() else {
                            return
                        }
                        
                        try? realm.write {
                            thawedBook.title = title
                            thawedBook.summary = description
                            
                            let updatedAuthors: RealmSwift.List<Author> = RealmSwift.List()
                            let authors = authors.split(separator: ",")
                            
                            authors.forEach { name in
                                let author = Author()
                                author.name = String(name).trimmingCharacters(in: .whitespacesAndNewlines)
                                updatedAuthors.append(author)
                            }
                            thawedBook.authors = updatedAuthors
                        }
                        
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(minHeight: 44)
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                        .stroke(theme.tintColor, lineWidth: 2)
                    )
                    .background(theme.tintColor.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 10))
                }
                
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Edit your book")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    SRXButton {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditDetailsView(book: .example1)
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
}
