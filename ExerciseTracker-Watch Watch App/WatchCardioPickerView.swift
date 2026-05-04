import SwiftUI

struct WatchCardioPickerView: View {
    var body: some View {
        List {
            ForEach(WatchCardioType.allCases) { type in
                NavigationLink {
                    WatchCardioLoggerView(machineType: type)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: type.iconName)
                            .font(.body)
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        Text(type.displayName)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Cardio")
    }
}
