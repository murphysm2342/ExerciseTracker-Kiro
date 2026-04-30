import SwiftUI
import SwiftData

struct StrengthLoggingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: StrengthLoggingViewModel

    init(machine: Machine, user: User, session: WorkoutSession, modelContext: ModelContext) {
        _viewModel = State(
            wrappedValue: StrengthLoggingViewModel(
                modelContext: modelContext,
                machine: machine,
                user: user,
                session: session
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.addSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brand.opacity(0.1))
                    .foregroundStyle(Color.brand)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.smallRadius))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.sets.reversed()) { set in
                        SetEditorView(
                            set: set,
                            activeFieldTarget: $viewModel.activeFieldTarget,
                            fieldBuffers: viewModel.fieldBuffers,
                            onActivate: { target in viewModel.activateField(target) },
                            onRepsAdjust: { amount in viewModel.adjustReps(for: set.id, by: amount) },
                            onDelete: viewModel.sets.count > 1 ? { viewModel.deleteSet(set) } : nil
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            NumberPadView { action in
                viewModel.handleNumberPadAction(action)
            }

            Button {
                trySave()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brandGradient)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .navigationTitle(viewModel.machine.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func trySave() {
        do {
            try viewModel.saveSession()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}
