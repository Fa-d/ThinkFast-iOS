//
//  MainTabView.swift
//  Intently
//
//  Created on 2025-01-01.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.dependencies) private var dependencies
    @State private var showInterventionSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .tint(.appPrimary)
        .sheet(isPresented: $showInterventionSheet) {
            InterventionSheet()
        }
        .onReceive(dependencies.jitaiInterventionManager.$isShowingIntervention) { isShowing in
            showInterventionSheet = isShowing
        }
    }
}

#Preview {
    MainTabView()
}
