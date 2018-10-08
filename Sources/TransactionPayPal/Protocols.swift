import Foundation
import PayPal

public protocol ExecutablePayment {
    var total: String { get }
    var currency: Currency { get }
    var externalID: String { get }
}

public protocol PaymentCreator {
    var paypal: PayPal.Payment { get }
}
