//
//  RemindersView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import UserNotifications

struct RemindersView: View {
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("reminderDays") private var reminderDaysData = Data()
    
    @State private var selectedDays: Set<Int> = [1, 3, 5] // Mon, Wed, Fri by default
    @State private var showingTimePicker = false
    
    let daysOfWeek = [
        (1, "Mon"), (2, "Tue"), (3, "Wed"), (4, "Thu"),
        (5, "Fri"), (6, "Sat"), (0, "Sun")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Decorative neomorphic circles with different radii
                NeomorphicCircle(radius: 120, offset: CGSize(width: -100, height: -200))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 150, offset: CGSize(width: 150, height: 300))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 100, offset: CGSize(width: -120, height: 400))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 80, offset: CGSize(width: 200, height: 100))
                    .allowsHitTesting(false)
                NeomorphicCircle(radius: 110, offset: CGSize(width: -150, height: 600))
                    .allowsHitTesting(false)
                
                Form {
                Section {
                    Toggle("Enable Reminders", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { enabled in
                            if enabled {
                                requestNotificationPermission()
                                scheduleReminders()
                            } else {
                                cancelReminders()
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                } header: {
                    Text("Settings")
                }
                
                if remindersEnabled {
                    Section {
                        Button(action: {
                            showingTimePicker = true
                        }) {
                            HStack {
                                Text("Time")
                                Spacer()
                                Text(String(format: "%02d:%02d", reminderHour, reminderMinute))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    } header: {
                        Text("Reminder Time")
                    }
                    
                    Section {
                        ForEach(daysOfWeek, id: \.0) { day in
                            Button(action: {
                                if selectedDays.contains(day.0) {
                                    selectedDays.remove(day.0)
                                } else {
                                    selectedDays.insert(day.0)
                                }
                                saveDays()
                                if remindersEnabled {
                                    scheduleReminders()
                                }
                            }) {
                                HStack {
                                    Text(day.1)
                                    Spacer()
                                    if selectedDays.contains(day.0) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .listRowBackground(Color.white.opacity(0.5))
                        }
                    } header: {
                        Text("Days of Week")
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.clear)
            .onAppear {
                // Make Form background transparent
                UITableView.appearance().backgroundColor = .clear
            }
            .navigationTitle("Reminders")
            }
            .sheet(isPresented: $showingTimePicker) {
                TimePickerView(hour: $reminderHour, minute: $reminderMinute) {
                    if remindersEnabled {
                        scheduleReminders()
                    }
                }
            }
            .onAppear {
                loadDays()
                if remindersEnabled {
                    requestNotificationPermission()
                }
            }
        }
    }
    
    private func loadDays() {
        if let days = try? JSONDecoder().decode(Set<Int>.self, from: reminderDaysData) {
            selectedDays = days
        }
    }
    
    private func saveDays() {
        if let data = try? JSONEncoder().encode(selectedDays) {
            reminderDaysData = data
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private let reminderMessages = [
        "Time for your run! Every step brings you closer to your goals.",
        "Let's go for a run! Your body will thank you for this workout.",
        "Ready to hit the pavement? Today's run awaits you!",
        "Don't skip your run! Consistency is the key to success.",
        "It's running time! Push yourself and feel the progress.",
        "Get moving! A good run will boost your energy and mood.",
        "Your run is calling! Step outside and enjoy the fresh air.",
        "Time to lace up! Every run makes you stronger.",
        "Don't wait, just run! The hardest part is getting started.",
        "Make it happen today! Your future self will thank you for this run."
    ]
    
    private func scheduleReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard remindersEnabled && !selectedDays.isEmpty else { return }
        
        let selectedDaysArray = Array(selectedDays).sorted()
        
        for (index, day) in selectedDaysArray.enumerated() {
            var dateComponents = DateComponents()
            dateComponents.weekday = day == 0 ? 1 : day + 1 // Sunday = 1 in DateComponents
            dateComponents.hour = reminderHour
            dateComponents.minute = reminderMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Time to Run!"
            // Use different message for each day, cycling through the array
            let messageIndex = index % reminderMessages.count
            content.body = reminderMessages[messageIndex]
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "runReminder-\(day)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    private func cancelReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = hour
                            components.minute = minute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            hour = components.hour ?? 8
                            minute = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

