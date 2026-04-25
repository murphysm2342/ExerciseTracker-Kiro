import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(UserViewModel.self) private var userViewModel

    var userToEdit: User?

    @State private var name: String = ""
    @State private var colorTag: String = ""
    @State private var showValidationError = false

    @Environment(\.dismiss) private var dismiss

    var isCreating: Bool { userToEdit == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)

                    TextField("Color Tag (e.g. blue, red)", text: $colorTag)
                }

                if showValidationError {
                    Section {
                        Text("Name cannot be empty.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isCreating ? "New Profile" : "Edit Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let user = userToEdit {
                    name = user.name
                    colorTag = user.colorTag ?? ""
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }
        showValidationError = false
        let tag = colorTag.trimmingCharacters(in: .whitespaces)
        let tagValue: String? = tag.isEmpty ? nil : tag

        do {
            if let user = userToEdit {
                try userViewModel.updateUser(user, name: trimmedName, colorTag: tagValue)
            } else {
                try userViewModel.createUser(name: trimmedName, colorTag: tagValue)
                if let created = userViewModel.allUsers.last {
                    userViewModel.selectUser(created)
                }
            }
            dismiss()
        } catch {
            showValidationError = true
        }
    }
}

#Preview {
    EditProfileView()
        .environment(UserViewModel(modelContext: try! ModelContainer(for: User.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
}
