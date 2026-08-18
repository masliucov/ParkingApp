import MapKit
import SwiftUI

struct ParkingMapView: View {
    @State private var viewModel: ParkingMapViewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var lotBeingBooked: ParkingLot?

    @Environment(\.dismiss) private var dismiss

    private let user: User
    private let environment: AppEnvironment
    private let onSessionStarted: () -> Void

    init(user: User, environment: AppEnvironment, onSessionStarted: @escaping () -> Void) {
        self.user = user
        self.environment = environment
        self.onSessionStarted = onSessionStarted
        _viewModel = State(
            initialValue: ParkingMapViewModel(locationProvider: environment.locationProvider)
        )
    }

    var body: some View {
        map
            .overlay(alignment: .top) { status }
            .overlay(alignment: .bottom) { selection }
            .navigationTitle("Find parking")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.requestLocation()
            }
            .task(id: viewModel.searchKey) {
                await viewModel.loadLots()
            }
            .sheet(item: $lotBeingBooked) { lot in
                StartParkingView(
                    lot: lot,
                    user: user,
                    vehicleService: environment.vehicleService,
                    sessionService: environment.sessionService
                ) {
                    lotBeingBooked = nil
                    onSessionStarted()
                    dismiss()
                }
            }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.lots) { lot in
                Annotation(lot.name, coordinate: lot.coordinate) {
                    Button {
                        viewModel.select(lot)
                    } label: {
                        ParkingLotPin(isSelected: viewModel.selectedLot?.id == lot.id)
                    }
                    .accessibilityLabel("\(lot.name), \(lot.availableSpaces) spaces free")
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    @ViewBuilder
    private var status: some View {
        if viewModel.isLocationDenied {
            banner(
                message: "Turn on location access to see parking near you.",
                actionTitle: "Open Settings",
                action: openSystemSettings
            )
        } else if let locationErrorMessage = viewModel.locationErrorMessage {
            banner(
                message: locationErrorMessage,
                actionTitle: "Try again",
                action: viewModel.requestLocation
            )
        } else if viewModel.isWaitingForLocation {
            banner(message: "Looking for your location…", isBusy: true)
        } else if viewModel.isSearching {
            banner(message: "Looking for parking on nearby streets…", isBusy: true)
        } else if let searchErrorMessage = viewModel.searchErrorMessage {
            banner(message: searchErrorMessage, actionTitle: "Try again", action: retry)
        } else if viewModel.hasNoNearbyParking {
            banner(message: "No street parking found around here.", actionTitle: "Try again", action: retry)
        }
    }

    @ViewBuilder
    private var selection: some View {
        if let lot = viewModel.selectedLot {
            ParkingLotCard(
                lot: lot,
                distance: viewModel.formattedDistance(to: lot),
                onPark: { lotBeingBooked = lot },
                onClose: viewModel.clearSelection
            )
            .padding(Theme.Spacing.medium)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func banner(
        message: String,
        isBusy: Bool = false,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: Theme.Spacing.small) {
            if isBusy {
                ProgressView()
            }

            Text(message)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(Theme.Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous))
        .padding(Theme.Spacing.medium)
    }

    private func retry() {
        Task {
            await viewModel.loadLots()
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ParkingLotPin: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "parkingsign.circle.fill")
            .font(.title)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSelected ? Color.accentColor : Color.secondary)
            .scaleEffect(isSelected ? 1.25 : 1)
            .animation(.spring(duration: 0.2), value: isSelected)
    }
}

private struct ParkingLotCard: View {
    let lot: ParkingLot
    let distance: String?
    let onPark: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text(lot.name)
                    .font(.headline)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
            }

            HStack(spacing: Theme.Spacing.medium) {
                Label("\(lot.formattedHourlyRate) / hour", systemImage: "tag")

                Label(
                    lot.hasSpacesAvailable ? "\(lot.availableSpaces) free" : "Full",
                    systemImage: "car"
                )

                if let distance {
                    Label(distance, systemImage: "location")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button("Park here", action: onPark)
                .buttonStyle(.primary)
                .disabled(!lot.hasSpacesAvailable)
                .padding(.top, Theme.Spacing.extraSmall)
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ParkingMapView(
            user: User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date()),
            environment: AppEnvironment(store: InMemoryKeyValueStore()),
            onSessionStarted: {}
        )
    }
}
