import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportData: Data?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let backupService = DataBackupService()

    var body: some View {
        Form {
            Section {
                Text("Export your workout data as a JSON file you can save, share, or use to restore later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    exportBackup()
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: "square.and.arrow.up", color: .brand, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Data")
                                .fontWeight(.medium)
                            Text("Save all profiles, machines, and workouts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Export")
            }
            .listRowBackground(Color.cardBackground)

            Section {
                Text("Import data from a previously exported backup file. Existing profiles will not be duplicated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    isImporting = true
                } label: {
                    HStack(spacing: 12) {
                        IconBadge(systemName: "square.and.arrow.down", color: .green, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Data")
                                .fontWeight(.medium)
                            Text("Restore from a backup file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Import")
            }
            .listRowBackground(Color.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceLight)
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: exportData.map { JSONBackupDocument(data: $0) },
            contentType: .json,
            defaultFilename: "ExerciseTracker-Backup-\(dateStamp).json"
        ) { result in
            switch result {
            case .success:
                alertTitle = "Export Complete"
                alertMessage = "Your data has been saved successfully."
                showAlert = true
            case .failure(let error):
                alertTitle = "Export Failed"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func exportBackup() {
        do {
            exportData = try backupService.exportAllData(modelContext: modelContext)
            isExporting = true
        } catch {
            alertTitle = "Export Failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                alertTitle = "Import Failed"
                alertMessage = "Could not access the selected file."
                showAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let count = try backupService.importAllData(from: data, modelContext: modelContext)
                alertTitle = "Import Complete"
                alertMessage = count > 0
                    ? "Imported \(count) profile\(count == 1 ? "" : "s") successfully."
                    : "No new profiles to import. All profiles in the backup already exist."
                showAlert = true
            } catch {
                alertTitle = "Import Failed"
                alertMessage = "Could not read backup file: \(error.localizedDescription)"
                showAlert = true
            }

        case .failure(let error):
            alertTitle = "Import Failed"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - FileDocument wrapper for export

struct JSONBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
