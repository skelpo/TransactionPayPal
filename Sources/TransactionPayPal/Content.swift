import Vapor

public struct AcceptQueryString: Content {
    public let payerID: String
    public let paymentID: String
}
