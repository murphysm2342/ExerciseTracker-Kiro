import SwiftUI
import SwiftData

/// Shows all sets for a machine simultaneously with a custom NumberPad at the bottom.
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.7, 3.8
struct StrengthLoggingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: StrengthLoggingViewModel

    init(machine: Machine, user: User, modelContext: ModelContext) {
        _viewModel = State(
            wrappedValue: StrengthLoggingViewModel(
                modelContext: modelContext,
                machine: machine,
                user: user
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sets list (Req 3.1 — all sets visible simultaneously)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sets) { set in
                        SetEditorView(
                            set: set,
                            activeFieldTarget: $viewModel.activeFieldTarget,
                            fieldBuffers: viewModel.fieldBuffers,
                            onComplete: { viewModel.completeSet(set) }
                        )
                        .padding(.horizontal)
                    }

                    // Add Set button
                    Button {
                        viewModel.addSet()
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)
            }

            Divider()

            // NumberPad always visible at bottom (Req 3.2, 10.1)
            NumberPadView { action in
                viewModel.handleNumberPadAction(action)
            }

            // Save button
            Button {
                trySave()
            } label: {
                Text("Save Session")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .navigationTitle(viewModel.sets.first?.machine.name ?? "Strength")
        .navigationBarTitleDisplayMode(.inline)
        // Suppress system keyboard (Req 3.3, 10.2) — no TextField is ever focused
        .confirmationDialog(
            "No completed sets",
            isPresented: $viewModel.requiresConfirmation,
            titleVisibility: .visible
        ) {
            Button("Save Anyway") {
                try? viewModel.confirmSave()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You haven't marked any sets as completed. Save anyway?")
        }
    }

    private func trySave() {
        do {
            try viewModel.saveSession()
            // If requiresConfirmation was set, the dialog handles the rest
            if !viewModel.requiresConfirmation {
                dismiss()
            }
        } catch {
            // In a production app we'd show an alert; for now just print
            print("Save failed: \(error)")
        }
    }
}
