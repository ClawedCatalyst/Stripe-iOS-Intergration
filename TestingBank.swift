import SwiftUI
import StripeFinancialConnections
import Combine
import StripePaymentSheet

// ViewModel that handles fetching the LinkToken and managing the Financial Connections flow
class BankAccountViewModel: ObservableObject {
    @Published var linkToken: String?
    @Published var customerID = "cus_xxx"  // Replace with the actual Stripe customer ID
    @Published var accountId: String?
    @Published var cardSetupClientSecret: String?
    
    // Method to fetch the LinkToken from your backend
    func fetchLinkToken() {
        guard let url = URL(string: "https://012a-2409-40e3-1b-7dfb-ed8e-5b56-48a-3479.ngrok-free.app/api/payment/stripe/create-setup-intent") else { return }
        
        // Create the request with the customer_id
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        // Perform the request to get the LinkToken
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching LinkToken: \(error?.localizedDescription ?? "")")
                return
            }
            
            // Parse the response
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let linkToken = json["clientSecret"] as? String {
                DispatchQueue.main.async {
                    self.linkToken = linkToken
                }
            } else {
                print("Invalid response or missing linkToken")
            }
        }
        
        task.resume()
    }
    
    // Method to initiate the Financial Connections flow
    func startFinancialConnectionsFlow() {
        guard let linkToken = linkToken else {
            print("LinkToken is not available")
            return
        }
        
        let financialConnectionsSheet = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: linkToken)
        
        // Ensure rootViewController is available before presenting
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
            print("Root view controller is not available")
            return
        }
        
        // Present the Financial Connections flow
        financialConnectionsSheet.present(from: rootViewController) { result in
            switch result {
            case .completed(let session):
                // Access the first account ID from the session's account data
                if let accountId = session.accounts.data.first?.id {
                    DispatchQueue.main.async {
                        self.accountId = accountId
                    }
                    print("Bank account connected: \(accountId)")
                }
            case .canceled:
                print("Financial Connections flow canceled")
            case .failed(let error):
                print("Failed to connect bank account: \(error.localizedDescription)")
            }
        }
    }
    
    //step to add a card
    func fetchSetupIntent() {
        guard let url = URL(string: "https://ceb1-103-19-152-138.ngrok-free.app/api/payment/stripe/create-setup-intent") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        

        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching SetupIntent: \(error?.localizedDescription ?? "")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let clientSecret = json["clientSecret"] as? String {
                DispatchQueue.main.async {
                    self.cardSetupClientSecret = clientSecret
                    var config = PaymentSheet.Configuration()
                    config.allowsDelayedPaymentMethods = true 
                    let paymentSheet = PaymentSheet(setupIntentClientSecret: clientSecret, configuration: config)
                    
                    guard let rootViewController = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
                        print("Root view controller is not available")
                        return
                    }
                    
                    paymentSheet.present(from: rootViewController) { result in
                        switch result {
                        case .completed:
                            print("Card successfully added and saved!")
                        case .canceled:
                            print("Card entry was canceled.")
                        case .failed(let error):
                            print("Failed to add card: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                print("Invalid response or missing clientSecret")
            }
        }
        task.resume()
    }
    
    // Present card input and save the card
    func addCard() {
        guard let clientSecret = cardSetupClientSecret else {
            print("SetupIntent client secret is not available")
            return
        }
        
        let config = PaymentSheet.Configuration()
        let paymentSheet = PaymentSheet(setupIntentClientSecret: self.cardSetupClientSecret ?? "nothing", configuration: config)
        
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
            print("Root view controller is not available")
            return
        }
        
        paymentSheet.present(from: rootViewController) { result in
            switch result {
            case .completed:
                print("Card successfully added and saved!")
            case .canceled:
                print("Card entry was canceled.")
            case .failed(let error):
                print("Failed to add card: \(error.localizedDescription)")
            }
        }
    }
}

struct ConnectBankAccountView: View {
    @StateObject private var viewModel = BankAccountViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect your bank account")
                .font(.title)
                .padding()
            
            // Fetch the link token when the button is pressed
            Button(action: {
                viewModel.fetchLinkToken()
            }) {
                Text("Fetch Link Token")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // If the link token is available, allow the user to connect their bank account
            if viewModel.linkToken != nil {
                Button(action: {
                    viewModel.startFinancialConnectionsFlow()
                }) {
                    Text("Connect Bank Account")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Display the connected account ID if available
            if let accountId = viewModel.accountId {
                Text("Connected Bank Account ID: \(accountId)")
                    .padding()
                    .foregroundColor(.green)
            }
        }
        .padding()
        
        Button(action: {
            viewModel.fetchSetupIntent()
//            viewModel.addCard()
        }) {
            Text("Add Card")
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
        }.padding()
        
        // Display the connected account ID if available
        if let accountId = viewModel.accountId {
            Text("Connected Bank Account ID: \(accountId)")
                .padding()
                .foregroundColor(.green)
        }
    }
}

// Preview for SwiftUI
struct ConnectBankAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectBankAccountView()
    }
}


