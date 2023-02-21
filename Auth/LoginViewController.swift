//
//  LoginViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/04.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class LoginViewController: CommonViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var toAccountButton: UIButton!
    
    var isFromSetting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mailTextField.delegate = self
        self.passwordTextField.delegate = self

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // メールアドレス変更やパスワード変更画面からの遷移時
        if self.isFromSetting {
            self.toAccountButton.isHidden = true
        }
        else {
            self.toAccountButton.isHidden = false
        }
    }
    
    // 画面タップでキーボードを閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if self.mailTextField.text!.isEmpty || self.passwordTextField.text!.isEmpty {
            SVProgressHUD.showError(withStatus: "すべての項目に入力してください")
            SVProgressHUD.dismiss(withDelay: 2)
            return
        }
        // HUDで処理中を表示
        SVProgressHUD.show()
        
        Auth.auth().signIn(withEmail: self.mailTextField.text!, password: self.passwordTextField.text!) { authResult, error in
            if let error = error {
                print("<<ログインエラー>>: " + error.localizedDescription)
                SVProgressHUD.showError(withStatus: "メールアドレスもしくはパスワードが誤っています。")
                SVProgressHUD.dismiss(withDelay: 2)
                return
            }
            print("<<ログイン成功>>: ログインに成功しました。")
            // HUDを消す
            SVProgressHUD.dismiss()
            // 画面を閉じて元の画面に戻る
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }

}
