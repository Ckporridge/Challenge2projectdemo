//
//  CalendarView.swift
//  Challenge 2 Demo Collab
//
//  Created by Chengkun on 7/8/26.
//

import SwiftUI
import Foundation
import Combine
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

struct MonthGrid: View {
    let month: Date
    let hexColor: String
    @Binding var selectedDay: Date?
    @Binding var sheetshowing: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var namespace
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Date.capitalizedFirstLettersOfWeekdays.indices, id: \.self) { index in
                Text(Date.capitalizedFirstLettersOfWeekdays[index])
                    .fontWeight(.black)
                    .foregroundStyle(Color(hex: hexColor))
                    .frame(maxWidth: .infinity)
            }
            ForEach(month.calendarDisplayDays, id: \.self) { day in
                if day.monthInt != month.monthInt {
                    Text("")
                } else {
                    Button {
                        selectedDay = day
                        sheetshowing = true
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
    }
}

struct FixedWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    var rowCount: Int
    var titleForRow: (Int) -> String

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        @Binding var selection: Int
        var rowCount: Int
        var titleForRow: (Int) -> String
        var lastAppliedSelection: Int?

        init(selection: Binding<Int>, rowCount: Int, titleForRow: @escaping (Int) -> String) {
            _selection = selection
            self.rowCount = rowCount
            self.titleForRow = titleForRow
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            rowCount
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            titleForRow(row)
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selection = row
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, rowCount: rowCount, titleForRow: titleForRow)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.dataSource = context.coordinator
        pickerView.delegate = context.coordinator
        pickerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pickerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        pickerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pickerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        return pickerView
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        context.coordinator.rowCount = rowCount
        context.coordinator.titleForRow = titleForRow
        if context.coordinator.lastAppliedSelection != selection {
            uiView.selectRow(selection, inComponent: 0, animated: false)
            context.coordinator.lastAppliedSelection = selection
        }
    }
}

final class MonthYearPickerModel: ObservableObject {
    @Published var selectedMonthRow: Int
    @Published var selectedYearRow: Int

    let months: [String]

    var yearValues: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 50)...(currentYear + 50))
    }

    init(date: Date) {
        self.months = Calendar.current.monthSymbols
        let calendar = Calendar.current
        self.selectedMonthRow = calendar.component(.month, from: date) - 1
        let year = calendar.component(.year, from: date)
        let currentYear = calendar.component(.year, from: Date())
        let yearRange = Array((currentYear - 50)...(currentYear + 50))
        self.selectedYearRow = yearRange.firstIndex(of: year) ?? 50
    }

    func monthRow(for date: Date) -> Int {
        Calendar.current.component(.month, from: date) - 1
    }

    func yearRow(for date: Date) -> Int {
        yearValues.firstIndex(of: Calendar.current.component(.year, from: date)) ?? 50
    }
}

struct MonthYearWheelPicker: View {
    @Binding var date: Date
    @StateObject private var model: MonthYearPickerModel

    init(date: Binding<Date>) {
        _date = date
        _model = StateObject(wrappedValue: MonthYearPickerModel(date: date.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 12) {
            FixedWheelPicker(
                selection: $model.selectedMonthRow,
                rowCount: model.months.count,
                titleForRow: { model.months[$0] }
            )
            .frame(width: 190)

            FixedWheelPicker(
                selection: $model.selectedYearRow,
                rowCount: model.yearValues.count,
                titleForRow: { String(model.yearValues[$0]) }
            )
            .frame(width: 110)
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
        .onChange(of: model.selectedMonthRow) { _, row in
            updateDate(month: row + 1, year: nil)
        }
        .onChange(of: model.selectedYearRow) { _, row in
            updateDate(month: nil, year: model.yearValues[row])
        }
        .onChange(of: date) { _, _ in
            syncFromDate()
        }
    }

    private func syncFromDate() {
        let monthRow = model.monthRow(for: date)
        if model.selectedMonthRow != monthRow { model.selectedMonthRow = monthRow }
        let yearRow = model.yearRow(for: date)
        if model.selectedYearRow != yearRow { model.selectedYearRow = yearRow }
    }

    private func updateDate(month: Int?, year: Int?) {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        if let month { comps.month = month }
        if let year { comps.year = year }
        let target = Calendar.current.date(from: comps) ?? date
        if let day = comps.day {
            let maxDay = Calendar.current.range(of: .day, in: .month, for: target)?.count ?? 28
            comps.day = min(day, maxDay)
        }
        if let updated = Calendar.current.date(from: comps) {
            date = updated
        }
    }
}

struct CalendarView: View {
    //Storing color as a Hex string in AppStorage
    @AppStorage("userCalendarHex") private var hexColor: String = "#FF0000"
    @State private var date = Date.now
    @State private var isDateExpanded = false
    @State private var selectedTab = 2
    @State private var sheetshowing = false
    @State private var settingsShowing = false
    @State private var selectedDay: Date?
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool {
        verticalSizeClass == .regular
    }

    var body: some View {
        VStack(spacing: 4) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    isDateExpanded.toggle()
                }
            } label: {
                LabeledContent("Date") {
                    Text(date.formatted(.dateTime.month(.wide).year()))
                        .font(.body.bold())
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.red.opacity(0.15))
                        )
                }
            }
            .buttonStyle(.plain)

            if isDateExpanded {
                MonthYearWheelPicker(date: $date)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            TabView(selection: $selectedTab) {
                ForEach(-2...2, id: \.self) { offset in
                    MonthGrid(
                        month: month(for: offset),
                        hexColor: hexColor,
                        selectedDay: $selectedDay,
                        sheetshowing: $sheetshowing
                    )
                    .tag(offset + 2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity, alignment: .top)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        date = shiftedMonth(by: -2)
                    }
                    selectedTab = 2
                } else if newValue == 4 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        date = shiftedMonth(by: 2)
                    }
                    selectedTab = 2
                }
            }
            .sheet(isPresented: $sheetshowing) {
                if let selectedDay {
                    SheetView(day: selectedDay)
                }
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
        .sheet(isPresented: $settingsShowing) {
            SettingsView()
        }
    }

    private func month(for offset: Int) -> Date {
        let base = Calendar.current.dateInterval(of: .month, for: date)!.start
        return Calendar.current.date(byAdding: .month, value: offset, to: base) ?? base
    }

    private func shiftedMonth(by offset: Int) -> Date {
        month(for: offset)
    }
}

#Preview {
    CalendarView()
}
