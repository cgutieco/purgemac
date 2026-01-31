//
//  DeletorService.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation
import AppKit

// MARK: - Deletion Record

struct DeletionRecord: Sendable {
    let originalPath: URL
    let trashPath: URL
    let displayName: String
    let timestamp: Date
    let sizeBytes: Int64
}

// MARK: - Deletion Result

struct DeletionResult: Sendable {
    let freedBytes: Int64
    let records: [DeletionRecord]
    let wasPermanent: Bool
}

// MARK: - Deletor Service

actor DeletorService {
    
    // MARK: - Singleton
    
    static let shared = DeletorService()
    
    private init() {}
    
    // MARK: - Undo State
    
    private(set) var lastDeletionRecords: [DeletionRecord] = []
    private(set) var lastDeletionWasPermanent: Bool = false
    
    var canUndo: Bool {
        !lastDeletionRecords.isEmpty && !lastDeletionWasPermanent
    }
    
    // MARK: - Deletion Methods
    
    func moveToTrash(
        artifacts: [AppArtifact],
        progressHandler: @escaping @MainActor @Sendable (Double, String) -> Void
    ) async throws -> DeletionResult {
        var totalFreed: Int64 = 0
        var records: [DeletionRecord] = []
        let total = Double(artifacts.count)
        
        for (index, artifact) in artifacts.enumerated() {
            let progress = Double(index + 1) / total
            await progressHandler(progress, artifact.displayName)
            
            // Verificar si el archivo existe antes de intentar borrarlo
            // Si ya no existe, técnicamente ya está "limpio", así que lo saltamos sin error.
            if !FileManager.default.fileExists(atPath: artifact.path.path) {
                print("⚠️ File already missing, skipping: \(artifact.path.lastPathComponent)")
                continue
            }
            
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: artifact.path, resultingItemURL: &resultingURL)
                totalFreed += artifact.sizeBytes
                
                // Guardar registro para undo
                if let trashURL = resultingURL as URL? {
                    let record = DeletionRecord(
                        originalPath: artifact.path,
                        trashPath: trashURL,
                        displayName: artifact.displayName,
                        timestamp: Date(),
                        sizeBytes: artifact.sizeBytes
                    )
                    records.append(record)
                }
            } catch {
                print("Failed to trash \(artifact.path): \(error)")
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Guardar para undo
        lastDeletionRecords = records
        lastDeletionWasPermanent = false
        
        return DeletionResult(freedBytes: totalFreed, records: records, wasPermanent: false)
    }
    
    func deletePermanently(
        artifacts: [AppArtifact],
        progressHandler: @escaping @MainActor @Sendable (Double, String) -> Void
    ) async throws -> DeletionResult {
        var totalFreed: Int64 = 0
        var errors: [Error] = []
        let total = Double(artifacts.count)
        
        for (index, artifact) in artifacts.enumerated() {
            let progress = Double(index + 1) / total
            await progressHandler(progress, artifact.displayName)
            
            // Verificar si el archivo existe antes de intentar borrarlo
            if !FileManager.default.fileExists(atPath: artifact.path.path) {
                print("⚠️ File already missing, skipping: \(artifact.path.lastPathComponent)")
                continue
            }
            
            do {
                try FileManager.default.removeItem(at: artifact.path)
                totalFreed += artifact.sizeBytes
            } catch {
                errors.append(error)
                print("Failed to delete \(artifact.path): \(error)")
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        
        if totalFreed == 0 && !errors.isEmpty {
            throw ScanError.deletionFailed(message: "No se pudo eliminar ningún archivo")
        }
        
        // Limpiar historial de undo (eliminación permanente no es recuperable)
        lastDeletionRecords = []
        lastDeletionWasPermanent = true
        
        return DeletionResult(freedBytes: totalFreed, records: [], wasPermanent: true)
    }
    
    // MARK: - Undo Methods
    
    /// Restaura archivos desde la papelera a su ubicación original
    func restoreFromTrash(
        progressHandler: @escaping @MainActor @Sendable (Double, String) -> Void
    ) async throws -> Int {
        guard canUndo else { return 0 }
        
        var restoredCount = 0
        let total = Double(lastDeletionRecords.count)
        
        for (index, record) in lastDeletionRecords.enumerated() {
            let progress = Double(index + 1) / total
            await progressHandler(progress, record.displayName)
            
            do {
                // Crear directorio padre si no existe
                let parentDir = record.originalPath.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: parentDir.path) {
                    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                }
                
                // Mover de vuelta desde la papelera
                try FileManager.default.moveItem(at: record.trashPath, to: record.originalPath)
                restoredCount += 1
            } catch {
                print("Failed to restore \(record.displayName): \(error)")
            }
            
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        
        // Limpiar historial después de restaurar
        clearUndoHistory()
        
        return restoredCount
    }
    
    /// Limpia el historial de undo
    func clearUndoHistory() {
        lastDeletionRecords = []
        lastDeletionWasPermanent = false
    }
    
    // MARK: - Validation
    
    func canDelete(artifact: AppArtifact) -> Bool {
        FileManager.default.isDeletableFile(atPath: artifact.path.path)
    }
    
    func filterDeletable(artifacts: [AppArtifact]) -> [AppArtifact] {
        artifacts.filter { canDelete(artifact: $0) }
    }
    
    func findUndeletable(artifacts: [AppArtifact]) -> [AppArtifact] {
        artifacts.filter { !canDelete(artifact: $0) }
    }
}

// MARK: - Batch Operations

extension DeletorService {
    func deleteSelected(
        from artifacts: [AppArtifact],
        permanently: Bool = false,
        progressHandler: @escaping @MainActor @Sendable (Double, String) -> Void
    ) async throws -> DeletionResult {
        let selected = artifacts.filter(\.isSelected)
        
        guard !selected.isEmpty else {
            return DeletionResult(freedBytes: 0, records: [], wasPermanent: permanently)
        }
        
        if permanently {
            return try await deletePermanently(artifacts: selected, progressHandler: progressHandler)
        } else {
            return try await moveToTrash(artifacts: selected, progressHandler: progressHandler)
        }
    }
}
