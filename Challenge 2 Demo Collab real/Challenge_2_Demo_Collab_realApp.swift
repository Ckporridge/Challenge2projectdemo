//
//  Challenge_2_Demo_Collab_realApp.swift
//  Challenge 2 Demo Collab real
//
//  Created by Chengkun on 8/8/26.
//

import SwiftUI
import SwiftData

@main
struct Challenge_2_Demo_Collab_realApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CalendarView()
            }
        }
        .modelContainer(for: Note.self)
    }
}
