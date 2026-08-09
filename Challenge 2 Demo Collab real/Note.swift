//
//  Note.swift
//  Challenge 2 Demo Collab
//
//  Created by Chengkun on 8/8/26.
//

import Foundation
import SwiftData

@Model
final class Note {
    var dayKey: String
    var text: String
    var createdAt: Date

    init(dayKey: String, text: String, createdAt: Date = .now) {
        self.dayKey = dayKey
        self.text = text
        self.createdAt = createdAt
    }
}