//
//  Utility.swift
//
//  Created by Robert Vaessen on 10/4/15.
//  Copyright © 2015 Robert Vaessen. All rights reserved.
//

import UIKit
import UserNotifications

// Synchronization ****************************************************************************

public func lockObject(_ object: AnyObject, andExecuteCode code: () -> Any?) -> Any? {
    objc_sync_enter(object)
    defer { objc_sync_exit(object) }
    return code()
}

public var GlobalMainQueue: DispatchQueue {
    return DispatchQueue.main
}

public var GlobalUserInteractiveQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
}

public var GlobalUserInitiatedQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
}

public var GlobalUtilityQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
}

public var GlobalBackgroundQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
}

// String / NSData **************************************************************************

func stringArrayToData(_ array: [String]) -> Data {
    let data = NSMutableData()
    let terminator = [0]
    for string in array {
        if let encodedString = string.data(using: String.Encoding.utf8) {
            data.append(encodedString)
            data.append(terminator, length: 1)
        }
        else {
            NSLog("Cannot encode string \"\(string)\"")
        }
    }
    return data as Data
}

func dataToStringArray(_ data: Data) -> [String] {
    var decodedStrings = [String]()
    
    var stringTerminatorPositions = [Int]()
    
    var currentPosition = 0
    data.enumerateBytes() {
        buffer, index, stop in
        
        for i in 0 ..< index {
            if buffer[i] == 0 {
                stringTerminatorPositions.append(currentPosition)
            }
            currentPosition += 1
        }
    }
    
    var stringStartPosition = 0
    for stringTerminatorPosition in stringTerminatorPositions {
        let encodedString = data.subdata(in: stringStartPosition ..< (stringTerminatorPosition - stringStartPosition))
        if let decodedString =  String(data: encodedString, encoding: String.Encoding.utf8) {
            decodedStrings.append(decodedString)
        }
        stringStartPosition = stringTerminatorPosition + 1
    }
    
    return decodedStrings
}

// User Notifications **************************************************************************
/*
 let content = UNMutableNotificationContent()
 content.title = NSString.localizedUserNotificationStringForKey("Hello!", arguments: nil)
 content.body = NSString.localizedUserNotificationStringForKey("Hello_message_body", arguments: nil)
 content.sound = UNNotificationSound.defaultSound()
 
 // Deliver the notification in five seconds.
 let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
 let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
 
 // Schedule the notification.
 let center = UNUserNotificationCenter.currentNotificationCenter()
 center.addNotificationRequest(request)
 */
public func notifyUser(_ message:  String) {
    if hasNotifyPermission() {
        let content = UNMutableNotificationContent()
        content.body = message;
        content.sound = UNNotificationSound.default()
        let request = UNNotificationRequest(identifier: "\(arc4random())", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

func hasNotifyPermission() -> Bool {
    let currentSettings = UIApplication.shared.currentUserNotificationSettings
    return currentSettings!.types.contains(.alert) && currentSettings!.types.contains(.sound)
}

public func alertUser(title: String?, body: String?) {
    let alert = UIAlertController(title: title, message: body, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
    alert.display()
}

// Other **************************************************************************

open class LocalTime {
    fileprivate static let dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/yyyy HH:mm:ss")
        return formatter
    }()
    
    open class var text : String {
        return dateFormatter.string(from: Date())
    }
}

class ElapsedTime : CustomStringConvertible {
    fileprivate let startTime = Date()
    fileprivate let timeFormatter = DateComponentsFormatter()
    
    init() {
        timeFormatter.calendar = Calendar.current;
        timeFormatter.zeroFormattingBehavior = [.pad]
        timeFormatter.allowedUnits = [.hour, .minute, .second]
    }
    
    var elapsedTime : TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var description : String {
        return timeFormatter.string(from: elapsedTime)!
    }
}

public var applicationName: String = {
    struct Name {
        static let value = Name()
        
        let text: String
        
        init() {
            if let name = Bundle.main.infoDictionary?["CFBundleName"] {
                text = name as! String
            }
            else {
                text = "<UnknownAppliction>"
            }

        }
    }

    return Name.value.text
}()

public func increaseIndent(_ original: String) -> String {
    var modified = original.replacingOccurrences(of: "\n", with: "\n\t")
    modified.insert("\t", at: modified.startIndex)
    if modified.characters.last == "\t" {
        modified.remove(at: modified.characters.index(before: modified.endIndex))
    }
    return modified
}
