//
//  HistoryService.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation

// MARK: - History Service

/// Servicio para gestionar el historial de apps escaneadas recientemente
actor HistoryService {
    
    // MARK: - Singleton
    
    static let shared = HistoryService()
    
    // MARK: - Configuration
    
    private let maxEntries = 10
    private let storageKey = "recentAppsHistory"
    
    // MARK: - Public API
    
    /// Agrega o actualiza una entrada en el historial
    func addEntry(
        appURL: URL,
        bundleIdentifier: String?,
        displayName: String,
        artifactCount: Int,
        totalSize: Int64
    ) async {
        var entries = load()
        
        // Si la app ya existe, elimínala (la agregaremos al frente)
        entries.removeAll { $0.appPath == appURL.path }
        
        // Crear nueva entrada usando el factory method nonisolated
        let newEntry = RecentAppEntry.create(
            appURL: appURL,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName,
            artifactCount: artifactCount,
            totalSize: totalSize
        )
        
        // Insertar al frente
        entries.insert(newEntry, at: 0)
        
        // Mantener solo las últimas N entradas
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        
        save(entries)
    }
    
    /// Obtiene las apps recientes, filtrando las que ya no existen
    func getRecentApps() async -> [RecentAppEntry] {
        let entries = load()
        
        // Filtrar apps que ya no existen
        let validEntries = entries.filter { $0.appExists }
        
        // Si hubo cambios, guardar la lista limpia
        if validEntries.count != entries.count {
            save(validEntries)
        }
        
        return validEntries
    }
    
    /// Elimina una entrada específica del historial
    func removeEntry(_ id: UUID) async {
        var entries = load()
        entries.removeAll { $0.id == id }
        save(entries)
    }
    
    /// Limpia todo el historial
    func clearHistory() async {
        save([])
    }
    
    /// Verifica si hay entradas en el historial
    func hasEntries() async -> Bool {
        !load().isEmpty
    }
    
    // MARK: - Persistence
    
    private func save(_ entries: [RecentAppEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func load() -> [RecentAppEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([RecentAppEntry].self, from: data) else {
            return []
        }
        return entries
    }
}
