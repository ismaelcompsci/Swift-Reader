//
//  RefrenceLibrary.swift
//  Read
//
//  Created by Mirna Olvera on 3/15/24.
//

import SwiftUI

struct RefrenceLibrary: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIReferenceLibraryViewController

    var term: String

    init(term: String) {
        self.term = term
    }

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        print("TERM: \(term)")
        let controller = UIReferenceLibraryViewController(term: term)

        return controller
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}

extension View {
    func refrenceLibrary(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, term: Binding<String>) -> some View {
        sheet(isPresented: isPresented, onDismiss: onDismiss, content: {
            RefrenceLibrary(term: term.wrappedValue)
                .ignoresSafeArea()
                .presentationDetents([.medium])
        })
    }
}
