//
//  AddAccountViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Action
import Former

final class AddAccountViewController: FormViewController {

  var viewModel: AddAccountViewModel!

  lazy var finished: Driver<String?> = {
    return self.finishedSubject.asDriver(onErrorJustReturn: nil)
  }()
  private var finishedSubject = PublishSubject<String?>()

  private var nameRow: TextFieldRowFormer<FormTextFieldCell>?
  private var urlRow: TextFieldRowFormer<FormTextFieldCell>?
  private var usernameRow: TextFieldRowFormer<FormTextFieldCell>?
  private var passwordRow: TextFieldRowFormer<FormTextFieldCell>?
  private var unamepwordApiKeySeperatorView: LabelViewFormer<FormLabelFooterView>?
  private var apiKeyRow: TextFieldRowFormer<FormTextFieldCell>?
  private var scanQRRow: LabelRowFormer<FormLabelCell>?

  private let disposeBag = DisposeBag()

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
        $0.text = viewModel.name.value
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.name.accept(text)
    }

    let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.keyboardType = .URL
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "URL"
        $0.text = viewModel.url.value
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.url.accept(text)
    }

    let usernameRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Username"
        $0.text = viewModel.username.value
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.username.accept(text)
    }

    let passwordRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.isSecureTextEntry = true
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Password"
        $0.text = viewModel.password.value
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.password.accept(text)
    }

    let apiKeyRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "API read key"
        $0.text = viewModel.apiKey.value
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.apiKey.accept(text)
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
    let action = CocoaAction(enabledIf: self.viewModel.canSave()) { [weak self] _ -> Observable<Void> in
      guard let strongSelf = self else { return Observable.empty() }

      strongSelf.tableView.resignFirstResponder()
      strongSelf.tableView.isUserInteractionEnabled = false

      return strongSelf.viewModel.saveAccount()
        .do(onNext: { [weak self] accountId in
          guard let strongSelf = self else { return }
          strongSelf.finishedSubject.onNext(accountId)
        })
        .catchError { [weak self] error in
          guard let strongSelf = self else { return Observable.empty() }

          AppLog.info("Login failed: \(error)")

          strongSelf.tableView.isUserInteractionEnabled = true

          let message: String
          if let error = error as? AddAccountViewModel.AddAccountError {
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
          } else {
            message = "An unknown error ocurred."
          }

          let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
          strongSelf.present(alert, animated: true, completion: nil)
          return Observable.empty()
        }
        .becomeVoid()
    }
    self.navigationItem.rightBarButtonItem!.rx.action = action
  }

  private func presentScanQR() {
    self.performSegue(withIdentifier: Segues.scanQR.rawValue, sender: self)
  }

  fileprivate func updateWithAccountCredentials(_ accountCredentials: AccountCredentials) {
    self.viewModel.url.accept(accountCredentials.url)
    self.viewModel.apiKey.accept(accountCredentials.apiKey)
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
