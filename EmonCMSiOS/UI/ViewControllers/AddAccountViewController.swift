//
//  AddAccountViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

import Former

final class AddAccountViewController: FormViewController {

  var viewModel: AddAccountViewModel!

  lazy var finished: AnyPublisher<String?, Never> = {
    return self.finishedSubject.eraseToAnyPublisher()
  }()
  private var finishedSubject = PassthroughSubject<String?, Never>()

  private var nameRow: TextFieldRowFormer<FormTextFieldCell>?
  private var urlRow: TextFieldRowFormer<FormTextFieldCell>?
  private var usernameRow: TextFieldRowFormer<FormTextFieldCell>?
  private var passwordRow: TextFieldRowFormer<FormTextFieldCell>?
  private var unamepwordApiKeySeperatorView: LabelViewFormer<FormLabelFooterView>?
  private var apiKeyRow: TextFieldRowFormer<FormTextFieldCell>?
  private var scanQRRow: LabelRowFormer<FormLabelCell>?

  private var cancellables = Set<AnyCancellable>()

  fileprivate enum Segues: String {
    case scanQR
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Account Details"

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

    self.setupFormer()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }

  private func setupFormer() {
    let viewModel = self.viewModel!

    let nameRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      }.configure {
        $0.placeholder = "Name"
        $0.text = viewModel.name
      }.onTextChanged { [weak self] text in
        guard let self = self else { return }
        self.viewModel.name = text
    }

    let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.keyboardType = .URL
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "URL"
        $0.text = viewModel.url
      }.onTextChanged { [weak self] text in
        guard let self = self else { return }
        self.viewModel.url = text
    }

    let usernameRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Username"
        $0.text = viewModel.username
      }.onTextChanged { [weak self] text in
        guard let self = self else { return }
        self.viewModel.username = text
    }

    let passwordRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.isSecureTextEntry = true
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Password"
        $0.text = viewModel.password
      }.onTextChanged { [weak self] text in
        guard let self = self else { return }
        self.viewModel.password = text
    }

    let apiKeyRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "API read key"
        $0.text = viewModel.apiKey
      }.onTextChanged { [weak self] text in
        guard let self = self else { return }
        self.viewModel.apiKey = text
    }

    let scanQRRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Scan QR Code"
      }.onSelected { [weak self] _ in
        self?.presentScanQR()
    }

    let unamepwordApiKeySeperatorView = LabelViewFormer<FormLabelFooterView>() {
      $0.titleLabel.textColor = .darkGray
      }.configure {
        $0.text = "\u{2014} or \u{2014}"
    }

    self.nameRow = nameRow
    self.urlRow = urlRow
    self.usernameRow = usernameRow
    self.passwordRow = passwordRow
    self.unamepwordApiKeySeperatorView = unamepwordApiKeySeperatorView
    self.apiKeyRow = apiKeyRow
    self.scanQRRow = scanQRRow

    let section1 = SectionFormer(rowFormer: nameRow, urlRow)
    let section2 = SectionFormer(rowFormer: usernameRow, passwordRow)
      .set(footerViewFormer: unamepwordApiKeySeperatorView)
    let section3 = SectionFormer(rowFormer: apiKeyRow)
    let section4 = SectionFormer(rowFormer: scanQRRow)
    self.former.append(sectionFormer: section1, section2, section3, section4)
  }

  private func setupBindings() {
    let barButtonItem = self.navigationItem.rightBarButtonItem!

    self.viewModel.canSave()
      .assign(to: \.isEnabled, on: barButtonItem)
      .store(in: &self.cancellables)

    barButtonItem.publisher()
      .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty<Void, Never>().eraseToAnyPublisher() }

        self.tableView.resignFirstResponder()
        self.tableView.isUserInteractionEnabled = false

        return self.viewModel.saveAccount()
          .handleEvents(receiveOutput: { [weak self] accountId in
            guard let self = self else { return }
            self.finishedSubject.send(accountId)
          })
          .catch { [weak self] error -> AnyPublisher<String, Never> in
            guard let self = self else { return Empty<String, Never>().eraseToAnyPublisher() }

            AppLog.info("Login failed: \(error)")

            self.tableView.isUserInteractionEnabled = true

            let message: String
            switch error {
            case .urlNotValid:
              message = "URL is not valid."
            case .httpsRequired:
              message = "HTTPS is required. This is a requirement of iOS. Please ensure you are using HTTPS with a valid certificate."
            case .invalidCredentials:
              message = "The credentials are invalid."
            case .networkFailed:
              message = "The connection failed. Please try again."
            case .saveFailed:
              message = "Something failed. Please try again."
            }

            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)

            return Empty<String, Never>().eraseToAnyPublisher()
        }
        .becomeVoid()
        .eraseToAnyPublisher()
      }
    .sink { _ in }
    .store(in: &self.cancellables)
  }

  private func presentScanQR() {
    self.performSegue(withIdentifier: Segues.scanQR.rawValue, sender: self)
  }

  fileprivate func updateWithAccountCredentials(_ accountCredentials: AccountCredentials) {
    self.viewModel.url = accountCredentials.url
    self.viewModel.apiKey = accountCredentials.apiKey
    self.urlRow?.text = accountCredentials.url
    self.urlRow?.update()
    self.apiKeyRow?.text = accountCredentials.apiKey
    self.apiKeyRow?.update()
  }

}

extension AddAccountViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.scanQR.rawValue {
      let navController = segue.destination as! UINavigationController
      let viewController = navController.topViewController! as! AddAccountQRViewController
      viewController.delegate = self
    }
  }

}

extension AddAccountViewController: AddAccountQRViewControllerDelegate {

  func addAccountQRViewController(controller: AddAccountQRViewController, didFinishWithAccountCredentials accountCredentials: AccountCredentials) {
    self.updateWithAccountCredentials(accountCredentials)
    self.dismiss(animated: true, completion: nil)
  }

  func addAccountQRViewControllerDidCancel(controller: AddAccountQRViewController) {
    self.dismiss(animated: true, completion: nil)
  }

}
