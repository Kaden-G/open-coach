import SwiftUI
import SwiftData

// OSS-003: One-tap JSON export of all data

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Export all your workout history, training plans, and settings as a human-readable JSON file. This enables data portability and community forks to build importers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Data Export")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportData() {
        isExporting = true
        errorMessage = nil

        Task {
            do {
                let url = try JSONExporter.export(context: modelContext)
                await MainActor.run {
                    exportURL = url
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
