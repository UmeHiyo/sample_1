//
//  ChatViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/02.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class ChatViewController: CommonViewController, UITextViewDelegate, UITableViewDataSource {

    @IBOutlet weak var changeViewSegment: UISegmentedControl!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    var existProfile = false
    @IBOutlet weak var textFieldViewHeight: NSLayoutConstraint!
    var messageArray: [Message] = []
    // Firestoreのリスナー
    var listener: ListenerRegistration?
    
    // 最初にメッセージを送信する時にユーザーのプロフィール情報が存在しないときはユーザー情報の登録を指示
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.delegate = self
        self.textView.layer.cornerRadius = 5
        self.textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        self.textView.layer.borderWidth = 0.5
        self.textView.clipsToBounds = true
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "MyMessageCell", bundle: nil), forCellReuseIdentifier: "MyMessageCell")
        self.tableView.register(UINib(nibName: "AnswerMessageCell", bundle: nil), forCellReuseIdentifier: "AnswerMessageCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // currentUserがnilならログインしていない
        if Auth.auth().currentUser == nil {
            // ログインしていないときの処理
            let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "Login")
            loginViewController.modalPresentationStyle = .fullScreen
            self.present(loginViewController, animated: true, completion: nil)
            return
        }
        
        // ログイン済みであれば通知のトピック登録を行う
        Messaging.messaging().subscribe(toTopic: Auth.auth().currentUser!.uid) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                print("Subscribed to topic")
            }
        }
        
        // メッセージのコレクションはユーザーのプロフィールドキュメントに紐づく
        self.listener = Firestore.firestore().collection("users").document(Auth.auth().currentUser!.uid).collection("messages").order(by: "date", descending: false)
            .addSnapshotListener { (querySnapshot :QuerySnapshot?, error: Error?) -> Void  in
                if let error = error {
                    print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                    return
                }
                self.messageArray = querySnapshot!.documents.map { document in
                    print("DEBUG_PRINT: document取得 \(document.documentID)")
                    let message = Message(document: document)
                    return message
                }
                self.tableView.reloadData()
                if self.messageArray.count != 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: self.messageArray.count - 1, section: 0),
                                          at: UITableView.ScrollPosition.bottom, animated: true)
                }
        }
        SVProgressHUD.show(withStatus: "プロフィール取得中")
        SVProgressHUD.dismiss(withDelay: 0.8)
        // ユーザープロフィールの取得
        let userId = Auth.auth().currentUser!.uid // ログイン状態でしかこの画面を開けない
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let error = error {
                print("<<プロフィール取得エラー>>: documentの取得に失敗しました。 \(error)")
            }
            if let document = document, document.exists {
                print("<<プロフィール取得成功>>: 既存プロフィールデータがあります。")
                self.existProfile = true
            }
            else {
                print("<<プロフィールなし>>:　\(userId)←←←このユーザーのプロフィール情報はありません。")
                SVProgressHUD.showError(withStatus: "メッセージを送信するには個人情報の登録が必要です。\n[MENU]→[・個人情報登録および変更]")
                return
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DEBUG_PRINT: viewWillDisappear")
        // listenerを削除して監視を停止する
        self.listener?.remove()
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        let selectedIndex = changeViewSegment.selectedSegmentIndex
        if selectedIndex == 0 {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        
        if existProfile && !self.textView.text!.isEmpty {
            let timeStamp: Timestamp = Timestamp(date: Date())
            let messageRef = Firestore.firestore().collection("users").document(Auth.auth().currentUser!.uid).collection("messages").document()
            // ドキュメントIDは自動採番
            let messageDic = [ "answerFlag" : false,
                               "content" : self.textView.text!,
                               "date" : timeStamp
            ] as [String : Any]
            messageRef.setData(messageDic)
            // メッセージやりとり日時保存用
            let messageUserRef = Firestore.firestore().collection("messageUsers").document(Auth.auth().currentUser!.uid)
            messageUserRef.getDocument { (document, error) in
                if let error = error {
                    print("<<取得エラー>>: documentの取得に失敗しました。 \(error)")
                }
                if let document = document, document.exists {
                    print("<<取得成功>>: 過去にメッセージのやりとりがあります。")
                    messageUserRef.updateData(["lastDate" : timeStamp])
                }
                else {
                    print("<<メッセージなし>>:　\(Auth.auth().currentUser!.uid)←←←このユーザーは初めてのメッセージ送信です。")
                    let messageUserDic = ["userId" : Auth.auth().currentUser!.uid,
                                          "lastDate" : timeStamp] as [String : Any]
                    messageUserRef.setData(messageUserDic)
                }
            }
            self.tableView.reloadData()
            if self.messageArray.count != 0 {
                self.tableView.scrollToRow(at: IndexPath(row: self.messageArray.count - 1, section: 0),
                                           at: UITableView.ScrollPosition.bottom, animated: true)
            }
            self.textView.text = ""
            self.textFieldViewHeight.constant = 80
        }
        else {
            if !existProfile {
                SVProgressHUD.showError(withStatus: "メッセージを送信するには個人情報の登録が必要です。\n[MENU]\n↓\n[個人情報登録および変更]\n\n※登録済みの場合は少し待ってから再度お試しください。")
            }
            else {
                SVProgressHUD.showError(withStatus: "メッセージを入力してください。")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nowMessage = self.messageArray[indexPath.row]
        
        if !nowMessage.answerFlag {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyMessageCell") as! MyMessageCell
            cell.setMessage(message: nowMessage)
            cell.backgroundColor = UIColor.clear
            return cell
        }
        else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "AnswerMessageCell") as! AnswerMessageCell
            cell.setMessage(message: nowMessage)
            cell.backgroundColor = UIColor.clear
            return cell
        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        if textView.numberOfLines > 1 {
            self.textFieldViewHeight.constant = 80 + CGFloat(20 * (self.textView.numberOfLines - 1))
        }
        else {
            self.textFieldViewHeight.constant = 80
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // TextViewが複数行になったら
        if textView.numberOfLines > 1 {
            self.textFieldViewHeight.constant = 80 + CGFloat(20 * (self.textView.numberOfLines - 1))
        }
        else {
            self.textFieldViewHeight.constant = 80
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.textFieldViewHeight.constant = 80
    }
    
    // UITextFieldからframeを取得できないのでoverride
    @objc override func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
            }
        }
        self.view.addGestureRecognizer(self.tapGesture)
    }

}

extension UITextView {
    var numberOfLines: Int {
        // prepare
        var computingLineIndex = 0
        var computingGlyphIndex = 0
        // compute
        while computingGlyphIndex < layoutManager.numberOfGlyphs {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: computingGlyphIndex, effectiveRange: &lineRange)
            computingGlyphIndex = NSMaxRange(lineRange)
            computingLineIndex += 1
        }
        // return
        if textContainer.maximumNumberOfLines > 0 {
            return min(textContainer.maximumNumberOfLines, computingLineIndex)
        } else {
            return computingLineIndex
        }
    }
}
