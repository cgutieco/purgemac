//
//  FileSearchService.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import Foundation

// MARK: - File Search Service

actor FileSearchService {
    
    // MARK: - Singleton
    
    static let shared = FileSearchService()
    
    private init() {}
    
    // MARK: - Real Home Directory
    
    private var realHomeDirectory: URL {
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            let homePath = String(cString: home)
            return URL(fileURLWithPath: homePath)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
    
    // MARK: - Search Paths
    
    private static let userLibraryPaths: [(path: String, category: ArtifactCategory)] = [
        ("Application Support", .applicationSupport),
        ("Caches", .caches),
        ("Preferences", .preferences),
        ("Logs", .logs),
        ("Containers", .containers),
        ("Saved Application State", .savedState),
        ("HTTPStorages", .httpStorages),
        ("WebKit", .webKit),
        ("LaunchAgents", .launchAgents),
        ("Cookies", .cookies),
        ("Application Scripts", .applicationSupport),
        ("Group Containers", .containers)
    ]
    
    private static let systemLibraryPaths: [(path: String, category: ArtifactCategory)] = [
        ("Logs/DiagnosticReports", .logs),
        ("Application Support", .applicationSupport),
        ("Caches", .caches),
        ("LaunchAgents", .launchAgents),
        ("LaunchDaemons", .launchAgents),
        ("Preferences", .preferences)
    ]
    
    // MARK: - Main Search Method
    
    func findArtifacts(
        for appURL: URL,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> [AppArtifact] {
        guard let bundle = Bundle(url: appURL) else {
            throw ScanError.invalidApp
        }
        
        let bundleIdentifier = bundle.bundleIdentifier
        let appName = appURL.deletingPathExtension().lastPathComponent
        
        print("🔍 Scanning app: \(appName)")
        print("📦 Bundle ID: \(bundleIdentifier ?? "nil")")
        
        let homeDir = realHomeDirectory
        let userLibraryPath = homeDir.appendingPathComponent("Library")
        
        print("🏠 Real home directory: \(homeDir.path)")
        print("📚 Library path: \(userLibraryPath.path)")
        
        let searchTerms = generateSearchTerms(
            bundleIdentifier: bundleIdentifier,
            appName: appName
        )
        
        print("🔎 Search terms: \(searchTerms)")
        
        var artifacts: [AppArtifact] = []
        
        let appSize = await calculateSize(at: appURL)
        let appArtifact = AppArtifact(
            path: appURL,
            category: .application,
            sizeBytes: appSize,
            isSelected: true
        )
        artifacts.append(appArtifact)
        
        await progressHandler(0.1)
        
        let totalPaths = Double(Self.userLibraryPaths.count)
        
        for (index, searchPath) in Self.userLibraryPaths.enumerated() {
            let categoryPath = userLibraryPath.appendingPathComponent(searchPath.path)
            
            let progress = 0.1 + (Double(index + 1) / totalPaths) * 0.8
            await progressHandler(progress)
            
            print("📂 Searching in: \(categoryPath.path)")
            
            let foundArtifacts = await searchCategory(
                at: categoryPath,
                category: searchPath.category,
                searchTerms: searchTerms
            )
            
            if !foundArtifacts.isEmpty {
                print("  ✓ Found \(foundArtifacts.count) items")
            }
            
            artifacts.append(contentsOf: foundArtifacts)
        }
        
        if let bundleId = bundleIdentifier {
            let prefsPath = userLibraryPath.appendingPathComponent("Preferences")
            let plistArtifacts = await searchPlistFiles(
                at: prefsPath,
                bundleId: bundleId,
                appName: appName
            )
            artifacts.append(contentsOf: plistArtifacts)
        }
        
        let systemLibraryPath = URL(fileURLWithPath: "/Library")
        
        print("📂 Searching in system /Library/...")
        
        for searchPath in Self.systemLibraryPaths {
            let categoryPath = systemLibraryPath.appendingPathComponent(searchPath.path)
            
            print("📂 Searching in: \(categoryPath.path)")
            
            let foundArtifacts = await searchCategory(
                at: categoryPath,
                category: searchPath.category,
                searchTerms: searchTerms
            )
            
            if !foundArtifacts.isEmpty {
                print("  ✓ Found \(foundArtifacts.count) items")
            }
            
            artifacts.append(contentsOf: foundArtifacts)
        }
        
        print("✅ Total found: \(artifacts.count) artifacts")
        
        await progressHandler(1.0)
        
        return artifacts
    }
    
    // MARK: - Search Helpers
    
    private func generateSearchTerms(bundleIdentifier: String?, appName: String) -> [String] {
        var terms: Set<String> = []
        
        terms.insert(appName)
        terms.insert(appName.lowercased())
        terms.insert(appName.replacingOccurrences(of: " ", with: ""))
        terms.insert(appName.replacingOccurrences(of: " ", with: "").lowercased())
        
        if let bundleId = bundleIdentifier {
            terms.insert(bundleId)
            terms.insert(bundleId.lowercased())
            
            let parts = bundleId.split(separator: ".")
            for part in parts {
                let partString = String(part)
                let genericTerms = ["com", "org", "net", "io", "app", "macos", "mac", "ios", "desktop", "application"]
                if !genericTerms.contains(partString.lowercased()) && partString.count > 2 {
                    terms.insert(partString)
                    terms.insert(partString.lowercased())
                }
            }
        }
        
        return Array(terms.filter { !$0.isEmpty })
    }
    
    private func searchCategory(
        at categoryPath: URL,
        category: ArtifactCategory,
        searchTerms: [String]
    ) async -> [AppArtifact] {
        var artifacts: [AppArtifact] = []
        
        let fm = FileManager.default
        
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: categoryPath.path, isDirectory: &isDir), isDir.boolValue else {
            print("  ⚠️ Directory not found: \(categoryPath.path)")
            return []
        }
        
        do {
            let contents = try fm.contentsOfDirectory(
                at: categoryPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            print("  📁 Contents count: \(contents.count)")
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent
                let itemNameLower = itemName.lowercased()
                
                var matched = false
                var matchedTerm = ""
                
                for term in searchTerms {
                    let termLower = term.lowercased()
                    if itemNameLower.contains(termLower) {
                        matched = true
                        matchedTerm = term
                        break
                    }
                }
                
                if matched {
                    let size = await calculateSize(at: itemURL)
                    
                    let artifact = AppArtifact(
                        path: itemURL,
                        category: category,
                        sizeBytes: size,
                        isSelected: true
                    )
                    
                    artifacts.append(artifact)
                    print("    ✅ Match '\(matchedTerm)': \(itemName) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
                }
            }
        } catch {
            print("  ❌ Error reading directory: \(error.localizedDescription)")
        }
        
        return artifacts
    }
    
    private func searchPlistFiles(
        at prefsPath: URL,
        bundleId: String,
        appName: String
    ) async -> [AppArtifact] {
        var artifacts: [AppArtifact] = []
        let fm = FileManager.default
        
        let exactPlistPath = prefsPath.appendingPathComponent("\(bundleId).plist")
        
        if fm.fileExists(atPath: exactPlistPath.path) {
            let size = await calculateSize(at: exactPlistPath)
            let artifact = AppArtifact(
                path: exactPlistPath,
                category: .preferences,
                sizeBytes: size,
                isSelected: true
            )
            artifacts.append(artifact)
            print("  ✅ Found plist: \(bundleId).plist")
        }
        
        do {
            let contents = try fm.contentsOfDirectory(at: prefsPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            let bundleIdLower = bundleId.lowercased()
            let appNameLower = appName.lowercased().replacingOccurrences(of: " ", with: "")
            
            for file in contents where file.pathExtension == "plist" {
                let fileName = file.deletingPathExtension().lastPathComponent.lowercased()
                
                if fileName == bundleIdLower {
                    continue
                }
                
                if fileName.hasPrefix(bundleIdLower) || fileName.contains(appNameLower) {
                    let size = await calculateSize(at: file)
                    let artifact = AppArtifact(
                        path: file,
                        category: .preferences,
                        sizeBytes: size,
                        isSelected: true
                    )
                    artifacts.append(artifact)
                    print("  ✅ Found related plist: \(file.lastPathComponent)")
                }
            }
        } catch {
            // Ignore errors
        }
        
        return artifacts
    }
    
    func calculateSize(at url: URL) async -> Int64 {
        var totalSize: Int64 = 0
        let fm = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if !isDirectory.boolValue {
            do {
                let attributes = try fm.attributesOfItem(atPath: url.path)
                return Int64(attributes[.size] as? UInt64 ?? 0)
            } catch {
                return 0
            }
        }
        
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                
                if resourceValues.isDirectory == false {
                    let fileSize = resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
}

// MARK: - Quick Cache Search

extension FileSearchService {
    func findCacheArtifacts(
        for appURL: URL,
        progressHandler: @escaping @MainActor @Sendable (Double) -> Void
    ) async throws -> [AppArtifact] {
        guard let bundle = Bundle(url: appURL) else {
            throw ScanError.invalidApp
        }
        
        let bundleIdentifier = bundle.bundleIdentifier
        let appName = appURL.deletingPathExtension().lastPathComponent
        
        let searchTerms = generateSearchTerms(
            bundleIdentifier: bundleIdentifier,
            appName: appName
        )
        
        let cachesPath = realHomeDirectory.appendingPathComponent("Library/Caches")
        
        await progressHandler(0.5)
        
        let artifacts = await searchCategory(
            at: cachesPath,
            category: .caches,
            searchTerms: searchTerms
        )
        
        await progressHandler(1.0)
        
        return artifacts
    }
}
