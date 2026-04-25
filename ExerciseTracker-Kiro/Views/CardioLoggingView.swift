import SwiftUI
import SwiftData

/// Routes to ManualCardioView or HealthKitImportView based on the user's preferredCardioSource.
/// Requirements: 4.5, 5.2, 5.5
struct CardioLoggingView: View {
    @Environment(\.modelContext) private var modelContext

    let user: User

    /// Tracks whether we've fallen back to manual entry due to a permission denial (Req 5.5)
    @State private var forceManual: Bool = false

    var body: some View {
        if user.preferredCardioSource == .manual || forceManual {
            // Req 4.5 — manual path (also used as fallback from permission denial)
            ManualCardioView(
                viewModel: CardioLoggingViewModel(modelContext: modelContext, user: user)
            )
        } else {
            // Req 5.2 — HealthKit import path
            HealthKitImportView(
                viewModel: CardioLoggingViewModel(modelContext: modelContext, user: user),
                onFallbackToManual: { forceManual = true }
            )
        }
    }
}
