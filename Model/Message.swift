//
//  Message.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/10.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import Firebase

class Message: NSObject {
    var answerFlag: Bool = false // 回答かどうか
    var content: String = "" // メッセージ内容
    var date: Date = Date() // メッセージ送信日時
    
    init(document: DocumentSnapshot) {        
        let messageDic = document.data()!
        
        self.answerFlag = messageDic["answerFlag"] as! Bool
        
        self.content = messageDic["content"] as! String
        
        let timeStamp = messageDic["date"] as! Timestamp
        self.date = timeStamp.dateValue()
    }
}
