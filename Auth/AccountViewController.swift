//
//  AccountViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/04.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class AccountViewController: CommonViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var mailTextField2: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordTextField2: UITextField!
    @IBOutlet weak var kiyakuStackView: UIStackView!
    var isAgreed = false
    @IBOutlet weak var nextButton: CustomButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mailTextField.delegate = self
        self.mailTextField2.delegate = self
        self.passwordTextField.delegate = self
        self.passwordTextField2.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !isAgreed {
            self.nextButton.isEnabled = false
            self.nextButton.backgroundColor = UIColor.lightGray
            self.nextButton.layer.shadowOpacity = 0
        }
        else {
            self.nextButton.isEnabled = true
            self.nextButton.backgroundColor = Colors.solid
            self.nextButton.layer.shadowOpacity = 0.6
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is ProfileViewController {
            let nextViewController = segue.destination as! ProfileViewController
            nextViewController.isFromAccountViewController = true
        }
    }
    
    @IBAction func kiyakuButtonTapped(_ sender: Any) {
        let kiyakuViewController = self.storyboard!.instantiateViewController(identifier: "kiyaku")
        self.present(kiyakuViewController, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        // チェックしてからユーザー登録処理して遷移
        
        // どれかが空のとき
        if self.mailTextField.text!.isEmpty || self.mailTextField2.text!.isEmpty || self.passwordTextField.text!.isEmpty || self.passwordTextField2.text!.isEmpty {
            SVProgressHUD.showError(withStatus: "すべての項目に入力してください")
            return
        }
        if self.mailTextField.text! != self.mailTextField2.text! {
            SVProgressHUD.showError(withStatus: "メールアドレスが一致しません")
            SVProgressHUD.dismiss(withDelay: 2)
            return
        }
        if self.passwordTextField.text! != self.passwordTextField2.text! {
            SVProgressHUD.showError(withStatus: "パスワードが一致しません")
            SVProgressHUD.dismiss(withDelay: 2)
            return
        }
        // 利用規約への同意を求める
        // アドレスとパスワードでユーザー作成。ユーザー作成に成功すると、自動的にログインする
        Auth.auth().createUser(withEmail: self.mailTextField.text!, password: self.passwordTextField.text!) { authResult, error in
            if let error = error {
                // エラーがあったら原因をprintして、returnすることで以降の処理を実行せずに処理を終了する
                print("<<新規登録エラー>>: " + error.localizedDescription)
                SVProgressHUD.showError(withStatus: "メールアドレスかパスワードが正しくありません。")
                SVProgressHUD.dismiss(withDelay: 2)
                return
            }
            print("<<新規登録成功>>: ユーザー作成に成功しました。")
            self.performSegue(withIdentifier: "toProfile", sender: nil)
        }
    }
}
