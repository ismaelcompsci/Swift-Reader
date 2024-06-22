//
//  ReadingNowView.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import SwiftUI

struct ReadingNowView: View {
    var body: some View {
        ScrollView {
            LastEngaged()

            WantToRead()
        }
        .navigationBarTitle("Reading Now", displayMode: .large)
    }
}

#Preview {
    ReadingNowView()
        .preferredColorScheme(.dark)
}
