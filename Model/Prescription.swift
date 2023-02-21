//
//  Prescription.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/10.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import Firebase

class Prescription: NSObject {
    var id: String // このIDでStorageの画像を管理する
    var userId: String? // 処方箋を提出したユーザーのID
    var userName: String? // 処方箋を提出したユーザーのプロフィール名(処方箋送信時)
    var deliveryFlag: Bool? // 配送希望でtrue
    var pickUpDate: String? // 受け取り希望日時もしくは配送希望日時(配送時間は13-16時の固定)
    
    init(document: DocumentSnapshot) {
        self.id = document.documentID
        
        let prescDic = document.data()!
        
        self.userId = prescDic["userId"] as? String
        self.userName = prescDic["userName"] as? String
        self.deliveryFlag = prescDic["deliveryFlag"] as? Bool
        self.pickUpDate = prescDic["pickUpDate"] as? String
    }
}

extension UserDefaults {
    // 保存したいUIImage, 保存するUserDefaults, Keyを取得
    func setUIImageToData(image: UIImage, forKey: String) {
        // UIImageをData型へ変換
        let nsdata = image.pngData()
        // UserDefaultsへ保存
        self.set(nsdata, forKey: forKey)
    }
    // 参照するUserDefaults, Keyを取得, UIImageを返す
    func image(forKey: String) -> UIImage {
        // UserDefaultsからKeyを基にData型を参照
        let data = self.data(forKey: forKey)
        // UIImage型へ変換
        let returnImage = UIImage(data: data!)
        // UIImageを返す
        return returnImage!
    }

}
