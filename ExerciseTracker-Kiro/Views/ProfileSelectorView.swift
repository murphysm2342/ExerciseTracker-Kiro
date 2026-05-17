import SwiftUI
import SwiftData

struct ProfileSelectorView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss

    /// When false (shown from ContentView with no active user), the Done button is hidden.
    var canDismiss: Bool = true

    @State private var showAddProfile = false
    @State private var userToEdit: User? = nil
    @State private var showOnboarding = false
    @State private var newlyCreatedUser: User? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(userViewModel.allUsers) { user in
                    Button {
                        userViewModel.selectUser(user)
                        if canDismiss { dismiss() }
                    } label: {
                        HStack {
                            colorCircle(for: user.colorTag)
                            Text(user.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if userViewModel.activeUser?.id == user.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            try? userViewModel.deleteUser(user)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            userToEdit = user
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }

                Button {
                    showAddProfile = true
                } label: {
                    Label("Add Profile", systemImage: "plus")
                }
            }
            .navigationTitle("Select Profile")
            .toolbar {
                if canDismiss {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                // After creating a profile, show the machine favorites picker
                EditProfileView(onCreated: { user in
                    showAddProfile = false
                    newlyCreatedUser = user
                    // Delay briefly to ensure the first sheet dismisses before showing the next
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showOnboarding = true
                    }
                })
            }
            .sheet(item: $userToEdit) { user in
                EditProfileView(userToEdit: user)
            }
            .sheet(isPresented: $showOnboarding, onDismiss: {
                newlyCreatedUser = nil
            }) {
                if let user = newlyCreatedUser {
                    OnboardingSetupView(user: user) {
                        showOnboarding = false
                    }
                    .interactiveDismissDisabled()
                }
            }
        }
    }

    @ViewBuilder
    private func colorCircle(for colorTag: String?) -> some View {
        Circle()
            .fill(color(for: colorTag))
            .frame(width: 12, height: 12)
    }

    private func color(for tag: String?) -> Color {
        switch tag?.lowercased() {
        case "red":    return .red
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink":   return .pink
        default:       return .gray
        }
    }
}

#Preview {
    ProfileSelectorView()
        .environment(UserViewModel(modelContext: try! ModelContainer(
            for: User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ).mainContext))
}
