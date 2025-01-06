import SwiftUI
import PassKit
import StripePaymentSheet

class PaymentManager: NSObject, ObservableObject {
    @Published var paymentStatus: PaymentStatus = .ready
    @Published var isLoading = false
    
    private var paymentSheet: PaymentSheet?
    private var paymentIntentClientSecret: String?
    
    enum PaymentStatus {
        case ready
        case processing
        case completed
        case failed
    }
    
    func preparePaymentSheet() {
        isLoading = true
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Benefi"
        configuration.applePay = .init(merchantId: "merchant.benefi", merchantCountryCode: "US")
        configuration.allowsDelayedPaymentMethods = false
        
        self.paymentIntentClientSecret = "pi_3QSJnbL8yY0HPNsk0GHN1BAu_secret_O4rFrI0Yd3qK4LUri73jWoJBJ"
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: "pi_3QSJnbL8yY0HPNsk0GHN1BAu_secret_O4rFrI0Yd3qK4LUri73jWoJBJ",
            configuration: configuration
        )
        
        self.isLoading = false
    }
    
    func presentPaymentSheet(in viewController: UIViewController) {
        guard let paymentSheet = paymentSheet else {
            paymentStatus = .failed
            return
        }
        
        paymentStatus = .processing
        paymentSheet.present(from: viewController) { [weak self] paymentResult in
            switch paymentResult {
            case .completed:
                self?.paymentStatus = .completed
                print("Payment completed successfully")
            case .canceled:
                self?.paymentStatus = .ready
                print("Payment canceled")
            case .failed(let error):
                self?.paymentStatus = .failed
                print("Payment failed: \(error.localizedDescription)")
            }
        }
    }
    
}

struct ApplePayPaymentSheetView: View {
    @StateObject private var paymentManager = PaymentManager()
    
    var body: some View {
        VStack {
            switch paymentManager.paymentStatus {
            case .ready:
                Text("Ready to Pay $10")
                    .foregroundColor(.blue)
            case .processing:
                ProgressView("Processing Payment")
            case .completed:
                Text("Payment Successful!")
                    .foregroundColor(.green)
            case .failed:
                Text("Payment Failed")
                    .foregroundColor(.red)
            }
            
            Button(action: initiatePayment) {
                Text("Pay with Apple Pay")
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(paymentManager.isLoading)
        }
        .onAppear {
            paymentManager.preparePaymentSheet()
        }
    }
    
    private func initiatePayment() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        paymentManager.presentPaymentSheet(in: rootViewController)
    }
}
