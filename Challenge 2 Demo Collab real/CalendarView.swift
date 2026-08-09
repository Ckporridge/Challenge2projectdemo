//
//  CalendarView.swift
//  Challenge 2 Demo Collab
//
//  Created by Chengkun on 7/8/26.
//

import SwiftUI
import Foundation
import SwiftData

struct SheetView: View {
    @Environment(\.modelContext) private var modelContext
    private let dayKey: String
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    private let day: Date
    @State private var noteToDelete: Note?
    @Query private var notes: [Note]

    
    init(day: Date) {
        self.day = day
        let key = Self.key(for: day)
        self.dayKey = key
        _notes = Query(
            filter: #Predicate<Note> { $0.dayKey == key },
            sort: \Note.createdAt
        )
    }
    
    private static func key(for day: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
    
    private func addNote() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = Note(dayKey: dayKey, text: trimmed)
        withAnimation(.easeOut(duration: 0.25)) {
            modelContext.insert(note)
            try? modelContext.save()
        }
        text = ""
    }
    
    private func deleteNote() {
        guard let noteToDelete else { return }
        modelContext.delete(noteToDelete)
        try? modelContext.save()
        self.noteToDelete = nil
    }
    
    var body: some View {
        VStack {
            NoteComposer(text: $text) {
                addNote()
            }
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(notes) { note in
                        NoteRowView(note: note) {
                            noteToDelete = note
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding()
        .alert("Delete this note?", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text(noteToDelete?.text ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .id(day)
    }
}

struct NoteComposer: View {
    @Binding var text: String
    var onAdd: () -> Void

    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Type some sensible stuff", text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit(onAdd)

            if !isEmpty {
                Button(action: onAdd) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: isEmpty)
    }
}

struct NoteRowView: View {
    let note: Note
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(note.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

extension Color {
    /// Converts  Color into a Hex String
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    /// Int a Color from a Hex String
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xff0000) >> 16) / 255
            let g = Double((hexNumber & 0x00ff00) >> 8) / 255
            let b = Double(hexNumber & 0x0000ff) / 255
            self.init(red: r, green: g, blue: b)
            return
        }
        self.init(.blue) // Fallback color if parsing fails
    }
}


struct SettingsView: View {
    @AppStorage("userCalendarHex") private var hexColor: String = "#FF0000"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let colorBinding = Binding<Color>(
            get: { Color(hex: hexColor) },
            set: { newColor in
                if let hex = newColor.toHex() {
                    hexColor = hex
                }
            }
        )
        NavigationStack {
            Form {
                LabeledContent("Calendar Color") {
                    ColorPicker("Select Custom Color", selection: colorBinding)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CalendarView: View {
    //Storing color as a Hex string in AppStorage
    @AppStorage("userCalendarHex") private var hexColor: String = "#FF0000"
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var namespace
    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    @State private var date = Date.now
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date] = []
    @State private var sheetshowing = false
    @State private var settingsShowing = false
    @State private var selectedDay: Date?
    var body: some View {
        VStack {
            LabeledContent("Date") {
                DatePicker("", selection: $date, displayedComponents: .date)
            }
            HStack {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .fontWeight(.black)
                        .foregroundStyle(Color(hex: hexColor))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns) {
                ForEach(days, id: \.self) { day in
                    if day.monthInt != date.monthInt {
                        Text("")
                    } else {
                        Button {
                            selectedDay = day
                            sheetshowing.toggle()
                        } label: {
                            let isToday = Date.now.startOfDay == day.startOfDay
                            let isSelected = selectedDay?.startOfDay == day.startOfDay
                            VStack(spacing: 2) {
                                Text(day.formatted(.dateTime.day()))
                                    .fontWeight(isToday ? .heavy : .bold)
                                    .foregroundStyle(isToday ? .red : (colorScheme == .dark ? .white : .secondary))
                            }
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Circle()
                                            .fill(Color(hex: hexColor).opacity(0.5))
                                            .matchedGeometryEffect(id: "selectedDayCircle", in: namespace)
                                    }
                                    if isToday {
                                        Circle()
                                            .strokeBorder(.red, lineWidth: 2)
                                    } else if !isSelected {
                                        Circle()
                                            .fill(Color(hex: hexColor).opacity(0.15))
                                    }
                                }
                            )
                        }
                        
                        
                    }
                }
            }
            
            .sheet(isPresented: $sheetshowing) {
                if let selectedDay {
                    SheetView(day: selectedDay)
                }
            }
            .sheet(isPresented: $settingsShowing) {
                SettingsView()
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    settingsShowing = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        
        .padding()
    }
}

#Preview {
    CalendarView()
}
