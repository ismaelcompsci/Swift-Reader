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
    @State var author: String
    
    init(book: Book) {
        self.book = book

        _title = State(initialValue: book.title)
        _description = State(initialValue: book.summary ?? "")
        _author = State(initialValue: book.author ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    BookCover(
                        imageURL: getCoverFullPath(for: book.coverPath ?? ""),
                        title: book.title,
                        author: book.author
                    )
                    .frame(width: 100, height: 140)
                    .padding(.vertical)
                    
                    SRFromInput(text: $title, inputTitle: "Title")
                    
                    SRFromInput(text: $author, inputTitle: "Author")
                    
                    SRFromInput(text: $description, inputTitle: "Description", axis: .vertical)
                    
                    Spacer()
                }
                .contentMargins(12, for: .scrollContent)
                
                HStack {
                    Button("Save") {
                        guard let realm = book.realm?.thaw() else {
                            return
                        }
                        
                        guard let thawedBook = book.thaw() else {
                            return
                        }
                        
                        try? realm.write {
                            thawedBook.title = title
                            thawedBook.summary = description
                            thawedBook.author = author
                        }
                        
                        dismiss()
                    }
                    .buttonStyle(.main)
                    
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
            }
            .padding(.horizontal)
            .toolbarBackground(.visible, for: .navigationBar)
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
    NavigationStack {
        VStack {}
            .sheet(isPresented: .constant(true), onDismiss: nil) {
                EditDetailsView(book: .example1)
                    .environment(\.font, Font.custom("Poppins-Regular", size: 16))
                    .environment(AppTheme.shared)
            }
    }
}
