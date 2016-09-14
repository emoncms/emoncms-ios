//
//  AddAccountViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import Former

protocol AddAccountViewControllerDelegate: class {
  func addAccountViewController(controller: AddAccountViewController, didFinishWithAccount account: Account)
}

class AddAccountViewController: FormViewController {

  var viewModel: AddAccountViewModel!

  weak var delegate: AddAccountViewControllerDelegate?

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
    let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.keyboardType = .URL
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms instance URL"
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.url.value = text
    }

    let apikeyRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms API read Key"
      }.onTextChanged { [weak self] text in
        guard let strongSelf = self else { return }
        strongSelf.viewModel.apikey.value = text
    }

    let scanQRRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Scan QR Code"
      }.onSelected { [weak self] _ in
        self?.presentScanQR()
    }

    self.urlRow = urlRow
    self.apikeyRow = apikeyRow
    self.scanQRRow = scanQRRow

    let section = SectionFormer(rowFormer: urlRow, apikeyRow, scanQRRow)
    former.append(sectionFormer: section)
  }

  private func setupBindings() {
    self.viewModel.canSave()
      .asDriver(onErrorJustReturn: false)
      .drive(self.navigationItem.rightBarButtonItem!.rx.enabled)
      .addDisposableTo(self.disposeBag)

    Observable
      .combineLatest(self.navigationItem.rightBarButtonItem!.rx.tap, self.viewModel.canSave().asObservable()) { $1 }
      .filter { $0 == true }
      .flatMapLatest { [weak self] _ -> Observable<Account> in
        guard let strongSelf = self else { return Observable.never() }

        let url = strongSelf.viewModel.url.value
        let apikey = strongSelf.viewModel.apikey.value

        let account = Account(url: url, apikey: apikey)
        return account.validate()
      }
      .observeOn(MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] account in
          guard let strongSelf = self else { return }
          strongSelf.delegate?.addAccountViewController(controller: strongSelf, didFinishWithAccount: account)
        },
        onError: { [weak self] _ in
          guard let strongSelf = self else { return }
          let alert = UIAlertController(title: "Error", message: "Couldn't talk to Emoncms. Are the credentials correct?", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
          strongSelf.present(alert, animated: true, completion: nil)
        })
      .addDisposableTo(self.disposeBag)
  }

  private func presentScanQR() {
    self.performSegue(withIdentifier: Segues.scanQR.rawValue, sender: self)
  }

  fileprivate func updateWithAccount(_ account: Account) {
    self.viewModel.url.value = account.url
    self.viewModel.apikey.value = account.apikey
    self.urlRow?.text = account.url
    self.urlRow?.update()
    self.apikeyRow?.text = account.apikey
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

  func addAccountQRViewController(controller: AddAccountQRViewController, didFinishWithAccount account: Account) {
    self.updateWithAccount(account)
    self.dismiss(animated: true, completion: nil)
  }

  func addAccountQRViewControllerDidCancel(controller: AddAccountQRViewController) {
    self.dismiss(animated: true, completion: nil)
  }

}
