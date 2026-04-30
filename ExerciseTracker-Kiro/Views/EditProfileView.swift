import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.dismiss) private var dismiss

    var userToEdit: User?
    /// Called after a new profile is successfully created (not used when editing). (#13)
    var onCreated: ((User) -> Void)? = nil

    @State private var name: String = ""
    @State private var colorTag: String = ""
    @State private var showValidationError = false

    private let colorOptions = ["red", "blue", "green", "orange", "purple", "yellow", "pink", "gray"]

    var isCreating: Bool { userToEdit == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)

                    Picker("Color", selection: $colorTag) {
                        Text("None").tag("")
                        ForEach(colorOptions, id: \.self) { option in
                            HStack {
                                Circle()
                                    .fill(color(for: option))
                                    .frame(width: 12, height: 12)
                                Text(option.capitalized)
                            }
                            .tag(option)
                        }
                    }
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
                    Button("Save") { save() }
                }
                if !isCreating {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
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
        let tagValue: String? = colorTag.isEmpty ? nil : colorTag

        do {
            if let user = userToEdit {
                try userViewModel.updateUser(user, name: trimmedName, colorTag: tagValue)
                dismiss()
            } else {
                // Create user (which now handles seeding and selection internally)
                try userViewModel.createUser(name: trimmedName, colorTag: tagValue)
                // Notify parent that user was created
                if let created = userViewModel.activeUser {
                    print("🔵 Created user: \(created.name)")
                    onCreated?(created)
                    // Don't dismiss - parent will handle the flow
                }
            }
        } catch {
            print("❌ Failed to create/update user: \(error)")
            showValidationError = true
        }
    }

    private func color(for tag: String) -> Color {
        switch tag.lowercased() {
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
    EditProfileView()
        .environment(UserViewModel(modelContext: try! ModelContainer(
            for: User.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ).mainContext))
}
