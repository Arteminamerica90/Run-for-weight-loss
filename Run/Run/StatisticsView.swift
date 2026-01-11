//
//  StatisticsView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Run.timestamp, ascending: false)],
        animation: .default)
    private var runs: FetchedResults<Run>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Overall Stats
                    VStack(spacing: 15) {
                        Text("Overall Statistics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 15) {
                            StatBox(title: "Total Runs", value: "\(runs.count)", icon: "figure.run", color: .blue)
                            StatBox(title: "Total km", value: String(format: "%.1f", totalDistance), icon: "map", color: .green)
                        }
                        
                        HStack(spacing: 15) {
                            StatBox(title: "Total Time", value: formatTime(totalDuration), icon: "clock", color: .orange)
                            StatBox(title: "Average Pace", value: averagePace > 0 ? String(format: "%.1f", averagePace) : "—", icon: "speedometer", color: .purple)
                        }
                    }
                    .padding()
                    
                    // Weekly Stats
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Daily Statistics (Last 7 Days)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        ForEach(last7Days, id: \.date) { day in
                            DayStatRow(day: day)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
        }
    }
    
    private var totalDistance: Double {
        runs.reduce(0) { $0 + $1.distance }
    }
    
    private var totalDuration: TimeInterval {
        runs.reduce(0) { $0 + $1.duration }
    }
    
    private var averagePace: Double {
        guard totalDistance > 0 else { return 0 }
        return (totalDuration / 60.0) / totalDistance
    }
    
    private var last7Days: [DayStat] {
        let calendar = Calendar.current
        let now = Date()
        var days: [DayStat] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayRuns = runs.filter { run in
                guard let timestamp = run.timestamp else { return false }
                return timestamp >= startOfDay && timestamp < endOfDay
            }
            
            let distance = dayRuns.reduce(0.0) { $0 + $1.distance }
            let duration = dayRuns.reduce(0.0) { $0 + $1.duration }
            
            days.append(DayStat(date: date, distance: distance, duration: duration, count: dayRuns.count))
        }
        
        return days.sorted { $0.date > $1.date }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}


