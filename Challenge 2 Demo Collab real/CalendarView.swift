//
//  CalendarView.swift
//  Challenge 2 Demo Collab
//
//  Created by Chengkun on 7/8/26.
//

import SwiftUI
import Foundation


struct SheetView: View {
    @State private var userInput = ""
    var body: some View {
        
        VStack{
            TextField("Type some sensible stuff", text: $userInput)
            
            
            
        }
        
        
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
    let daysOfWeek = Date.capitalizedFirstLettersOfWeekdays
    @State private var date = Date.now
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @State private var days: [Date] = []
    @State private var sheetshowing = false
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
                            sheetshowing.toggle()
                            
                        } label: {
                            Text(day.formatted(.dateTime.day()))
                                .fontWeight(.bold)
                            
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(
                                    Circle()
                                        .foregroundStyle(
                                            Date.now.startOfDay == day.startOfDay
                                            ? .red.opacity(0.3)
                                            : Color(hex: hexColor).opacity(0.3)
                                        )
                                )
                        }
                        
                        
                    }
                }
            }
            
            .sheet(isPresented: $sheetshowing) {
                SheetView()
            }
        }
        .padding()
        .onAppear {
            days = date.calendarDisplayDays
        }
        .onChange(of: date) {
            days = date.calendarDisplayDays
        }
        VStack(spacing: 25) {
            Text("App Theme Color")
                .font(.title2)
                .bold()
            
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: hexColor))
                .frame(width: 120, height: 120)
                .shadow(radius: 5)
            
            // ColorPicker updating AppStorage via custom binding
            
            
            
        }
        .padding()
    }
}

#Preview {
    CalendarView()
}
