//
//  Conversation.swift
//  HomeSafv
//
//  Created by Alex Tan, Desmond, Yanling, Lei Jun on 25/4/17.
//  Copyright © 2017 SG4207. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class Conversation: NSObject {
    let user: User
    var lastMessage: Message
    
    class func showConversations(completion: @escaping ([Conversation]) -> Swift.Void) {
        if let currentUserID = FIRAuth.auth()?.currentUser?.uid {
            var conversations = [Conversation]()
            FIRDatabase.database().reference().child("users").child(currentUserID).child("conversations").observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    let fromID = snapshot.key
                    let values = snapshot.value as! [String: String]
                    let location = values["location"]!
                    User.info(forUserID: fromID, completion: { (user) in
                        let emptyMessage = Message.init(type: .text, content: "loading", owner: .sender, timestamp: 0, isRead: true, locsession: "", locsesscount: "")
                        let conversation = Conversation.init(user: user, lastMessage: emptyMessage)
                        conversations.append(conversation)
                        conversation.lastMessage.downloadLastMessage(forLocation: location, completion: { (_) in
                            completion(conversations)
                        })
                    })
                }
            })
        }
    }
    
    init(user: User, lastMessage: Message) {
        self.user = user
        self.lastMessage = lastMessage
    }

}
