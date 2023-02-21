//
//  CustomBtton.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/09.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit

import UIKit

@IBDesignable
class CustomButton: UIButton {
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      customDesign()
    }
    
    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      customDesign()
    }
    
    override func prepareForInterfaceBuilder() {
      super.prepareForInterfaceBuilder()
      customDesign()
    }
    
    private func customDesign() {
      // デザインのカスタマイズ内容
        // 影の色を設定
        layer.shadowColor = UIColor.black.cgColor
        // 影の方向を設定 （下方向）
        layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        // 影の色の濃さを設定
        layer.shadowOpacity = 0.6
        // 影で囲う厚さ設定
        layer.shadowRadius = 0.2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // 指が画面に触れた時
        UIView.animate(withDuration: 0.01) {
            // 影の色を透明にする
            self.layer.shadowColor = UIColor.clear.cgColor
            // 下方向に動かす
            self.transform = self.transform.translatedBy(x: 0, y: 3)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // 指が画面から離れた時
        UIView.animate(withDuration: 0.01) {
            // 影の色を黒にする
            self.layer.shadowColor = UIColor.black.cgColor
            // 元の位置に戻す
            self.transform = CGAffineTransform.identity
        }
    }
}
