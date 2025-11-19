import Foundation
import SharedTypes

@MainActor
class Core: ObservableObject {
    @Published var view: ViewModel
    
    init() {
        // Call the top-level view() function from the generated FFI
        let viewData = Thiccc.view()
        self.view = try! .bincodeDeserialize(input: [UInt8](viewData))
    }
    
    func update(_ event: Event) {
        let effects = [UInt8](processEvent(Data(try! event.bincodeSerialize())))
        
        let requests: [Request] = try! .bincodeDeserialize(input: effects)
        for request in requests {
            processEffect(request)
        }
    }
    
    func processEffect(_ request: Request) {
        switch request.effect {
        case .render:
            let viewData = Thiccc.view()
            self.view = try! .bincodeDeserialize(input: [UInt8](viewData))
        }
    }
}
