import DatabaseKit
import Transaction
import Foundation
import PayPal

public protocol ExecutablePayment {
    var total: Int { get }
    var currency: String { get }
    var externalID: String? { get }
}

public protocol PayPalPaymentRepresentable {
    func paypal(on conn: DatabaseConnectable) -> Future<PayPal.Payment>
}

extension Currency: CurrencyProtocol {
    public init?(rawValue: String) {
        self.init(code: rawValue)
    }
    
    public var rawValue: String {
        return self.code
    }
}

