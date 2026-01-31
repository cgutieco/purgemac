//
//  ContentView.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainContentView()
            .frame(minWidth: 600, minHeight: 450)
            .windowVisualEffect()
    }
}

#Preview {
    ContentView()
        .environment(\.themeManager, ThemeManager())
}
