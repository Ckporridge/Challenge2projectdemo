//
//  CalendarView.swift
//  Challenge 2 Demo Collab
//
//  Created by Chengkun on 7/8/26.
//

import SwiftUI
import Foundation


struct SheetView: View {
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    private let day: Date
    
    init(day: Date) {
        self.day = day
    }
    
    private static func key(for day: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        return String(format: "dayNote-%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
    
    var body: some View {
        VStack {
            TextField("Type some sensible stuff", text: $text)
                .padding()
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            text = UserDefaults.standard.string(forKey: Self.key(for: day)) ?? ""
        }
        .onChange(of: day) {
            text = UserDefaults.standard.string(forKey: Self.key(for: day)) ?? ""
        }
        .onChange(of: text) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: Self.key(for: day))
            UserDefaults.standard.synchronize()
        }
        .id(day)
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
    @State private var selectedDay: Date?
    var body: some View {
        // binding between Color and String
        let colorBinding = Binding<Color>(
            get: { Color(hex: hexColor) },
            set: { newColor in
                if let hex = newColor.toHex() {
                    hexColor = hex
                }
            }
        )
        VStack {
            LabeledContent("Calendar Color") {
                ColorPicker("Select Custom Color", selection: colorBinding)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            LabeledContent("Date/Time") {
                DatePicker("", selection: $date)
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
        }
        .padding()
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
