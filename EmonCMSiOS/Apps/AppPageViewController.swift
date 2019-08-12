//
//  AppPageViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/02/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

class AppPageViewController: UIViewController {

  var viewModel: AppPageViewModel!

  @IBOutlet private var bannerView: UIView!
  @IBOutlet private var bannerLabel: UILabel!
  @IBOutlet private var bannerSpinner: UIActivityIndicatorView!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active = false
  }

  private func setupBindings() {
    self.viewModel.errors
      .sink(receiveValue: { [weak self] error in
        guard let self = self else { return }
        guard let error = error else { return }

        switch error {
        case .initialFailed:
          let alert = UIAlertController(title: "Error", message: "Failed to connect to emoncms. Please try again.", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        default:
          break
        }
      })
      .store(in: &self.cancellables)

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    self.viewModel.bannerBarState
      .sink(receiveValue: { [weak self] state in
        guard let self = self else { return }

        switch state {
        case .loading:
          self.bannerSpinner.startAnimating()
          self.bannerLabel.text = "Loading\u{2026}"
          self.bannerView.backgroundColor = UIColor.lightGray
        case .error(let message):
          self.bannerSpinner.stopAnimating()
          self.bannerLabel.text = message
          self.bannerView.backgroundColor = EmonCMSColors.ErrorRed
        case .loaded(let updateTime):
          self.bannerSpinner.stopAnimating()
          self.bannerLabel.text = "Last updated: \(dateFormatter.string(from: updateTime))"
          self.bannerView.backgroundColor = UIColor.lightGray
        }
      })
      .store(in: &self.cancellables)
  }

}
