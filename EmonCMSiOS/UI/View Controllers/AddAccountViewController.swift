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
  private var apikeyRow: TextFieldRowFormer<FormTextFieldCell>?
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
    let nameRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.keyboardType = .URL
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms instance name"
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
        $0.placeholder = "Emoncms instance URL"
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.url.accept(text)
    }

    let apikeyRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms API read Key"
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.apikey.accept(text)
    }

    let scanQRRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Scan QR Code"
      }.onSelected { [weak self] _ in
        self?.presentScanQR()
    }

    self.nameRow = nameRow
    self.urlRow = urlRow
    self.apikeyRow = apikeyRow
    self.scanQRRow = scanQRRow

    let section = SectionFormer(rowFormer: nameRow, urlRow, apikeyRow, scanQRRow)
    self.former.append(sectionFormer: section)
  }

  private func setupBindings() {
    let action = CocoaAction(enabledIf: self.viewModel.canSave()) { [weak self] _ -> Observable<Void> in
      guard let strongSelf = self else { return Observable.empty() }

      return strongSelf.viewModel.validate()
        .observeOn(MainScheduler.asyncInstance)
        .flatMap { [weak self] account -> Observable<String> in
          guard let strongSelf = self else { return Observable.empty() }
          return strongSelf.viewModel.saveAccount(withUrl: account.url, apiKey: account.apiKey)
        }
        .do(onNext: { [weak self] accountId in
          guard let strongSelf = self else { return }
          strongSelf.finishedSubject.onNext(accountId)
        })
        .catchError { [weak self] error in
          guard let strongSelf = self else { return Observable.empty() }

          AppLog.info("Login failed: \(error)")

          let message: String
          if let error = error as? AddAccountViewModel.AddAccountError {
            switch error {
            case .httpsRequired:
              message = "HTTPS is required."
            case .invalidCredentials:
              message = "The credentials are invalid."
            case .networkFailed:
              message = "The connection failed. Please try again."
            }
          } else {
            message = "An unknown error ocurred."
          }

          let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
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
    self.viewModel.apikey.accept(accountCredentials.apiKey)
    self.urlRow?.text = accountCredentials.url
    self.urlRow?.update()
    self.apikeyRow?.text = accountCredentials.apiKey
    self.apikeyRow?.update()
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
