//
//  InfoTag.swift
//  Read
//
//  Created by Mirna Olvera on 6/18/24.
//

import SwiftUI

struct InfoTag: View {
    let book: SDBook

    enum TagState {
        case new
        case progress
        case finished
    }

    var tagState: TagState {
        if book.isFinished == true {
            return .finished
        } else if book.position != nil {
            return .progress
        } else {
            return .new
        }
    }

    var finished: some View {
        Text("Finished")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    var progress: some View {
        let position = book.position?.totalProgression ?? 0

        return Text("\(Int(position * 100))%")
            .foregroundStyle(.secondary)
            .font(.footnote)
            .minimumScaleFactor(0.001)
    }

    var newtag: some View {
        Text("NEW")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(uiColor: .systemBlue))
            .clipShape(.rect(cornerRadius: 8))
            .foregroundStyle(.white)
    }

    var body: some View {
        HStack(alignment: .center) {
            switch tagState {
            case .new:
                newtag
            case .progress:
                progress
            case .finished:
                finished
            }
        }
    }
}
