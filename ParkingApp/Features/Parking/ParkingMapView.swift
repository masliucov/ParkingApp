import MapKit
import SwiftUI

struct ParkingMapView: View {
    @State private var viewModel: ParkingMapViewModel
    /// Lives here because the balance is shown here, and every screen that spends it is
    /// opened from this one.
    @State private var wallet: WalletViewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var lotBeingBooked: ParkingLot?
    @State private var sessionBeingExtended: ParkingSession?
    @State private var sessionBeingEnded: ParkingSession?
    @State private var isAddingFunds = false

    @Binding private var lotToShow: ParkingLot?

    private let user: User
    private let environment: AppEnvironment
    private let activeParking: ActiveParkingViewModel

    init(
        user: User,
        environment: AppEnvironment,
        activeParking: ActiveParkingViewModel,
        lotToShow: Binding<ParkingLot?>
    ) {
        self.user = user
        self.environment = environment
        self.activeParking = activeParking
        _lotToShow = lotToShow
        _viewModel = State(
            initialValue: ParkingMapViewModel(
                locationProvider: environment.locationProvider,
                sessionService: environment.sessionService,
                userID: user.id
            )
        )
        _wallet = State(
            initialValue: WalletViewModel(service: environment.walletService, userID: user.id)
        )
    }

    var body: some View {
        map
            .overlay(alignment: .top) { status }
            .overlay(alignment: .bottom) { bottomCard }
            .navigationTitle("Find parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    WalletBalanceButton(formattedBalance: wallet.formattedBalance) {
                        isAddingFunds = true
                    }
                }
            }
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by code or street"
            )
            .autocorrectionDisabled()
            .onChange(of: viewModel.query) {
                // The card would otherwise outlive the pin the search just hid.
                viewModel.clearSelection()
            }
            .onChange(of: lotToShow) { _, lot in
                guard let lot else { return }
                show(lot)
            }
            .task {
                viewModel.requestLocation()
                viewModel.loadKnownLots()
                wallet.load()
            }
            .onChange(of: activeParking.activeSessions) {
                // A stay that just started or ended may have added a spot worth searching.
                viewModel.loadKnownLots()
            }
            .task(id: viewModel.searchKey) {
                await viewModel.loadLots()
            }
            .sheet(isPresented: $isAddingFunds) {
                AddFundsView(wallet: wallet)
            }
            .sheet(item: $lotBeingBooked) { lot in
                StartParkingView(
                    lot: lot,
                    user: user,
                    vehicleService: environment.vehicleService,
                    sessionService: environment.sessionService,
                    wallet: wallet
                ) {
                    lotBeingBooked = nil
                    viewModel.clearSelection()
                    wallet.load()
                    Task { await activeParking.refresh() }
                }
            }
            .sheet(item: $sessionBeingExtended) { session in
                AddTimeView(
                    session: session,
                    sessionService: environment.sessionService,
                    wallet: wallet
                ) {
                    sessionBeingExtended = nil
                    wallet.load()
                    Task { await activeParking.refresh() }
                }
            }
            .confirmationDialog(
                "End parking now?",
                isPresented: isConfirmingEnd,
                titleVisibility: .visible,
                presenting: sessionBeingEnded
            ) { session in
                Button("End parking", role: .destructive) {
                    sessionBeingEnded = nil
                    Task { await activeParking.end(session) }
                }
                Button("Cancel", role: .cancel) {
                    sessionBeingEnded = nil
                }
            } message: { session in
                Text("\(session.vehicle.licensePlate) frees the spot now. Time already paid for is not refunded.")
            }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.visibleLots) { lot in
                Annotation(lot.code, coordinate: lot.coordinate) {
                    Button {
                        viewModel.select(lot)
                    } label: {
                        ParkingLotPin(
                            isSelected: viewModel.selectedLot?.id == lot.id,
                            parkedCount: viewModel.parkedCount(at: lot)
                        )
                    }
                    .accessibilityLabel(accessibilityLabel(for: lot))
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
        } else if let parkingErrorMessage = activeParking.errorMessage {
            banner(
                message: parkingErrorMessage,
                actionTitle: "OK",
                action: activeParking.dismissError
            )
        } else if let walletErrorMessage = wallet.errorMessage {
            banner(
                message: walletErrorMessage,
                actionTitle: "OK",
                action: wallet.dismissError
            )
        } else if viewModel.hasNoMatches {
            banner(message: "No parking here matches “\(viewModel.query)”.", actionTitle: "Clear") {
                viewModel.query = ""
            }
        }
    }

    /// A tapped spot wins the bottom of the screen: it is what the driver just asked for,
    /// and the countdown comes back the moment the card is closed.
    @ViewBuilder
    private var bottomCard: some View {
        if let lot = viewModel.selectedLot {
            ParkingLotCard(
                lot: lot,
                distance: viewModel.formattedDistance(to: lot),
                onPark: { lotBeingBooked = lot },
                onClose: viewModel.clearSelection
            )
            .padding(Theme.Spacing.medium)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if !activeParking.activeSessions.isEmpty {
            ActiveParkingOverlay(
                sessions: activeParking.activeSessions,
                onAddTime: { sessionBeingExtended = $0 },
                onEnd: { session in
                    // Move to the spot first, so the pin being freed is under the dialog
                    // rather than somewhere off screen.
                    focusCamera(on: session.lot)
                    sessionBeingEnded = session
                }
            )
            .padding(.vertical, Theme.Spacing.medium)
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

    /// Opens a spot arriving from the history. It is almost certainly not among what the
    /// map just found nearby, so the search is cleared and the camera goes to it.
    private func show(_ lot: ParkingLot) {
        viewModel.query = ""
        viewModel.select(lot)
        focusCamera(on: lot)
        lotToShow = nil
    }

    private func focusCamera(on lot: ParkingLot) {
        withAnimation {
            cameraPosition = .region(ParkingMapCamera.region(focusing: lot))
        }
    }

    private func retry() {
        Task {
            await viewModel.loadLots()
        }
    }

    private func accessibilityLabel(for lot: ParkingLot) -> String {
        let base = "\(lot.name), code \(lot.code), \(lot.availableSpaces) spaces free"
        let parked = viewModel.parkedCount(at: lot)

        guard parked > 0 else { return base }
        return "\(base). \(parked) of your cars parked here."
    }

    private var isConfirmingEnd: Binding<Bool> {
        Binding(
            get: { sessionBeingEnded != nil },
            set: { isPresented in
                if !isPresented { sessionBeingEnded = nil }
            }
        )
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ParkingLotPin: View {
    let isSelected: Bool
    /// How many of the driver's cars are in this spot. Above zero the pin turns green.
    let parkedCount: Int

    private var isOccupied: Bool {
        parkedCount > 0
    }

    var body: some View {
        Image(systemName: "parkingsign.circle.fill")
            .font(.title)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, tint)
            .scaleEffect(isSelected ? 1.25 : 1)
            .animation(.spring(duration: 0.2), value: isSelected)
            .overlay(alignment: .topTrailing) {
                if isOccupied {
                    countBadge
                }
            }
    }

    /// Green wins over the selection colour: where your car is matters more than which pin
    /// you last tapped, and the tap already shows in the size.
    private var tint: Color {
        if isOccupied { return .green }
        return isSelected ? Color.accentColor : Color.secondary
    }

    private var countBadge: some View {
        Text("\(parkedCount)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(minWidth: 16, minHeight: 16)
            .background(Circle().fill(.green))
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
            .offset(x: 5, y: -5)
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
                VStack(alignment: .leading, spacing: Theme.Spacing.extraSmall) {
                    Text(lot.name)
                        .font(.headline)

                    Text("Code \(lot.code)")
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                }

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
    let user = User(id: UUID(), name: "Ana Silva", email: "ana@example.com", createdAt: Date())
    let environment = AppEnvironment(store: InMemoryKeyValueStore())

    return NavigationStack {
        ParkingMapView(
            user: user,
            environment: environment,
            activeParking: ActiveParkingViewModel(
                sessionService: environment.sessionService,
                notifications: environment.notifications,
                userID: user.id
            ),
            lotToShow: .constant(nil)
        )
    }
}
