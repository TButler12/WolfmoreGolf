//
//  KeyboardHelpers.swift
//  Wolfmore-7Man
//
//  Created by Tom BUTLER on 10/10/25.
//
import UIKit

extension UIViewController {
    
    /// Unique name to avoid collisions with VC methods
    

    /// Convenience: attach the same Done toolbar to many fields
    func kbAttachDoneToolbar(to fields: [UITextField]) {
        let bar = kbMakeDoneToolbar()
        fields.forEach { $0.inputAccessoryView = bar }
    }

    /// Tap anywhere to dismiss
    func kbEnableTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(kbDismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}
extension UIViewController {
    @objc func kbDismissKeyboard() { view.endEditing(true) }

    func kbMakeDoneToolbar() -> UIToolbar {
        let bar = UIToolbar(); bar.sizeToFit()
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let done = UIBarButtonItem(title: "Done", style: .done,
                                   target: self, action: #selector(kbDismissKeyboard))
        bar.items = [flex, done]
        return bar
    }
}
