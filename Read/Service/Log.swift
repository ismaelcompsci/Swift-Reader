//
//  Log.swift
//  Read
//
//  Created by Mirna Olvera on 4/24/24.
//

import Foundation

func Log(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n"
) {
    let output = items.map { "SR_LOG: \($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
}
