//
//  MailViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/11/10.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class MailViewController: CommonViewController {
    
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var mailTextField2: UITextField!
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mailTextField.delegate = self
        self.mailTextField2.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // この画面が閉じられたことを他の画面に伝える
        self.presentingViewController!.beginAppearanceTransition(true, animated: animated)
        self.presentingViewController!.endAppearanceTransition()
    }
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        
        if self.mailTextField.text!.isEmpty || self.mailTextField2.text!.isEmpty {
            SVProgressHUD.showError(withStatus: "すべての項目を入力してください")
            SVProgressHUD.dismiss(withDelay: 2)
            return
        }
        
        if self.mailTextField.text! != self.mailTextField2.text! {
            SVProgressHUD.showError(withStatus: "メールアドレスが一致しません")
            SVProgressHUD.dismiss(withDelay: 2)
            return
        }
        
        if let user = Auth.auth().currentUser {
            // HUDで処理中を表示
            SVProgressHUD.show()
            user.updateEmail(to: self.mailTextField.text!) { error in
                if let error = error {
                    if AuthErrorCode(rawValue: error._code) == AuthErrorCode.requiresRecentLogin {
        
                        let alert: UIAlertController = UIAlertController(title: "注意", message: "最新のログイン情報が必要です。ログイン画面を開きます。", preferredStyle:  UIAlertController.Style.alert)
                        // OKボタン
                        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                            (action: UIAlertAction!) -> Void in
                            self.showLoginViewController()
                            return
                        })
                        // キャンセルボタン
                        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
                            (action: UIAlertAction!) -> Void in
                        })
                        
                        alert.addAction(cancelAction)
                        alert.addAction(okAction)
                        
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    else {
                        // メールアドレス更新不可
                        print("<<メールアドレス変更エラー>>: " + error.localizedDescription)
                        SVProgressHUD.showError(withStatus: "メールアドレスが正しくありません")
                        SVProgressHUD.dismiss(withDelay: 2)
                        return
                    }
                    
                }
                print("<<メールアドレス変更成功>>: [mail = \(String(describing: user.email))]の設定に成功しました。")
                let userRef = Firestore.firestore().collection("users").document(user.uid)
                userRef.updateData(["mail": self.mailTextField.text!])
                SVProgressHUD.showSuccess(withStatus: "変更が完了しました！")
                SVProgressHUD.dismiss(withDelay: 1)
                // 画面を閉じてタブ画面に戻る
                self.dismiss(animated: true, completion: nil)
            }
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showLoginViewController() {
        let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "Login") as! LoginViewController
        loginViewController.modalPresentationStyle = .fullScreen
        loginViewController.isFromSetting = true
        self.present(loginViewController, animated: true, completion: nil)
    }
    
}
