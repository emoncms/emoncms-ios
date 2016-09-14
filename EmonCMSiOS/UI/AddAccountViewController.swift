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
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

    self.setupFormer()
    self.updateSaveButtonState()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
  }

  private dynamic func save() {
    guard self.canSave == true,
      let url = self.urlRow?.text,
      let apikey = self.apikeyRow?.text
      else {
        return
    }

    let account = Account(url: url, apikey: apikey)
    account.validate()
      .observeOn(MainScheduler.instance)
      .subscribe(
        onError: { [weak self] _ in
          guard let strongSelf = self else { return }
          let alert = UIAlertController(title: "Error", message: "Couldn't talk to Emoncms. Are the credentials correct?", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
          strongSelf.present(alert, animated: true, completion: nil)
        },
        onCompleted: { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.delegate?.addAccountViewController(controller: strongSelf, didFinishWithAccount: account)
        })
      .addDisposableTo(self.disposeBag)
  }

  private var canSave: Bool {
    return !(self.urlRow?.text?.isEmpty ?? true) && !(self.apikeyRow?.text?.isEmpty ?? true)
  }

  private func updateSaveButtonState() {
    self.navigationItem.rightBarButtonItem?.isEnabled = self.canSave
  }

  private func setupFormer() {
    let urlRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.keyboardType = .URL
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms instance URL"
      }.onTextChanged { [weak self] _ in
        self?.updateSaveButtonState()
    }

    let apikeyRow = TextFieldRowFormer<FormTextFieldCell>() {
      $0.textField.font = .systemFont(ofSize: 15)
      $0.textField.autocapitalizationType = .none
      $0.textField.autocorrectionType = .no
      }.configure {
        $0.placeholder = "Emoncms API read Key"
      }.onTextChanged { [weak self] _ in
        self?.updateSaveButtonState()
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

  private func presentScanQR() {
    self.performSegue(withIdentifier: Segues.scanQR.rawValue, sender: self)
  }

  fileprivate func updateWithAccount(_ account: Account) {
    self.urlRow?.text = account.url
    self.apikeyRow?.text = account.apikey
    self.urlRow?.update()
    self.apikeyRow?.update()
    self.updateSaveButtonState()
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
