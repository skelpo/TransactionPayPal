import Transaction
import Foundation
import PayPal

public protocol ExecutablePayment {
    var total: String { get }
    var currency: CurrencyType { get }
    var externalID: String? { get }
}

extension Currency: CurrencyProtocol {
    public init?(rawValue: String) {
        self.init(code: rawValue)
    }
    
    public var rawValue: String {
        return self.code
    }
}

