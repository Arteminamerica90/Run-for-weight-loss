//
//  MainView.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: RunTrackerViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Run.timestamp, ascending: false)],
        animation: .default)
    private var runs: FetchedResults<Run>
    
    @State private var selectedTab = 0
    
    init() {
        let locationMgr = LocationManager()
        let context = PersistenceController.shared.container.viewContext
        _locationManager = StateObject(wrappedValue: locationMgr)
        _viewModel = StateObject(wrappedValue: RunTrackerViewModel(locationManager: locationMgr, viewContext: context))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel, locationManager: locationManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            RunHistoryView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(viewModel)
                .environmentObject(locationManager)
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                .tag(1)
            
            ArticlesView()
                .tabItem {
                    Label("Articles", systemImage: "book.fill")
                }
                .tag(2)
            
            RemindersView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
                .tag(3)
        }
    }
}

