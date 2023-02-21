//
//  CustomTextField.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/08.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {
    
    // コピーとペーストを禁止にする
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) || action == #selector(paste(_:)) {
            return false
        }
        return true
    }
}
