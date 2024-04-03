//
//  EditViewModel.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import Foundation

class EditViewModel: ObservableObject {
    @Published var editBookReady = false

    @Published var showEditView = false { didSet { isReady() } }
    @Published var book: Book? = nil { didSet { isReady() } }

    func isReady() {
        if showEditView == true && book != nil {
            editBookReady = true
        }
    }

    func reset() {
        editBookReady = false
        showEditView = false
        book = nil
    }
}
