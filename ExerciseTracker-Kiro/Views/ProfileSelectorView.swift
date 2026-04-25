import SwiftUI
import SwiftData

struct ProfileSelectorView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddProfile = false
    @State private var userToEdit: User? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(userViewModel.allUsers) { user in
                    Button {
                        userViewModel.selectUser(user)
                        dismiss()
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
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                EditProfileView()
            }
            .sheet(item: $userToEdit) { user in
                EditProfileView(userToEdit: user)
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
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        default: return .gray
        }
    }
}

#Preview {
    ProfileSelectorView()
        .environment(UserViewModel(modelContext: try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
