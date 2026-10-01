import XCTest
@testable import AutoDealerPro

final class DealerTests: XCTestCase {
    func testMoneyUsesExactCents() throws {
        XCTAssertEqual(try Money.parse("12500,50"), 1_250_050)
        XCTAssertEqual(try Money.parse("0.01"), 1)
        XCTAssertEqual(try Money.parse("19,9"), 1990)
        XCTAssertEqual(try Money.parse(Money.input(98765)), 98765)
        XCTAssertThrowsError(try Money.parse("1.234,56"))
        XCTAssertThrowsError(try Money.parse("-10"))
        XCTAssertThrowsError(try Money.parse("NaN"))
        XCTAssertThrowsError(try Money.parse("1,234"))
    }
    func testMarginIncludesAllCosts() {
        var v = Vehicle(); v.purchaseCents = 1_000_000; v.saleCents = 1_350_000
        v.expenses = [Expense(label: "Service", cents: 45000), Expense(label: "Transport", cents: 15000)]
        XCTAssertEqual(v.investment, 1_060_000); XCTAssertEqual(v.margin, 290_000)
    }
    func testSoldVehicleNeedsRealBuyerAndDate() throws {
        var v = Vehicle(); v.name = "Testwagen"; v.status = .sold
        XCTAssertThrowsError(try v.validate(customers: []))
        var buyer = Customer(); buyer.name = "Käufer"
        v.customerID = buyer.id; v.saleDate = Date()
        try v.validate(customers: [buyer])
        XCTAssertThrowsError(try v.validate(customers: []))
    }
    func testSnapshotRoundTripPreservesFinancialData() throws {
        var s = Snapshot(); var v = Vehicle(); v.name = "Audi Q5"; v.purchaseCents = 1234567; v.saleCents = 1543210
        s.vehicles = [v]
        let restored = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(restored.vehicles[0], v)
    }
    func testBackupRoundTripPreservesPhotoBytes() throws {
        let id = UUID(); let bytes = Data([0, 1, 2, 255])
        let backup = Backup(snapshot: Snapshot(), photos: [id.uuidString: bytes])
        let decoded = try JSONDecoder().decode(Backup.self, from: JSONEncoder().encode(backup))
        XCTAssertEqual(decoded.photos[id.uuidString], bytes)
    }
}
