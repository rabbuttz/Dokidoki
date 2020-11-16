





import UIKit
import Firebase
import HealthKit
import WatchConnectivity

let healthStore = HKHealthStore()
let hisName = "me" //ここにあなたの名前を入力
let yourName = "miki" //ここに相手の名前を入力（デフォルトではメンバーのみきさんの心拍を取得することができます。）
var hisHeartrate:Double = 0
var dicHisHeartrate: Dictionary<String, Double> = ["heartrate": hisHeartrate]

class ViewController: UIViewController,
                    WCSessionDelegate {
    var globalHeartRate:Double!
    var DBRef:DatabaseReference!
    let dt = Date()
    var dateAndRate: [(myDate: Date, myHeartRate: Double)] = []
    
   var session:WCSession!
    
    public func session(_ session: WCSession, activationDidCompleteWith activationDidCompleteWithactivationState:WCSessionActivationState, error: Error?){
        switch WCSessionActivationState.activated {
        case .activated:
            print("セッションアクティブ")

        case .inactive:
            print("セッションはアクティブでデータ受信できる可能性はあるが、相手にはデータ送信できない")
        case .notActivated:
            print("セッション非アクティブで通信できない状態")
            let errStr = error?.localizedDescription.description
            print("error: " + (errStr?.description)!)
        }
    }

    func sessionDidBecomeInactive(_:WCSession) {
        print("sessionDidBecomeInactive")
    }

    func sessionDidDeactivate(_:WCSession)  {
        print("sessionDidDeactivate")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            if WCSession.isSupported() { // WCSessionが存在する場合のみ実行
                session = WCSession.default
                session!.delegate = self
                session!.activate()
            }


        
        
        print("ここだよ")
        if HKHealthStore.isHealthDataAvailable() {
            print("対応")
        } else {
            print("非対応")
        }
        // 読み込むデータ
        let read = Set(arrayLiteral:HKObjectType.quantityType(forIdentifier: .heartRate)!)
        let write = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: .bodyMass)!)
         
        healthStore.requestAuthorization(toShare: write, read: read, completion: { (status, error) in
            if status {
                print("認証済み")
            } else {
                print(error?.localizedDescription ?? "認証拒否")
            }
        })
        getTodaysHeartRates()
    }
    let health: HKHealthStore = HKHealthStore()
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")
    let heartRateType:HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        var heartRateQuery:HKSampleQuery?
    
    
    

    
    func getTodaysHeartRates() {
        print("cc")
       //predicate
       let calendar = NSCalendar.current
       let now = NSDate()
       let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
       
       guard let startDate:NSDate = calendar.date(from: components) as NSDate? else { return }
       var dayComponent    = DateComponents()
       dayComponent.day    = 1
       let endDate:NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
       let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])


       let sortDescriptors = [
                               NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                             ]
       
       heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 25, sortDescriptors: sortDescriptors, resultsHandler: { (query, results, error) in
           guard error == nil else { print("error"); return }

           self.printHeartRateInfo(results: results)
       })
       
       health.execute(heartRateQuery!)
    }


   private func printHeartRateInfo(results:[HKSample]?)
   {
       for (_, sample) in results!.enumerated() {
           guard let currData:HKQuantitySample = sample as? HKQuantitySample else { return }

           print("[\(sample)]")
           print("Heart Rate: \(currData.quantity.doubleValue(for: heartRateUnit))")
           print("quantityType: \(currData.quantityType)")
           print("Start Date: \(currData.startDate)")
           print("End Date: \(currData.endDate)")
           print("UUID: \(currData.uuid)")
           print("Source: \(currData.sourceRevision)")
           print("---------------------------------\n")
  
        dateAndRate.append((myDate: currData.endDate, myHeartRate: currData.quantity.doubleValue(for:heartRateUnit)))
       }//eofl
   }
    
    @IBOutlet weak var MyHeartRate: UILabel!

    @IBOutlet weak var MyButton: UIButton!
    @IBAction func MyButtonNew(_ sender: UIButton) {
        let dateAndRateMax = dateAndRate.max(by: { (a, b) -> Bool in
            return a.myDate < b.myDate
        })
        globalHeartRate = dateAndRateMax?.myHeartRate
    
        
        let image = UIImage(named: "heartfull")
        let state = UIControl.State.normal

        MyButton.setImage(image, for: state)
        
        DBRef = Database.database().reference()
        //取得
        let gotHeartRate = DBRef.child("heartrate").child(hisName).observe(.value) { (snapshot) in
           let value = snapshot.value as? NSDictionary
            var castedValue = value!["heartrate"]
            hisHeartrate = castedValue as! Double
            print(hisHeartrate)
            //let stringHisHeartrate:String = String(hisHeartrate)
        }
        //送信
        self.DBRef.child("heartrate").child(yourName).setValue(["heartrate": globalHeartRate])
        {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Data could not be saved: \(error).")
          } else {
            print("Data saved successfully!")
            
            dicHisHeartrate = ["heartrate":hisHeartrate]
            self.MyHeartRate.text = ("AppleWatchに" + hisName + "さんの心拍が送られました。/n" + "送信されたあなたの心拍数：" + String(self.globalHeartRate))
            print("dicHisHeartrate = ")
            print(dicHisHeartrate)
          }
        }
        
        guard session != nil else{
            return
        }
        
        session!.sendMessage(dicHisHeartrate, replyHandler: { (responses) -> Void in
                    print ("sent to AppleWatch");
                }) { (error) -> Void in
                    print(error)
                }
    }
}


