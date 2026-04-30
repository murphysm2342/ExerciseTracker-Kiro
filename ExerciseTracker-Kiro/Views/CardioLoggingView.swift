import SwiftUI
import SwiftData

struct CardioLoggingView: View {
    @Environment(\.modelContext) private var modelContext

    let user: User
    var date: Date = Date()
    var preselectedMachineType: CardioMachineType?

    @State private var forceManual: Bool = false

    var body: some View {
        if user.preferredCardioSource == .manual || forceManual {
            ManualCardioView(
                viewModel: CardioLoggingViewModel(
                    modelContext: modelContext,
                    user: user,
                    date: date,
                    machineType: preselectedMachineType ?? .treadmill
                )
            )
        } else {
            HealthKitImportView(
                viewModel: CardioLoggingViewModel(
                    modelContext: modelContext,
                    user: user,
                    date: date,
                    machineType: preselectedMachineType ?? .treadmill
                ),
                onFallbackToManual: { forceManual = true }
            )
        }
    }
}
