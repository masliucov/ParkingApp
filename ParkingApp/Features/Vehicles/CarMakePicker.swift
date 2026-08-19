import SwiftUI

/// Picks a car brand from the full list, with a search field for the drivers who already
/// know what they drive and would rather type three letters than scroll.
struct CarMakePicker: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""

    private var matches: [String] {
        CarMake.matching(query)
    }

    var body: some View {
        NavigationStack {
            List(matches, id: \.self) { make in
                Button {
                    selection = make
                    dismiss()
                } label: {
                    HStack {
                        Text(make)
                            .foregroundStyle(.primary)
                        Spacer()
                        if make == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityAddTraits(make == selection ? .isSelected : [])
            }
            .listStyle(.plain)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search brands"
            )
            .autocorrectionDisabled()
            .overlay {
                if matches.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Car brand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = "Renault"

    return CarMakePicker(selection: $selection)
}
