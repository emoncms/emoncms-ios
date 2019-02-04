//
//  AppPageViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/02/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class AppPageViewController: UIViewController {

  var viewModel: AppPageViewModel!

  @IBOutlet private var bannerView: UIView!
  @IBOutlet private var bannerLabel: UILabel!
  @IBOutlet private var bannerSpinner: UIActivityIndicatorView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active.accept(false)
  }

  private func setupBindings() {
    self.viewModel.errors
      .drive(onNext: { [weak self] error in
        guard let strongSelf = self else { return }
        guard let error = error else { return }

        switch error {
        case .initialFailed:
          let alert = UIAlertController(title: "Error", message: "Failed to connect to emoncms. Please try again.", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          strongSelf.present(alert, animated: true, completion: nil)
        default:
          break
        }
      })
      .disposed(by: self.disposeBag)

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    self.viewModel.bannerBarState
      .drive(onNext: { [weak self] state in
        guard let strongSelf = self else { return }

        switch state {
        case .loading:
          strongSelf.bannerSpinner.startAnimating()
          strongSelf.bannerLabel.text = "Loading\u{2026}"
          strongSelf.bannerView.backgroundColor = UIColor.lightGray
        case .error(let message):
          strongSelf.bannerSpinner.stopAnimating()
          strongSelf.bannerLabel.text = message
          strongSelf.bannerView.backgroundColor = EmonCMSColors.ErrorRed
        case .loaded(let updateTime):
          strongSelf.bannerSpinner.stopAnimating()
          strongSelf.bannerLabel.text = "Last updated: \(dateFormatter.string(from: updateTime))"
          strongSelf.bannerView.backgroundColor = UIColor.lightGray
        }
      })
      .disposed(by: self.disposeBag)
  }

}
