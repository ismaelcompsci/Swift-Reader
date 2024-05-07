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
            LastEngagedView()

//            VStack {
//                HStack {
//                    Text("Want To Read")
//                        .font(.headline)
//                        .fontDesign(.serif)
//
//                    Image(systemName: "chevron.right")
//                }
//            }
//
//            Spacer()
        }
        .navigationBarTitle("Reading Now", displayMode: .large)
    }
}

#Preview {
    ReadingNowView()
}
