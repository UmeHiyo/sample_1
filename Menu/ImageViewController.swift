//
//  ImageViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2021/02/02.
//  Copyright © 2021 Yuiko Umekawa. All rights reserved.
//

import UIKit
import SVProgressHUD

// 拡大画像表示
class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var lastScale: CGFloat = 1
    @IBOutlet var superView: UIView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.isUserInteractionEnabled = true
        let ud = UserDefaults.standard
        if ud.data(forKey: "image") != nil {
            let imageData = ud.data(forKey: "image")!
            // Data型からUIImage型へ変換
            self.imageView.image = UIImage(data: imageData)
            self.imageView.contentMode = .scaleAspectFit
            let pinchGesture = UIPinchGestureRecognizer()
            pinchGesture.addTarget(self, action: #selector(pinchAction(_:) ) )
            
            let panGesture = UIPanGestureRecognizer()
            panGesture.addTarget(self, action: #selector(panAction(_:) ) )
            
            self.imageView.addGestureRecognizer(pinchGesture)
            self.imageView.addGestureRecognizer(panGesture)
        }
        else {
            self.label.text = "送信済みの処方箋はありません。"
            return
        }
    }
    
    @objc func pinchAction(_ gesture: UIPinchGestureRecognizer ){
        if gesture.state == .began {
            lastScale = gesture.scale //lastScale はメンバ変数として定義する。
        }
        
        if gesture.state == .began || gesture.state == .changed {
            let currentScale: CGFloat = self.imageView.layer.value(forKeyPath: "transform.scale") as! CGFloat
            let maxScale: CGFloat = 3.0 // 最大値を定義
            let minScale: CGFloat = 1.0 // 最小値を定義
            var newScale: CGFloat = 1 - (lastScale - gesture.scale)
            newScale = min(newScale, maxScale / currentScale)
            newScale = max(newScale, minScale / currentScale)
            self.imageView.transform = (self.imageView.transform.scaledBy(x: newScale, y: newScale))
            lastScale = gesture.scale
        }
        
        //はみ出していないか判定する
        if self.imageView.frame.origin.x > 0 {
            self.imageView.frame.origin.x = 0
        }
        if self.imageView.frame.origin.y > 0 {
            self.imageView.frame.origin.y = 0
        }
        if self.imageView.frame.maxX < self.superView.bounds.width {
            self.imageView.frame.origin.x = 0
        }
        if self.imageView.frame.maxY < self.superView.bounds.height {
            self.imageView.frame.origin.y = 0
        }
    }
    
    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
        
        // 現在のtransfromを保存
        let transform = self.imageView.transform
        
        // imageViewのtransformを初期値に戻す
        // これを入れないと、拡大時のドラッグの移動量が少なくなってしまう
        self.imageView.transform = CGAffineTransform.identity
        
        // 画像をドラッグした量だけ動かす
        let point: CGPoint = gesture.translation(in: imageView)
        let movedPoint = CGPoint(x: imageView.center.x + point.x,
                                 y: imageView.center.y + point.y)
        self.imageView.center = movedPoint
        

        
        // 保存しておいたtransformに戻す
        self.imageView.transform = transform
        
        // ドラッグで移動した距離をリセット
        gesture.setTranslation(CGPoint.zero, in: self.imageView)
        //はみ出していないか判定する
        if self.imageView.frame.origin.x > 0 {
            self.imageView.frame.origin.x = 0
        }
        if self.imageView.frame.origin.y > 0 {
            self.imageView.frame.origin.y = 0
        }
        if self.imageView.frame.maxX < self.superView.bounds.width {
            self.imageView.frame.origin.x = 0
        }
        if self.imageView.frame.maxY < self.superView.bounds.height {
            self.imageView.frame.origin.y = 0
        }
        
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
