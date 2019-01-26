//
//  SecondaryViewController.swift
//  RxAppState_Example
//
//  Created by Jörn Schoppe on 28.10.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAppState

class SecondaryViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var stackView: UIStackView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        rx.viewState
            .map(label)
            .subscribe(onNext: { [weak self] label in
                self?.stackView.addArrangedSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.heightAnchor.constraint(equalToConstant: 40).isActive = true
            })
            .disposed(by: disposeBag)
    }
    
    func label(for state: ViewControllerViewState) -> UILabel {
        let label = UILabel()
        label.font = UIFont(name: "Futura-Medium", size: 17)
        label.textAlignment = .center
        label.textColor = .white
        label.text = String(describing: state)
        switch state {
        case .viewWillAppear:
            label.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        case .viewDidAppear:
            label.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        case .viewWillDisappear:
            label.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        case .viewDidDisappear:
            label.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        case .viewDidLoad:
            label.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        case .viewDidLayoutSubviews:
            label.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        }
        
        return label
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }
}
