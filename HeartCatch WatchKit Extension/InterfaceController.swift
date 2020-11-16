
import WatchKit
import Foundation
import WatchConnectivity

var hisHeartrate:Double = 90
let name = "みき"



class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet weak var heartrateStatus: WKInterfaceLabel!
    
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("session")
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void){
        
        guard let message = message["heartrate"] as? Double
        
        
    else{
            return
        }
        if message == 0.0 {
            heartrateStatus.setText("not ready")
        } else {
            heartrateStatus.setText(name + "さんの心拍を受信済")
        }
        
          print("receiveMessage::\(message)")
        //hisHeartrate = (message["heartrate"] as? Double)!
        print("hisHeartrate is")
        hisHeartrate = message
        print(hisHeartrate)
      }
    
    
    var session: WCSession!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if WCSession.isSupported(){
            session = WCSession.default
            session!.delegate = self
            session!.activate()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func MyButton() {
        //changeLabel()
        playHaptics()
        }
    func changeLabel(){
        heartrateStatus.setText(String(hisHeartrate))
    }
    func playHaptics () {
        let hapticType = WKHapticType(rawValue: 6)!
        for i in 1..<20 {
            print("i: \(i)")
            WKInterfaceDevice.current().play(hapticType)
            Thread.sleep(forTimeInterval: 60/hisHeartrate)
            print(hisHeartrate)
    }
    }
}
