//
//  ProfileViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/11/10.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import CoreLocation

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var postNo1TextField: UITextField!
    @IBOutlet weak var postNo2TextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var telTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var sexSegment: UISegmentedControl!
    
    // 現在選択されているTextField
    var selectedTextField:UITextField?
    
    let sexDic: [String:Int] = ["男性":0, "女性":1]
    // 新規登録画面からの遷移時は戻るボタンを消す
    // 新規登録画面からの遷移時は登録するボタンを押した時に利用規約への同意を求める
    var isFromAccountViewController: Bool = false
    @IBOutlet weak var closeButton: UIButton!
    var tapGesture: UITapGestureRecognizer?
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func getAddressButtonTapped(_ sender: CustomButton) {
        
        let postNo = self.postNo1TextField.text! + self.postNo2TextField.text!
        let geocoder = CLGeocoder()
        geocoder.convertAddress(from: postNo) { (address, error) in
            if let error = error {
                print(error)
                SVProgressHUD.showError(withStatus: "郵便番号から住所を取得できませんでした。")
                return
            }
            var addressStr: String = ""
            if let administrativeArea = address?.administrativeArea {
                addressStr += administrativeArea  // → 大阪府
            }
            if let locality = address?.locality {
                addressStr += locality  // → 高槻市
            }
            if let subLocality = address?.subLocality {
                addressStr += subLocality  // → 〇〇町
            }
            self.addressTextField.text = addressStr
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isFromAccountViewController {
            closeButton.isHidden = true
        }
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(self.tapGesture!)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFromAccountViewController {
            return
        }
        self.textFieldInit()
        
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
                let user = User(document: document)
                self.nameTextField.text = user.name!
                let postNo: [String] = user.postNo!.components(separatedBy: "-")
                self.postNo1TextField.text = postNo.first!
                self.postNo2TextField.text = postNo.last!
                self.addressTextField.text = user.address!
                self.telTextField.text = user.tel!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                let strBirthday = dateFormatter.string(from: user.birthday!)
                self.birthdayTextField.text = strBirthday
                self.sexSegment.selectedSegmentIndex = self.sexDic[user.sex!]!
            }
            else {
                print("<<プロフィールなし>>:　\(userId)←←←このユーザーのプロフィール情報はありません。")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // この画面が閉じられたことを他の画面に伝える
        self.presentingViewController!.beginAppearanceTransition(true, animated: animated)
        self.presentingViewController!.endAppearanceTransition()
        // キーボードイベントの監視解除
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        let name = self.nameTextField.text!
        let postNo1 = self.postNo1TextField.text!
        let postNo2 = self.postNo2TextField.text!
        let address = self.addressTextField.text!.applyingTransform(.fullwidthToHalfwidth, reverse: true)! // TODO: アドレスはすべて全角にする
        let tel = self.telTextField.text!
        let strBirthday = self.birthdayTextField.text!
        
        if name.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        if postNo1.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        if postNo2.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        if address.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        if tel.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        if strBirthday.isEmpty {
            SVProgressHUD.showError(withStatus: "全ての項目を入力してください。")
            return
        }
        // 日付チェック
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateBirthday = dateFormatter.date(from: strBirthday)
        if dateBirthday == nil {
            SVProgressHUD.showError(withStatus: "誕生日は指定された形式で入力してください。")
            return
        }
        // dateformatを表示形式に
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        // 性別セグメントから性別の取得
        let sex = self.sexSegment.titleForSegment(at: self.sexSegment.selectedSegmentIndex)!
        let message = "お名前：\(name)\n〒：\(postNo1)-\(postNo2)\n住所：\(address)\n電話番号：\(tel)\n誕生日：\(dateFormatter.string(from: dateBirthday!))\n性別：\(sex)"
        
        let alert: UIAlertController = UIAlertController(title: "下記の内容で登録します。", message: message, preferredStyle:  UIAlertController.Style.alert)
        
        // OKボタン
        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            // 登録処理
            let userDic = [
                "name" : name ,
                "postNo" : postNo1 + "-" + postNo2 ,
                "address" : address ,
                "tel" : tel ,
                "sex" : sex ,
                "birthday" : dateBirthday!,
                "mail": Auth.auth().currentUser!.email!
            ] as [String : Any]
            self.setUserProfile(userDic: userDic)
            if self.isFromAccountViewController {
                SVProgressHUD.showSuccess(withStatus: "登録が完了しました！")
                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
            else {
                SVProgressHUD.showSuccess(withStatus: "変更が完了しました！")
                // この画面を閉じる
                self.dismiss(animated: false, completion: nil)
            }
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setUserProfile(userDic: [String : Any]) {
        let userId = Auth.auth().currentUser!.uid // ログイン状態でしかこの画面を開けない
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.setData(userDic)
    }
    
    // キーボードを閉じる
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
        self.scrollView.removeGestureRecognizer(self.tapGesture!)
    }
    
}

extension ProfileViewController: UITextFieldDelegate {
    
    func textFieldInit() {
        
        self.nameTextField.delegate = self
        self.postNo1TextField.delegate = self
        self.postNo2TextField.delegate = self
        self.addressTextField.delegate = self
        self.telTextField.delegate = self
        self.birthdayTextField.delegate = self
        // キーボードイベント監視
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // キーボードが表示された時に呼ばれる
    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue, let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {
                restoreScrollViewSize()
                
                let convertedKeyboardFrame = scrollView.convert(keyboardFrame, from: nil)
                // 現在選択中のTextFieldの下部Y座標とキーボードの高さから、スクロール量を決定
                let offsetY: CGFloat = self.selectedTextField!.frame.maxY - convertedKeyboardFrame.minY + 20
                if offsetY < 0 { return }
                updateScrollViewSize(moveSize: offsetY, duration: animationDuration)
            }
        }
    }
    
    // キーボードが閉じられた時に呼ばれる
    @objc func keyboardWillHide(notification: NSNotification) {
        restoreScrollViewSize()
    }
    
    // TextFieldが選択された時
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // 選択されているTextFieldを更新
        self.selectedTextField = textField
        self.scrollView.addGestureRecognizer(self.tapGesture!)
    }
    
    // moveSize分Y方向にスクロールさせる
    func updateScrollViewSize(moveSize: CGFloat, duration: TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: moveSize, right: 0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            self.scrollView.contentOffset = CGPoint(x: 0, y: moveSize)
        }, completion: nil)
    }
    
    func restoreScrollViewSize() {
        // キーボードが閉じられた時に、スクロールした分を戻す
        self.scrollView.contentInset = UIEdgeInsets.zero
        self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
}
