//
//  Message.swift
//  HomeSafv
//
//  Created by Alex Tan, Desmond, Yanling, Lei Jun on 25/4/17.
//  Copyright © 2017 SG4207. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Message: NSObject {
    var owner: MessageOwner
    var type: MessageType
    var content: Any
    var timestamp: Int
    var isRead: Bool
    var image: UIImage?
    var locsession: String
    var locsesscount: String
    private var toID: String?
    private var fromID: String?
    var LLarray: Array<Any>
    
    class func downloadAllMessages(forUserID: String, completion: @escaping (Message) -> Swift.Void) {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(forUserID).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    
                    //lookhere desmond observe method
                    FIRDatabase.database().reference().child("conversations").child(location).observe(.childAdded, with: { (snap) in
                        if snap.exists() {
                            //logic here to consolidate track location session into 1 message
                            let receivedMessage = snap.value as! [String: Any]
                            var locses = ""
                            var loccnt = ""
                            if((snap.hasChild("locsession")) && (snap.hasChild("locCount")))
                            {
                                locses = receivedMessage["locsession"] as! String
                                loccnt = receivedMessage["locCount"] as! String
                            }
                            
                            let messageType = receivedMessage["type"] as! String
                            var type = MessageType.text
                            switch messageType {
                            case "photo":
                                type = .photo
                            case "location":
                                type = .location
                            case "tracking":
                                type = .tracklocation
                            default: break
                            }
                            //display the messages out
                            if messageType == "tracking"
                            {
                                if loccnt == "0"{
                                    // handle how to display the consolidated message only on 0
                                    //add the session here too
                                    print("locses | " + locses)
                                    let content = receivedMessage["content"] as! String
                                    let fromID = receivedMessage["fromID"] as! String
                                    let timestamp = receivedMessage["timestamp"] as! Int
                                    if fromID == currentUserID {
                                        let message = Message.init(type: type, content: content, owner: .receiver, timestamp: timestamp, isRead: true, locsession: locses, locsesscount: loccnt)
                                        completion(message)
                                    } else {
                                        let message = Message.init(type: type, content: content, owner: .sender, timestamp: timestamp, isRead: true, locsession: locses, locsesscount: loccnt)
                                        completion(message)
                                    }
                                }
                            }
                            else{
                                let content = receivedMessage["content"] as! String
                                let fromID = receivedMessage["fromID"] as! String
                                let timestamp = receivedMessage["timestamp"] as! Int
                                if fromID == currentUserID {
                                    let message = Message.init(type: type, content: content, owner: .receiver, timestamp: timestamp, isRead: true, locsession: "", locsesscount: "")
                                    completion(message)
                                } else {
                                    let message = Message.init(type: type, content: content, owner: .sender, timestamp: timestamp, isRead: true, locsession: "", locsesscount: "")
                                    completion(message)
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    func downloadImage(indexpathRow: Int, completion: @escaping (Bool, Int) -> Swift.Void)  {
        if self.type == .photo {
            let imageLink = self.content as! String
            let imageURL = URL.init(string: imageLink)
            URLSession.shared.dataTask(with: imageURL!, completionHandler: { (data, response, error) in
                if error == nil {
                    self.image = UIImage.init(data: data!)
                    completion(true, indexpathRow)
                }
            }).resume()
        }
    }
    
    class func markMessagesRead(forUserID: String)  {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(forUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    FIRDatabase.database().reference().child("conversations").child(location).observeSingleEvent(of: .value, with: { (snap) in
                        if snap.exists() {
                            for item in snap.children {
                                let receivedMessage = (item as! FIRDataSnapshot).value as! [String: Any]
                                let fromID = receivedMessage["fromID"] as! String
                                if fromID != currentUserID {
                                    FIRDatabase.database().reference().child("conversations").child(location).child((item as! FIRDataSnapshot).key).child("isRead").setValue(true)
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    func downloadLastMessage(forLocation: String, completion: @escaping (Void) -> Swift.Void) {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("conversations").child(forLocation).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    for snap in snapshot.children {
                        // print("entered download last messages - snap exists")
                        let receivedMessage = (snap as! FIRDataSnapshot).value as! [String: Any]
                        self.content = receivedMessage["content"]!
                        self.timestamp = receivedMessage["timestamp"] as! Int
                        let messageType = receivedMessage["type"] as! String
                        let fromID = receivedMessage["fromID"] as! String
                        self.isRead = receivedMessage["isRead"] as! Bool
                        
                        var type = MessageType.text
                        switch messageType {
                        case "text":
                            type = .text
                        case "photo":
                            type = .photo
                        case "location":
                            type = .location
                        case "tracking":
                            type = .tracklocation
                        default: break
                        }
                        self.type = type
                        if currentUserID == fromID {
                            self.owner = .receiver
                        } else {
                            self.owner = .sender
                        }
                        completion()
                    }
                }
            })
        }
    }
    
    class func send(message: Message, toID: String, completion: @escaping (Bool) -> Swift.Void)  {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            switch message.type {
            case .tracklocation:
                let values = ["type": "tracking", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false]
                Message.uploadMessage(withValues: values, toID: toID, completion: { (status) in
                    completion(status)
                })
            case .location:
                let values = ["type": "location", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false]
                Message.uploadMessage(withValues: values, toID: toID  , completion: { (status) in
                    completion(status)
                })
            case .photo:
                let imageData = UIImageJPEGRepresentation((message.content as! UIImage), 0.5)
                let child = UUID().uuidString
                FIRStorage.storage().reference().child("messagePics").child(child).put(imageData!, metadata: nil, completion: { (metadata, error) in
                    if error == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["type": "photo", "content": path!, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false] as [String : Any]
                        Message.uploadMessage(withValues: values, toID: toID, completion: { (status) in
                            completion(status)
                        })
                    }
                })
            case .text:
                let values = ["type": "text", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false]
                Message.uploadMessage(withValues: values, toID: toID, completion: { (status) in
                    completion(status)
                })
            }
        }
    }
    //added by desmond send loc
    class func sendLoc(message:Message, toID: String, completion: @escaping(Bool)-> Swift.Void, conSwitch: Bool, sessionID: String, locCounter: Int){
        let counter = String(locCounter)
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            if conSwitch == true
            {
                // let locsession = ("\(currentUserID)\(counter)")
                
                let values = ["type": "tracking", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "locsession":  sessionID, "locCount": counter, "isRead": false]
                //fire the values and send to database
                print("fromID: \(currentUserID) | content \(message.content)")
                //TODO add to database
                Message.uploadConstLocMessage(withValues: values, toID: toID, completion: { (status) in
                    completion(status)
                })
            }
        }
        
    }
    
    class func uploadConstLocMessage(withValues: [String: Any], toID: String, completion: @escaping (Bool) -> Swift.Void) {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            //desmond snapshot is if the data already exist in the database
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(toID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    FIRDatabase.database().reference().child("conversations").child(location).childByAutoId().setValue(withValues, withCompletionBlock: { (error, _) in
                        if error == nil {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    })
                } else {
                    FIRDatabase.database().reference().child("conversations").childByAutoId().childByAutoId().setValue(withValues, withCompletionBlock: { (error, reference) in
                        let data = ["location": reference.parent!.key]
                        FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(toID).updateChildValues(data)
                        FIRDatabase.database().reference().child("users").child(toID).child("conversations").child(currentUserID).updateChildValues(data)
                        completion(true)
                    })
                }
            })
        }
    }
    
    class func settrackstatus(switcher: Bool, toID: String, sessionid: String, currsessID: String, completion: @escaping (Bool) -> Swift.Void)
    {
        var flag = "start"
        if switcher == false{
            flag = "stop"
        }
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            //desmond snapshot is if the data already exist in the database
            FIRDatabase.database().reference().child("users").child(currentUserID).child("tracksession").child(toID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    
                    let data = snapshot.value as! [String: String]
                    let currID = data["id"]
                    let values = ["type" : "trackID", "fromID": currentUserID, "id": currID , "switch": flag, "session": currsessID]
                    FIRDatabase.database().reference().child("tracksession").child(sessionid).childByAutoId().setValue(values, withCompletionBlock: { (error, _) in
                        if error == nil {
                            //FIRDatabase.database().reference().child("users").child(currentUserID).child("tracksession").child(toID).updateChildValues(values)
                            //FIRDatabase.database().reference().child("users").child(toID).child("tracksession").child(currentUserID).updateChildValues(values)
                            completion(true)
                        } else {
                            completion(false)
                        }
                    })
                }
                else{
                    
                    let values = ["type" : "trackID", "fromID": currentUserID, "id": toID , "switch": flag, "session" : sessionid]
                    FIRDatabase.database().reference().child("tracksession").child(sessionid).childByAutoId().setValue(values, withCompletionBlock: { (error, reference)
                        in
                        FIRDatabase.database().reference().child("users").child(currentUserID).child("tracksession").child(toID).updateChildValues(values)
                        FIRDatabase.database().reference().child("users").child(toID).child("tracksession").child(currentUserID).updateChildValues(values)
                        completion(true)
                    })
                }
            })
        }
    }
    
    
    class func uploadMessage(withValues: [String: Any], toID: String, completion: @escaping (Bool) -> Swift.Void) {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(toID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String: String]
                    let location = data["location"]!
                    FIRDatabase.database().reference().child("conversations").child(location).childByAutoId().setValue(withValues, withCompletionBlock: { (error, _) in
                        if error == nil {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    })
                } else {
                    FIRDatabase.database().reference().child("conversations").childByAutoId().childByAutoId().setValue(withValues, withCompletionBlock: { (error, reference) in
                        let data = ["location": reference.parent!.key]
                        FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").child(toID).updateChildValues(data)
                        FIRDatabase.database().reference().child("users").child(toID).child("conversations").child(currentUserID).updateChildValues(data)
                        completion(true)
                    })
                }
            })
        }
    }
    
    func getLatLong(sessionid: String, toID: String, completion: @escaping (_ result: [String]) -> ()){
        
        var LLarray = [String]()
        var locsession = ""
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    // let fromID = snapshot.key
                    let values = snapshot.value as! [String: String]
                    let location = values["location"]!
                    
                    
                    FIRDatabase.database().reference().child("conversations").child(location).observe(.value, with: { (snapshot) in
                        if snapshot.exists() {
                            for snap in snapshot.children {
                                // print("entered get lat long - snap exists")
                                let receivedMessage = (snap as! FIRDataSnapshot).value as! [String: Any]
                                if (snap as! FIRDataSnapshot).hasChild("locsession")
                                {
                                    locsession = receivedMessage["locsession"] as! String
                                    //  print("locsession" + locsession )
                                }
                                let content = receivedMessage["content"] as! String
                                let type = receivedMessage["type"] as! String
                                //print("sessionid" + sessionid + " |  sessions: " + locsession)
                                if (sessionid == locsession) && (type == "tracking")
                                {
                                    LLarray.append(content)
                                    //let size = LLarray.count
                                    //print ("inside" + String(size))
                                    // print("sessions" + locsession + " |  content: " + content)
                                }
                            }
                            completion(LLarray)
                        }
                    })
                    
                }
            })
        }
    }
    
    
    //MARK: Inits
    init(type: MessageType, content: Any, owner: MessageOwner, timestamp: Int, isRead: Bool, locsession: String, locsesscount: String) {
        self.type = type
        self.content = content
        self.owner = owner
        self.timestamp = timestamp
        self.isRead = isRead
        self.locsession = locsession
        self.locsesscount = locsesscount
        self.LLarray = [String]()
    }
}
