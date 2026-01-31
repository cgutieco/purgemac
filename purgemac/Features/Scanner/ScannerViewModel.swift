//
//  ScannerViewModel.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import SwiftUI
import Combine

// MARK: - Scan Mode

enum ScanMode: Equatable {
    case full
    case cacheOnly
}

// MARK: - Scanner ViewModel

@MainActor
final class ScannerViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var state: ScanState = .idle
    @Published private(set) var scannedApp: ScannedApp?
    @Published private(set) var currentProgress: Double = 0
    @Published private(set) var statusMessage: StatusMessage = .none
    
    enum StatusMessage: Equatable {
        case none
        case startingScan
        case searchingInCategory(ArtifactCategory)
        case scanningCaches
        case preparingDeletion
        case deletingFile(String)
        
        var localized: String {
            switch self {
            case .none: return ""
            case .startingScan: return L10n.startingScan
            case .searchingInCategory(let cat): return L10n.searchingIn(cat.localizedName)
            case .scanningCaches: return L10n.scanningCaches
            case .preparingDeletion: return L10n.preparingDeletion
            case .deletingFile(let name): return L10n.deletingFile(name)
            }
        }
    }
    
    @Published var artifacts: [AppArtifact] = []
    @Published private(set) var scanMode: ScanMode = .full
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var lastDeletionWasPermanent: Bool = false
    @Published private(set) var lastFreedBytes: Int64 = 0
    
    // MARK: - Computed Properties
    
    var selectedArtifacts: [AppArtifact] {
        artifacts.filter(\.isSelected)
    }
    
    var selectedCount: Int {
        selectedArtifacts.count
    }
    
    var totalCount: Int {
        artifacts.count
    }
    
    var selectedSize: Int64 {
        selectedArtifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    var totalSize: Int64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }
    
    var canDelete: Bool {
        !selectedArtifacts.isEmpty && !state.isLoading
    }
    
    var hasFullDiskAccess: Bool {
        get async {
            await PermissionService.shared.hasFullDiskAccess()
        }
    }
    
    // MARK: - Services
    
    private let fileSearchService = FileSearchService.shared
    private let deletorService = DeletorService.shared
    private let permissionService = PermissionService.shared
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Actions
    
    func scanApp(at url: URL) async {
        guard url.pathExtension.lowercased() == "app" else {
            state = .error(.invalidApp)
            return
        }
        
        guard let app = ScannedApp.from(appURL: url) else {
            state = .error(.invalidApp)
            return
        }
        
        scannedApp = app
        state = .scanning(progress: 0)
        currentProgress = 0
        statusMessage = .startingScan
        
        do {
            let foundArtifacts = try await fileSearchService.findArtifacts(for: url) { [weak self] progress in
                self?.currentProgress = progress
                self?.state = .scanning(progress: progress)
                let catIndex = Int(progress * Double(ArtifactCategory.allCases.count)) % ArtifactCategory.allCases.count
                let category = ArtifactCategory.allCases[catIndex]
                self?.statusMessage = .searchingInCategory(category)
            }
            
            if foundArtifacts.isEmpty {
                state = .error(.noArtifactsFound)
            } else {
                artifacts = foundArtifacts
                scannedApp?.artifacts = foundArtifacts
                
                if let updated = scannedApp {
                    state = .found(updated)
                    // Guardar en historial
                    let appURL = updated.appURL
                    let bundleID = updated.bundleIdentifier
                    let name = updated.displayName
                    let count = updated.artifacts.count
                    let size = updated.totalSize
                    
                    Task { 
                        await HistoryService.shared.addEntry(
                            appURL: appURL,
                            bundleIdentifier: bundleID,
                            displayName: name,
                            artifactCount: count,
                            totalSize: size
                        )
                    }
                }
            }
        } catch let error as ScanError {
            state = .error(error)
        } catch {
            state = .error(.unknownError(message: error.localizedDescription))
        }
    }
    
    func scanCacheOnly(at url: URL) async {
        guard url.pathExtension.lowercased() == "app" else {
            state = .error(.invalidApp)
            return
        }
        
        state = .scanning(progress: 0)
        statusMessage = .scanningCaches
        
        do {
            let cacheArtifacts = try await fileSearchService.findCacheArtifacts(for: url) { [weak self] progress in
                self?.currentProgress = progress
                self?.state = .scanning(progress: progress)
            }
            
            if cacheArtifacts.isEmpty {
                state = .error(.noArtifactsFound)
            } else {
                artifacts = cacheArtifacts
                
                if var app = ScannedApp.from(appURL: url) {
                    app.artifacts = cacheArtifacts
                    scannedApp = app
                    state = .found(app)
                    // Guardar en historial
                    let appURL = app.appURL
                    let bundleID = app.bundleIdentifier
                    let name = app.displayName
                    let count = app.artifacts.count
                    let size = app.totalSize
                    
                    Task { 
                        await HistoryService.shared.addEntry(
                            appURL: appURL,
                            bundleIdentifier: bundleID,
                            displayName: name,
                            artifactCount: count,
                            totalSize: size
                        )
                    }
                }
            }
        } catch let error as ScanError {
            state = .error(error)
        } catch {
            state = .error(.unknownError(message: error.localizedDescription))
        }
    }
    
    func deleteSelected(permanently: Bool = false) async {
        guard canDelete else { return }
        
        state = .deleting(progress: 0)
        currentProgress = 0
        statusMessage = .preparingDeletion
        
        do {
            let result = try await deletorService.deleteSelected(
                from: artifacts,
                permanently: permanently
            ) { [weak self] progress, fileName in
                self?.currentProgress = progress
                self?.state = .deleting(progress: progress)
                self?.statusMessage = .deletingFile(fileName)
            }
            
            // Guardar estado para undo
            lastFreedBytes = result.freedBytes
            lastDeletionWasPermanent = result.wasPermanent
            canUndo = await deletorService.canUndo
            
            state = .success(freedBytes: result.freedBytes)
        } catch let error as ScanError {
            state = .error(error)
        } catch {
            state = .error(.deletionFailed(message: error.localizedDescription))
        }
    }
    
    /// Deshace la última eliminación (solo si fue a papelera)
    func undoLastDeletion() async -> Int {
        guard canUndo else { return 0 }
        
        state = .deleting(progress: 0)
        statusMessage = .preparingDeletion
        
        do {
            let restoredCount = try await deletorService.restoreFromTrash { [weak self] progress, fileName in
                self?.currentProgress = progress
                self?.state = .deleting(progress: progress)
            }
            
            // Limpiar estado de undo
            canUndo = false
            lastDeletionWasPermanent = false
            
            // Volver a idle o re-escanear
            reset()
            
            return restoredCount
        } catch {
            state = .error(.unknownError(message: error.localizedDescription))
            return 0
        }
    }
    
    // MARK: - Selection Actions
    
    func toggleArtifact(_ artifact: AppArtifact) {
        if let index = artifacts.firstIndex(where: { $0.id == artifact.id }) {
            if !artifacts[index].isProtected {
                artifacts[index].isSelected.toggle()
                // Forzar notificación de cambio
                objectWillChange.send()
            }
        }
    }
    
    func toggleArtifactById(_ id: UUID) {
        if let index = artifacts.firstIndex(where: { $0.id == id }) {
            if !artifacts[index].isProtected {
                artifacts[index].isSelected.toggle()
                objectWillChange.send()
            }
        }
    }
    
    func setArtifactSelection(_ id: UUID, selected: Bool) {
        if let index = artifacts.firstIndex(where: { $0.id == id }) {
            if !artifacts[index].isProtected {
                artifacts[index].isSelected = selected
                objectWillChange.send()
            }
        }
    }
    
    func selectAll() {
        for index in artifacts.indices {
            if !artifacts[index].isProtected {
                artifacts[index].isSelected = true
            }
        }
        objectWillChange.send()
    }
    
    func deselectAll() {
        for index in artifacts.indices {
            artifacts[index].isSelected = false
        }
        objectWillChange.send()
    }
    
    func selectCategory(_ category: ArtifactCategory) {
        for index in artifacts.indices where artifacts[index].category == category {
            if !artifacts[index].isProtected {
                artifacts[index].isSelected = true
            }
        }
        objectWillChange.send()
    }
    
    func deselectCategory(_ category: ArtifactCategory) {
        for index in artifacts.indices where artifacts[index].category == category {
            artifacts[index].isSelected = false
        }
        objectWillChange.send()
    }
    
    // MARK: - State Management
    
    func reset() {
        state = .idle
        scannedApp = nil
        artifacts = []
        currentProgress = 0
        statusMessage = .none
        scanMode = .full  // Resetear modo después de cada limpieza
    }
    
    /// Activar modo de solo caché.
    /// Si ya hay una app escaneada, re-escanea automáticamente con solo caché.
    func setCacheOnlyMode() {
        scanMode = .cacheOnly
        
        // Si ya hay una app escaneada, re-escanear con solo caché
        if case .found = state, let app = scannedApp {
            Task {
                await scanCacheOnly(at: app.appURL)
            }
        }
    }
    
    /// Volver a modo de escaneo completo
    func setFullMode() {
        scanMode = .full
    }
    
    func rescan() async {
        guard let app = scannedApp else { return }
        
        switch scanMode {
        case .full:
            await scanApp(at: app.appURL)
        case .cacheOnly:
            await scanCacheOnly(at: app.appURL)
        }
    }
    
    func checkAndRequestPermissions() async -> Bool {
        let hasAccess = await permissionService.hasFullDiskAccess()
        
        if !hasAccess {
            permissionService.openFullDiskAccessSettings()
        }
        
        return hasAccess
    }
}

// MARK: - Environment Key

private struct ScannerViewModelKey: EnvironmentKey {
    static let defaultValue: ScannerViewModel? = nil
}

extension EnvironmentValues {
    var scannerViewModel: ScannerViewModel? {
        get { self[ScannerViewModelKey.self] }
        set { self[ScannerViewModelKey.self] = newValue }
    }
}

// MARK: - Focused Value Key (for menu commands)

struct ScannerViewModelFocusedKey: FocusedValueKey {
    typealias Value = ScannerViewModel
}

extension FocusedValues {
    var scannerViewModel: ScannerViewModel? {
        get { self[ScannerViewModelFocusedKey.self] }
        set { self[ScannerViewModelFocusedKey.self] = newValue }
    }
}
