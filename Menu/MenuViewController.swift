//
//  MenuViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/11/10.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Firebase

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuTableView: UITableView!
    var isFirstAppearing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.menuTableView.delegate = self
        self.menuTableView.dataSource = self
        self.isFirstAppearing = true
        self.menuTableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // メニューの位置を取得する
        let menuPos = self.menuView.layer.position
        if isFirstAppearing {
            // 初期位置を画面の外側にするため、メニューの幅の分だけマイナスする
            self.menuTableView.layer.position.x = self.view.frame.width + self.menuTableView.frame.width
            // 初期位置を画面の外側にするため、メニューの幅の分だけマイナスする
            self.menuView.layer.position.x = self.view.frame.width + self.menuView.frame.width
            // 表示時のアニメーションを作成する
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    self.menuView.layer.position.x = menuPos.x
                    self.menuTableView.layer.position.x = menuPos.x
                },
                completion: { bool in
                })
            self.isFirstAppearing = false
        }
        self.menuTableView.separatorInset = .zero
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.menuTableView.indexPathForSelectedRow != nil {
            self.menuTableView.deselectRow(at: self.menuTableView.indexPathForSelectedRow!, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // この画面が閉じられたことを他の画面に伝える
        self.presentingViewController!.beginAppearanceTransition(true, animated: animated)
        self.presentingViewController!.endAppearanceTransition()
    }
    
    @IBAction func closeButton(_ sender: Any) {
        // 非表示時のアニメーションを作成する
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.menuView.layer.position.x = self.view.frame.width + self.menuView.frame.width
                self.menuTableView.layer.position.x = self.view.frame.width + self.menuTableView.frame.width
            },
            completion: { bool in
            })
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let backView = UIView()
        backView.backgroundColor = Colors.midiSolid
        cell.selectedBackgroundView = backView
        cell.backgroundColor = Colors.back
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "・個人情報登録および変更"
        case 1:
            cell.textLabel?.text = "・メールアドレス変更"
        case 2:
            cell.textLabel?.text = "・パスワード変更"
        case 3:
            cell.textLabel?.text = "・前回送信済み処方箋の確認"
        default:
            cell.textLabel?.text = "・ログアウト"
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let nextViewController = self.storyboard!.instantiateViewController(identifier: "profile")
            self.present(nextViewController, animated: true, completion: nil)
        case 1:
            let nextViewController = self.storyboard!.instantiateViewController(identifier: "mail")
            self.present(nextViewController, animated: true, completion: nil)
        case 2:
            let nextViewController = self.storyboard!.instantiateViewController(identifier: "password")
            self.present(nextViewController, animated: true, completion: nil)
        case 3:
            let nextViewController = self.storyboard!.instantiateViewController(identifier: "image")
            self.present(nextViewController, animated: true, completion: nil)
        default:
            let alert: UIAlertController = UIAlertController(title: "注意", message: "ログアウトしてもよろしいですか？", preferredStyle:  UIAlertController.Style.alert)
            // OKボタン
            let okAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                // トピックからも削除
                Messaging.messaging().unsubscribe(fromTopic: Auth.auth().currentUser!.uid) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else {
                        print("Unsubscribed to topic")
                    }
                }
                // ログアウト
                try! Auth.auth().signOut()
                // メニューを閉じる
                self.dismiss(animated: false, completion: nil)
            })
            // キャンセルボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                self.menuTableView.deselectRow(at: self.menuTableView.indexPathForSelectedRow!, animated: true)
            })
            
            alert.addAction(cancelAction)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
}
