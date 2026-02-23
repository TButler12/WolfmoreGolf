//
//  ProGateViewController.swift
//  WolfmoreGolf
//
//  Created by Tom BUTLER on 2/23/26.
//

import UIKit

final class ProGateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Pro"

        if #available(iOS 15.0, *) {
            let vc = ProViewController() // your programmatic Pro VC (StoreKit2)
            addChild(vc)
            view.addSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                vc.view.topAnchor.constraint(equalTo: view.topAnchor),
                vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            vc.didMove(toParent: self)
        } else {
            // iOS 14 or earlier fallback
            let label = UILabel()
            label.text = "Pro upgrades require iOS 15 or newer."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            ])
        }
    }
}
