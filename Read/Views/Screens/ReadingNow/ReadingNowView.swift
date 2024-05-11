//
//  ReadingNowView.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import RealmSwift
import SwiftUI

struct ReadingNowView: View {
    @Environment(Navigator.self) var navigator

    @State var selectedBook: Book?

    var body: some View {
        ScrollView {
            LastEngaged(handleBookItemEvent: handleBookItemEvent)

            WantToRead(handleBookItemEvent: handleBookItemEvent)

            Spacer()
        }
        .navigationBarTitle("Reading Now", displayMode: .large)
        .sheet(item: $selectedBook) { book in
            EditDetailsView(book: book)
        }
    }

    func handleBookItemEvent(_ book: Book, _ event: BookItemEvent) {
        switch event {
        case .onDelete:
            BookManager.shared.delete(book)
        case .onClearProgress:
            book.removeReadingPosition()
        case .onEdit:
            selectedBook = book
        case .onNavigate:
            navigator.navigate(to: .localDetails(book: book))
        case .onAddToList(let list):
            book.addToList(list)
        case .onRemoveFromList(let list):
            book.removeFromList(list)
        }
    }
}

#Preview {
    ReadingNowView()
        .preferredColorScheme(.dark)
}
