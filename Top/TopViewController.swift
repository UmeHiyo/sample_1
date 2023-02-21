//
//  ViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/09/24.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit
import Photos
import SVProgressHUD
import Firebase
import CalculateCalendarLogic
import FirebaseMessaging

class TopViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var changeViewSegment: UISegmentedControl!
    @IBOutlet weak var selectPhotoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var myView: UIView!
    // ⚠️セグメントの活性非活性はisEnabledへの代入を行わないこと！！
    @IBOutlet weak var haisouSegment: UISegmentedControl!
    @IBOutlet weak var honjitsuSegment: UISegmentedControl!
    @IBOutlet weak var dateSegment: UISegmentedControl!
    @IBOutlet weak var timeSegment: UISegmentedControl!
    @IBOutlet weak var menuButton: UIButton!
    var existProfile = false
    var currentProfile: User!
    
    var limitedHour = 2
    var dateArray: [Date] = []
    // 最初に処方箋を送信する時にユーザーのプロフィール情報が存在しないときはユーザー情報の登録を指示
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.selectPhotoLabel.text = "ここをタップして\n処方箋画像を選択"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 日付セグメントに値を設定
        self.dateArray = self.getArrayForDateSegment()
        for i in 0..<self.dateArray.count {
            self.dateSegment.setTitle(self.getDateString(date: self.dateArray[i]), forSegmentAt: i)
        }
        self.changeViewSegment.selectedSegmentIndex = 0
        self.checkSegments()
        self.checkSelectedSegmentIndex(segment: self.timeSegment)
        self.checkSelectedSegmentIndex(segment: self.dateSegment)
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
        SVProgressHUD.show(withStatus: "プロフィール取得中")
        SVProgressHUD.dismiss(withDelay: 0.8)
        // ユーザープロフィールの取得
        let userId = Auth.auth().currentUser!.uid // ログイン状態でしかこの画面を開けない
        
        // ログイン済みであれば通知のトピック登録を行う
        Messaging.messaging().subscribe(toTopic: Auth.auth().currentUser!.uid) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                print("Subscribed to topic")
            }
        }
        
        let userRef = Firestore.firestore().collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let error = error {
                print("<<プロフィール取得エラー>>: documentの取得に失敗しました。 \(error)")
            }
            if let document = document, document.exists {
                print("<<プロフィール取得成功>>: 既存プロフィールデータがあります。")
                self.existProfile = true
                self.currentProfile = User(document: document)
            }
            else {
                print("<<プロフィールなし>>:　\(userId)←←←このユーザーのプロフィール情報はありません。")
            }
        }
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        //セグメントが変更されたときの処理
        //選択されているセグメントのインデックス
        let selectedIndex = changeViewSegment.selectedSegmentIndex
        if selectedIndex == 1 {
            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.changeView), userInfo: nil, repeats: false)
            
        }
    }
    
    @objc func changeView() {
        self.performSegue(withIdentifier: "segue", sender: nil)
    }
    
    @IBAction func imageButtonTapped(_ sender: Any) {
        let alert: UIAlertController = UIAlertController(title: "画像の選択方法を選んでください", message: nil, preferredStyle:  .actionSheet)
        // カメラボタン
        let cameraAction: UIAlertAction = UIAlertAction(title: "カメラを起動", style: .default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("カメラ")
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .camera
                self.present(pickerController, animated: true, completion: nil)
            }
        })
        // ライブラリボタン
        let libraryAction: UIAlertAction = UIAlertAction(title: "ライブラリ", style: .default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("ライブラリ")
            // フォトライブラリを表示する
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .photoLibrary
                self.present(pickerController, animated: true, completion: nil)
            }
            
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: .cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("キャンセル")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        // iPadでは必須！
        alert.popoverPresentationController?.sourceView = self.view
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        alert.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let myImage: AnyObject?  = info[UIImagePickerController.InfoKey.originalImage] as AnyObject
        self.imageView.image = myImage as? UIImage
        self.imageView.backgroundColor = .systemGray
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 受け取りor配達
    @IBAction func haisouSegmentChanged(_ sender: Any) {
        self.checkSegments()
        self.checkSelectedSegmentIndex(segment: self.dateSegment)
        self.checkSelectedSegmentIndex(segment: self.timeSegment)
    }
    
    // 本日or翌日以降
    @IBAction func honjitsuSegmentChanged(_ sender: Any) {
        self.checkSegments()
        self.checkSelectedSegmentIndex(segment: self.dateSegment)
        self.checkSelectedSegmentIndex(segment: self.timeSegment)
    }
    
    // 日付
    @IBAction func dateSegmentChanged(_ sender: Any) {
        self.checkSegments()
        self.checkSelectedSegmentIndex(segment: self.timeSegment)
    }
    
    // 送信ボタン
    @IBAction func submitButtonTapped(_ sender: Any) {
        // ユーザー情報の取得
        // nilのときはプロフィール入力を促して送信処理をしない
        // 町名に半角が含まれる場合は全角にする
        // 本日希望かつ受け取り希望時間を超える場合のエラー
        // 本日希望かつ配達可能時間を超える場合のエラー
        
        
        // プロフィール情報がない場合
        if !existProfile {
            SVProgressHUD.showError(withStatus: "メッセージを送信するには個人情報の登録が必要です。\n[MENU]\n↓\n[個人情報登録および変更]\n\n※登録済みの場合は少し待ってから再度お試しください。")
            return
        }
        // 処方箋画像がない場合
        if self.imageView.image == nil {
            SVProgressHUD.showError(withStatus: "処方箋画像を登録してください。")
            return
        }
        // 薬局で受け取り希望かつ時間選択されていない場合
        if self.haisouSegment.selectedSegmentIndex == 0 && self.timeSegment.selectedSegmentIndex == -1 {
            //
            SVProgressHUD.showError(withStatus: "時間を選択してください。\n選択できる時間が表示されない場合は翌日以降の日付を指定してください。")
            return
        }
        // 配達希望
        if self.haisouSegment.selectedSegmentIndex == 1 {
            // 配達できる住所じゃない場合
            let userAddress = self.currentProfile.address!
            let townNames = AddressUtil.townNames
            var canPostFlag = false
            for townName in townNames {
                if userAddress.contains(townName) {
                    canPostFlag = true
                }
            }
            if !canPostFlag {
                SVProgressHUD.showError(withStatus: "登録されている住所が配達可能エリアではありません。")
                return
            }
            // 本日希望で受付可能時間を過ぎている場合
            if  self.honjitsuSegment.selectedSegmentIndex == 0 {
                let now = Date()
                let current = Calendar.current
                let intHour = current.component(.hour, from: now)
                // 12時台までOKとする（13時を含まない）
                if intHour > 13 {
                    SVProgressHUD.showError(withStatus: "本日の配達希望受付時間を過ぎています。\n配達をご希望の場合は翌日以降の日付を指定してください。")
                    return
                }
            }
        }
        let fireStore = Firestore.firestore()
        let prescRef = fireStore.collection("prescription").document()
        // 画像をJPEG形式に変換する
        let imageData = self.imageView.image!.jpegData(compressionQuality: 0.75)
        let imageRef = Storage.storage().reference().child("image").child(prescRef.documentID + ".jpg")
        // HUDで投稿処理中の表示を開始
        SVProgressHUD.show()
        // Storageに画像をアップロードする
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        imageRef.putData(imageData!, metadata: metadata) { (metadata, error) in
            if error != nil {
                // 画像のアップロード失敗
                print(error!)
                SVProgressHUD.showError(withStatus: "画像のアップロードが失敗しました")
                return
            }
            let userId = Auth.auth().currentUser!.uid
            
            var deliveryFlag = false
            if self.haisouSegment.selectedSegmentIndex == 1 {
                deliveryFlag = true
            }
            // ソート用日付(0時0分0秒)
            var dateForSort: Date = Date()
            var pickUpDate = "希望日: "
            if self.honjitsuSegment.selectedSegmentIndex == 0 {
                pickUpDate = pickUpDate + self.getDateString(date: Date()) // 本日の日付(String)
                dateForSort = Date().fixed(hour: 0, minute: 0, second: 0)  // 本日の日付0時0分(Date)
            }
            else {
                pickUpDate = pickUpDate + self.dateSegment.titleForSegment(at: self.dateSegment.selectedSegmentIndex)! // 選択された日付(String)
                dateForSort = self.dateArray[self.dateSegment.selectedSegmentIndex].fixed(hour: 0, minute: 0, second: 0) // 選択された日付0時0分(Date)
            }
            var timeForSort = "00" // 配達希望が一番最初に来るうよう
            if !deliveryFlag {
                pickUpDate += "　希望時間: " + self.timeSegment.titleForSegment(at: self.timeSegment.selectedSegmentIndex)!
                timeForSort = self.timeSegment.titleForSegment(at: self.timeSegment.selectedSegmentIndex)!
            }
            // ドキュメントIDは自動採番
            let prescDic = [ "userId" : userId,
                             "userName" : self.currentProfile.name!,
                             "deliveryFlag" : deliveryFlag,
                             "pickUpDate" : pickUpDate,
                             "dateForSort" : dateForSort,
                             "timeForSort" : timeForSort
            ] as [String : Any]
            prescRef.setData(prescDic)
            // スクリーンショットを撮影してUserDefaultsに保存
            let image = self.getImage(self.myView)
            // imageをカメラロールに保存
            // UserDefaultsの宣言
            let ud = UserDefaults.standard
            // UserDefaultsへ保存するとき
            // UIImageをData型へ変換
            let data = image.pngData()
            // UserDefaultsへ保存
            ud.set(data, forKey: "image")
            // HUDで投稿完了を表示する
            SVProgressHUD.showSuccess(withStatus: "処方箋を送信しました！")
        }
    }
    
    @objc func finishedSubmit() {
        SVProgressHUD.showSuccess(withStatus: "送信完了しました！")
        SVProgressHUD.dismiss(withDelay: 0.8)
    }
    
    // 現在日付から連続４日(日祝を除く)のDate配列を作成する
    private func getArrayForDateSegment() -> [Date] {
        var dateArray: [Date] = []
        let nowDate = Date()
        var nowIndex = 0
        let calendar = Calendar.current
        while dateArray.count < self.dateSegment.numberOfSegments {
            let addedDate = calendar.date(byAdding: .day, value: nowIndex + 1, to: nowDate)! // 現在日付からnowIndex + 1足した日付
            // 祝日でも日曜でもない場合のみ配列に追加
            if !self.isHoliday(date: addedDate) {
                dateArray.append(addedDate)
            }
//            let calendarLogic = CalculateCalendarLogic()
//                        let year = calendar.component(.year, from: addedDate)
//                        let month = calendar.component(.month, from: addedDate)
//                        let day = calendar.component(.day, from: addedDate)
//                        let isHoliday: Bool = calendarLogic.judgeJapaneseHoliday(year: year, month: month, day: day)
//                        let weekday = self.getWeekDayIndex(date: addedDate)
//            // 祝日でも日曜でもない場合のみ配列に追加
//            if !isHoliday && weekday != 1 {
//                dateArray.append(addedDate)
//            }
            nowIndex += 1
        }
        return dateArray
    }
    
    // 日付が日曜か祝日であればTrueを返す
    private func isHoliday(date :Date) -> Bool {
        let calendar = Calendar.current
        let calendarLogic = CalculateCalendarLogic()
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let isHoliday: Bool = calendarLogic.judgeJapaneseHoliday(year: year, month: month, day: day)
        let weekday = self.getWeekDayIndex(date: date)
        if isHoliday || weekday == 1 {
            return true
        }
        else {
            return false
        }
    }
    
    // 1/20のような形式でStringを返却する
    private func getDateString(date: Date) -> String {
        var dateString = ""
        let current = Calendar.current
        let intMonth = current.component(.month, from: date)
        let intDay = current.component(.day, from: date)
        // 土曜日の場合は()をつける
        if self.getWeekDayIndex(date: date) == 7 {
            dateString = "( " + String(intMonth) + "/" + String(intDay) + " )"
        }
        else {
            dateString = String(intMonth) + "/" + String(intDay)
        }
        return dateString
    }
    
    
    // 現在選択のセグメントの状態から各セグメントの活性非活性を制御する
    private func checkSegments() {
        if self.haisouSegment.selectedSegmentIndex == 0 {
            if self.honjitsuSegment.selectedSegmentIndex == 0 {
                // ①受け取り希望かつ本日希望
                self.disableAllSegment(segment: self.dateSegment) // 日付全非活性
                let nowDate = Date() // 本日のDate
                //  本日が土曜日の場合12:45までは09:00-13:00のみ選択可能
                if self.getWeekDayIndex(date: nowDate) == 7 {
                    self.disableAllSegment(segment: self.timeSegment) // いったん時間全非活性
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy/MM/dd"
                    let nowDateString = formatter.string(from: nowDate)
                    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                    let limitDateTimeString = nowDateString + " " + "12:45:00" // (例:2021/1/1 12:45:00)
                    let limitDateTime = formatter.date(from: limitDateTimeString)!
                    if limitDateTime > nowDate {
                        self.timeSegment.setEnabled(true, forSegmentAt: 0) // 09:00-13:00だけ活性化
                    }
                }
                // 本日が日・祝の場合は全時間選択不可
                else if self.isHoliday(date: Date()) {
                    self.disableAllSegment(segment: self.timeSegment)
                }
                else {
                    self.disableLimitedTimeSegment() // 現在時刻から時間一部活性
                }
            }
            else {
                self.enableAllSegment(segment: self.dateSegment) // 日付全活性
                let selectedDateIndex = self.dateSegment.selectedSegmentIndex
                let firstDate = self.dateSegment.titleForSegment(at: 0)!
                if selectedDateIndex == -1 {
                    if firstDate.contains("(") {
                        // 日付の最初が土曜日でまだどの日付も選択されていないとき
                        self.disableAllSegment(segment: self.timeSegment) // いったん時間全非活性
                        self.timeSegment.setEnabled(true, forSegmentAt: 0) // 10:00-12:00だけ活性化
                    }
                    else {
                        // 日付の最初が土曜日以外でまだどの日付も選択されていないとき
                        self.enableAllSegment(segment: self.timeSegment) // 時間全活性
                    }
                }
                else {
                    // 日付がなにかしら選択されている時
                    if self.dateSegment.titleForSegment(at: selectedDateIndex)!.contains("(") {
                        // 土曜日の場合
                        self.enableAllSegment(segment: self.dateSegment) // 日付全活性
                        self.disableAllSegment(segment: self.timeSegment) // いったん時間全非活性
                        self.timeSegment.setEnabled(true, forSegmentAt: 0) // 09:00-13:00だけ活性化
                    }
                    else {
                        self.enableAllSegment(segment: self.timeSegment) // 時間全活性
                    }
                }
            }
        }
        else {
            if self.honjitsuSegment.selectedSegmentIndex == 0 {
                // ④配達希望かつ本日希望
                self.disableAllSegment(segment: self.dateSegment) // 日付全非活性
                self.disableAllSegment(segment: self.timeSegment) // 時間全非活性
            }
            else {
                // ⑤配達希望かつ翌日以降希望
                self.enableAllSegment(segment: self.dateSegment) // いったん日付全活性
                for i in 0..<self.dateSegment.numberOfSegments {
                    if self.dateSegment.titleForSegment(at: i)!.contains("(") {
                        // ()のついている土曜を非活性
                        self.dateSegment.setEnabled(false, forSegmentAt: i)
                    }
                }
                self.disableAllSegment(segment: self.timeSegment) // 時間全非活性
            }
            
        }
    }
    
    // 選択状態のセグメントを移動する
    private func checkSelectedSegmentIndex(segment: UISegmentedControl) {
        for i in 0..<segment.numberOfSegments {
            if segment.isEnabledForSegment(at: i) {
                // 最初に活性状態のセグメントが見つかったときにそのセグメントを選択状態にする
                segment.selectedSegmentIndex = i
                return
            }
            // 最後まで活性状態のセグメントが見つからなかった場合は選択状態のセグメントはなし
            segment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
    
    // 時間セグメントの選択可能なものだけを活性化する
    // TODO: 15分前に変える
    private func disableLimitedTimeSegment() {
        let nowDate = Date() // 現在日時(例:2021/1/1 10:00)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let nowYYMMDDString = formatter.string(from: nowDate) // (例:2021/1/1)
        // タイムリミット配列を作る
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let index0String = nowYYMMDDString + " " + "12:45:00" // (例:2021/1/1 12:45:00)
        let index0Date = formatter.date(from: index0String)!
        let index1String = nowYYMMDDString + " " + "14:45:00"
        let index1Date = formatter.date(from: index1String)!
        let index2String = nowYYMMDDString + " " + "16:45:00"
        let index2Date = formatter.date(from: index2String)!
        let index3String = nowYYMMDDString + " " + "19:45:00"
        let index3Date = formatter.date(from: index3String)!
        let timelimitArray = [index0Date, index1Date, index2Date, index3Date]
        
        for i in 0...3 {
            if timelimitArray[i] > nowDate {
                self.timeSegment.setEnabled(true, forSegmentAt: i)
            }
            else {
                self.timeSegment.setEnabled(false, forSegmentAt: i)
            }
        }
        
        //        let addedDate = Calendar.current.date(byAdding: .hour, value: self.limitedHour, to: nowDate)! // 現在時刻からリミット時間を足した日時(例:2020/1/1 12:00)
        //        let intHour = Calendar.current.component(.hour, from: addedDate) // リミット時間を足した日時から時間のInt取得(例:12)
        //        for i in 0...3 {
        //            let limitInt = 12 + (i*2)
        //            if limitInt >= intHour {
        //                self.timeSegment.setEnabled(true, forSegmentAt: i)
        //            }
        //            else {
        //                self.timeSegment.setEnabled(false, forSegmentAt: i)
        //            }
        //        }
    }
    
    // すべてのセグメントを非活性化する
    private func disableAllSegment(segment: UISegmentedControl) {
        for i in 0..<segment.numberOfSegments {
            segment.setEnabled(false, forSegmentAt: i)
        }
    }
    
    // すべてのセグメントを活性化する
    private func enableAllSegment(segment: UISegmentedControl) {
        for i in 0..<segment.numberOfSegments {
            segment.setEnabled(true, forSegmentAt: i)
        }
    }
    
    // 週番号の取得
    private func getWeekDayIndex(date: Date) -> Int {
        return Calendar.current.component(.weekday, from: date)
    }
    
    // UIViewからUIImageに変換する
    private func getImage(_ view : UIView) -> UIImage {
        
        // キャプチャする範囲を取得する
        // 時間セグメントの下の座標まで
        let rect = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.timeSegment.frame.maxY + 7)
        
        // ビットマップ画像のcontextを作成する
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context : CGContext = UIGraphicsGetCurrentContext()!
        
        // view内の描画をcontextに複写する
        view.layer.render(in: context)
        
        // contextのビットマップをUIImageとして取得する
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // contextを閉じる
        UIGraphicsEndImageContext()
        
        return image
    }
    
}


extension Date {
    
    init(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) {
        self.init(
            timeIntervalSince1970: Date().fixed(
                year:   year,
                month:  month,
                day:    day,
                hour:   hour,
                minute: minute,
                second: second
            ).timeIntervalSince1970
        )
    }
    
    func fixed(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
        let calendar = self.calendar
        
        var comp = DateComponents()
        comp.year   = year   ?? calendar.component(.year,   from: self)
        comp.month  = month  ?? calendar.component(.month,  from: self)
        comp.day    = day    ?? calendar.component(.day,    from: self)
        comp.hour   = hour   ?? calendar.component(.hour,   from: self)
        comp.minute = minute ?? calendar.component(.minute, from: self)
        comp.second = second ?? calendar.component(.second, from: self)
        
        return calendar.date(from: comp)!
    }
    
    var year: Int {
        return calendar.component(.year, from: self)
    }
    
    var month: Int {
        return calendar.component(.month, from: self)
    }
    
    var day: Int {
        return calendar.component(.day, from: self)
    }
    
    var hour: Int {
        return calendar.component(.hour, from: self)
    }
    
    var minute: Int {
        return calendar.component(.minute, from: self)
    }
    
    var second: Int {
        return calendar.component(.second, from: self)
    }
    
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .japan
        calendar.locale   = .japan
        return calendar
    }
}

extension TimeZone {
    
    static let japan = TimeZone(identifier: "Asia/Tokyo")!
}

extension Locale {
    
    static let japan = Locale(identifier: "ja_JP")
}
