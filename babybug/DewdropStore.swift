import Foundation
import StoreKit

/// Real-money packs of dewdrops. Each product ID must also be created in App Store Connect as a consumable.
enum DewdropPack: String, CaseIterable, Identifiable {
    case small = "com.mayraju147.babybug.dewdrops1000"
    case medium = "com.mayraju147.babybug.dewdrops3500"
    case large = "com.mayraju147.babybug.dewdrops8500"

    var id: String { rawValue }

    var dewdrops: Int {
        switch self {
        case .small: 1000
        case .medium: 3500
        case .large: 8500
        }
    }

    /// Shown only until the App Store sends the real, local price.
    var fallbackPrice: String {
        switch self {
        case .small: "$2"
        case .medium: "$5"
        case .large: "$10"
        }
    }
}

/// Talks to the App Store: loads the dewdrop packs, buys them, and adds the dewdrops once Apple confirms.
/// It also listens for purchases that finish later, such as "Ask to Buy" when a parent approves on their own phone.
@MainActor
@Observable
final class DewdropStore {
    private(set) var products: [String: Product] = [:]
    private(set) var isBuying = false
    /// A short, friendly note for the grown-up, such as "Waiting for approval".
    var message: String?

    private let inventory: Inventory
    @ObservationIgnored private var updates: Task<Void, Never>?

    init(inventory: Inventory) {
        self.inventory = inventory
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        do {
            let list = try await Product.products(for: DewdropPack.allCases.map(\.rawValue))
            products = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
            if products.isEmpty {
                message = "The dewdrop packs aren't available yet."
            }
        } catch {
            message = "The App Store can't be reached right now. Please try again later."
        }
    }

    func price(of pack: DewdropPack) -> String {
        products[pack.rawValue]?.displayPrice ?? pack.fallbackPrice
    }

    func buy(_ pack: DewdropPack) async {
        guard let product = products[pack.rawValue] else {
            message = "The dewdrop packs aren't available yet."
            return
        }
        isBuying = true
        defer { isBuying = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending:
                message = "Waiting for a grown-up to approve. The dewdrops will arrive once it's approved."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "That didn't work. Please try again."
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        // Only add dewdrops for purchases Apple has signed and that haven't been refunded.
        guard case .verified(let transaction) = result else { return }
        if transaction.revocationDate == nil, let pack = DewdropPack(rawValue: transaction.productID) {
            inventory.earn(pack.dewdrops * transaction.purchasedQuantity)
            message = nil
        }
        await transaction.finish()
    }
}
