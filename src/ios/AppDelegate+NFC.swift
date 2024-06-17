import CoreNFC

extension AppDelegate {
    
    override open func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        NSLog("Extending UIApplicationDelegate")
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        
        // Confirm that the NSUserActivity object contains a valid NDEF message.
        if #available(iOS 12.0, *) {
            guard let ndefMessage = userActivity.ndefMessagePayload,
                  ndefMessage.records.count > 0,
                  ndefMessage.records[0].typeNameFormat != .empty else {
                return false
            }
            
            guard let nfcPluginInstance = self.viewController.getCommandInstance("NfcPlugin") as? NfcPlugin else {
                return false
            }
            
            var resolved = false
            let lockQueue = DispatchQueue(label: "resolvedLockQueue")
            NSLog(nfcPluginInstance.debugDescription)
                
            DispatchQueue.global().async {
                let waitingTimeInterval: Double = 0.1
                print("<NFC> Did start timeout")
                for _ in 1...2000 { // 5?s timeout
                    if !nfcPluginInstance.isListeningNDEF {
                        Thread.sleep(forTimeInterval: waitingTimeInterval)
                    } else {
                        let jsonDictionary = ndefMessage.ndefMessageToJSON()
                        nfcPluginInstance.sendThroughChannel(jsonDictionary: jsonDictionary)
                        
                        lockQueue.sync {
                            resolved = true
                        }
                        return
                    }
                }
            }
            
            return lockQueue.sync { resolved }
            
        } else {
            return false
        }
    }
}
