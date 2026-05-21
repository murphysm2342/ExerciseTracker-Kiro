import SwiftUI
import SwiftData

struct OnboardingSetupView: View {
    @Environment(\.modelContext) private var modelContext

    let user: User
    let onComplete: () -> Void

    @State private var step: OnboardingStep = .categories
    @State private var wantsStrengthMachines = false
    @State private var wantsFreeWeights = false
    @State private var wantsCardio = false
    @State private var selectedMachineIds: Set<UUID> = []
    @State private var selectedFreeWeightIds: Set<UUID> = []
    @State private var selectedCardioTypes: Set<String> = []

    private enum OnboardingStep: Equatable {
        case categories
        case strengthMachines
        case freeWeights
        case cardio
        case done
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                Group {
                    switch step {
                    case .categories:
                        categoryPickerView
                    case .strengthMachines:
                        strengthMachinesView
                    case .freeWeights:
                        freeWeightsView
                    case .cardio:
                        cardioOverviewView
                    case .done:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer(minLength: 0)

                nextButton
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        finishOnboarding()
                    }
                }
            }
        }
    }

    // MARK: - Progress

    private var totalSteps: Int {
        var count = 1
        if wantsStrengthMachines { count += 1 }
        if wantsFreeWeights { count += 1 }
        if wantsCardio { count += 1 }
        return count
    }

    private var currentStepIndex: Int {
        switch step {
        case .categories: return 0
        case .strengthMachines:
            return 1
        case .freeWeights:
            return (wantsStrengthMachines ? 2 : 1)
        case .cardio:
            var idx = 1
            if wantsStrengthMachines { idx += 1 }
            if wantsFreeWeights { idx += 1 }
            return idx
        case .done: return totalSteps
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brand.opacity(0.15))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brand)
                    .frame(width: geo.size.width * CGFloat(currentStepIndex) / CGFloat(max(totalSteps - 1, 1)), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var stepTitle: String {
        switch step {
        case .categories: return "Set Up Your Workouts"
        case .strengthMachines: return "Strength Machines"
        case .freeWeights: return "Free Weights"
        case .cardio: return "Cardio"
        case .done: return ""
        }
    }

    // MARK: - Step 1: Category Picker

    private var categoryPickerView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("What types of exercises do you do?")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("We'll help you set up favorites for each. You can always change this later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    categoryCard(
                        title: "Strength Machines",
                        subtitle: "Gym machines like chest press, leg press, lat pulldown",
                        icon: "dumbbell.fill",
                        color: .strengthAccent,
                        isSelected: $wantsStrengthMachines
                    )
                    categoryCard(
                        title: "Free Weights",
                        subtitle: "Dumbbells, cables, and Smith machine exercises",
                        icon: "figure.strengthtraining.traditional",
                        color: .orange,
                        isSelected: $wantsFreeWeights
                    )
                    categoryCard(
                        title: "Cardio",
                        subtitle: "Treadmill, elliptical, stair stepper, bike, rowing",
                        icon: "heart.fill",
                        color: .cardioAccent,
                        isSelected: $wantsCardio
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }

    private func categoryCard(title: String, subtitle: String, icon: String, color: Color, isSelected: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isSelected.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected.wrappedValue ? Color.brand : .secondary)
            }
            .padding(DesignTokens.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .strokeBorder(isSelected.wrappedValue ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Strength Machines

    private var strengthMachines: [Machine] {
        let machineNames = Set(MachineCatalogService.defaultMachines.map(\.name))
        return user.machines
            .filter { machineNames.contains($0.name) }
            .sorted { $0.name < $1.name }
    }

    private var strengthMachinesView: some View {
        VStack(spacing: 0) {
            Text("Star the exercises you use most. They'll appear first when logging workouts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 12)

            List {
                let grouped = groupedByCategory(strengthMachines)
                ForEach(grouped, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.machines) { machine in
                            favoriteRow(machine: machine, selectedIds: $selectedMachineIds)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Step 3: Free Weights

    private var freeWeightMachines: [Machine] {
        let freeWeightNames = Set(MachineCatalogService.freeWeightExercises.map(\.name))
        return user.machines
            .filter { freeWeightNames.contains($0.name) }
            .sorted { $0.name < $1.name }
    }

    private var freeWeightsView: some View {
        VStack(spacing: 0) {
            Text("Select the free weight exercises you do regularly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical, 12)

            List {
                let grouped = groupedByCategory(freeWeightMachines)
                ForEach(grouped, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.machines) { machine in
                            favoriteRow(machine: machine, selectedIds: $selectedFreeWeightIds)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Step 4: Cardio

    private var cardioOverviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Star your favorite cardio activities")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Favorites appear first when logging workouts. You can change this later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(CardioMachineType.allCases) { type in
                        Button {
                            if selectedCardioTypes.contains(type.rawValue) {
                                selectedCardioTypes.remove(type.rawValue)
                            } else {
                                selectedCardioTypes.insert(type.rawValue)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: type.iconName)
                                    .font(.title2)
                                    .foregroundStyle(Color.brand)
                                    .frame(width: 36)
                                Text(type.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: selectedCardioTypes.contains(type.rawValue) ? "star.fill" : "star")
                                    .foregroundStyle(selectedCardioTypes.contains(type.rawValue) ? .yellow : .secondary)
                                    .font(.title3)
                            }
                            .padding(DesignTokens.cardPadding)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                                    .fill(Color.cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }

    // MARK: - Shared Components

    private func favoriteRow(machine: Machine, selectedIds: Binding<Set<UUID>>) -> some View {
        Button {
            if selectedIds.wrappedValue.contains(machine.id) {
                selectedIds.wrappedValue.remove(machine.id)
            } else {
                selectedIds.wrappedValue.insert(machine.id)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(machine.name)
                        .foregroundStyle(.primary)
                    if let cat = machine.category {
                        Text(cat)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: selectedIds.wrappedValue.contains(machine.id) ? "star.fill" : "star")
                    .foregroundStyle(selectedIds.wrappedValue.contains(machine.id) ? .yellow : .secondary)
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
    }

    private struct CategoryGroup {
        let category: String
        let machines: [Machine]
    }

    private func groupedByCategory(_ machines: [Machine]) -> [CategoryGroup] {
        var order: [String] = []
        var dict: [String: [Machine]] = [:]
        for machine in machines {
            let cat = machine.category ?? "Other"
            if dict[cat] == nil {
                order.append(cat)
                dict[cat] = []
            }
            dict[cat]!.append(machine)
        }
        return order.sorted().map { CategoryGroup(category: $0, machines: dict[$0]!) }
    }

    // MARK: - Navigation

    private var nextButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                advanceStep()
            }
        } label: {
            Text(step == lastContentStep ? "Get Started" : "Next")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.brandGradient)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.buttonRadius))
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .disabled(step == .categories && !wantsStrengthMachines && !wantsFreeWeights && !wantsCardio)
    }

    private var lastContentStep: OnboardingStep {
        if wantsCardio { return .cardio }
        if wantsFreeWeights { return .freeWeights }
        if wantsStrengthMachines { return .strengthMachines }
        return .categories
    }

    private func advanceStep() {
        switch step {
        case .categories:
            if wantsFreeWeights {
                MachineCatalogService.seedFreeWeights(for: user, modelContext: modelContext)
            }
            if wantsStrengthMachines {
                step = .strengthMachines
            } else if wantsFreeWeights {
                step = .freeWeights
            } else if wantsCardio {
                step = .cardio
            } else {
                finishOnboarding()
            }

        case .strengthMachines:
            saveFavorites(ids: selectedMachineIds)
            if wantsFreeWeights {
                step = .freeWeights
            } else if wantsCardio {
                step = .cardio
            } else {
                finishOnboarding()
            }

        case .freeWeights:
            saveFavorites(ids: selectedFreeWeightIds)
            if wantsCardio {
                step = .cardio
            } else {
                finishOnboarding()
            }

        case .cardio:
            finishOnboarding()

        case .done:
            break
        }
    }

    private func saveFavorites(ids: Set<UUID>) {
        for machine in user.machines where ids.contains(machine.id) {
            machine.isFavorite = true
        }
        try? modelContext.save()
    }

    private func finishOnboarding() {
        saveFavorites(ids: selectedMachineIds)
        saveFavorites(ids: selectedFreeWeightIds)
        if !selectedCardioTypes.isEmpty {
            user.favoriteCardioTypes = Array(selectedCardioTypes)
            try? modelContext.save()
        }
        step = .done
        onComplete()
    }
}
