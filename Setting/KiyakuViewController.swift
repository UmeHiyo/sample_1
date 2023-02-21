//
//  KiyakuViewController.swift
//  acote
//
//  Created by Yuiko Umekawa on 2021/01/12.
//  Copyright © 2021 Yuiko Umekawa. All rights reserved.
//

import UIKit

class KiyakuViewController: UIViewController {

    @IBOutlet weak var kiyakuView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let fileUrl = Bundle.main.url(forResource: "kiyaku", withExtension: "txt")!
        // テキストファイルから文字列を読み出し
        do {
            let text = try String(contentsOf: fileUrl)
            kiyakuView.text = text
        } catch {
            print("Error: \(error)")
        }

        // Do any additional setup after loading the view.
    }
    

    @IBAction func cancel(_ sender: Any) {
        let accountViewController = self.presentingViewController as! AccountViewController
        accountViewController.isAgreed = false
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func ok(_ sender: Any) {
        let accountViewController = self.presentingViewController as! AccountViewController
        accountViewController.isAgreed = true
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
