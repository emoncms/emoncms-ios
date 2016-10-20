//
//  AddAccountQRViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit
import AVFoundation

protocol AddAccountQRViewControllerDelegate: class {
  func addAccountQRViewController(controller: AddAccountQRViewController, didFinishWithAccount account: Account)
  func addAccountQRViewControllerDidCancel(controller: AddAccountQRViewController)
}

class AddAccountQRViewController: UIViewController {

  weak var delegate: AddAccountQRViewControllerDelegate?

  @IBOutlet var playerLayerView: UIView!

  private var captureSession: AVCaptureSession?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  fileprivate var foundAccount = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Scan Code"
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.checkCameraPermissionAndSetupStack()
    self.captureSession?.startRunning()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.captureSession?.stopRunning()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.videoPreviewLayer?.frame = self.playerLayerView.bounds
  }

  private dynamic func cancel() {
    self.delegate?.addAccountQRViewControllerDidCancel(controller: self)
  }

  private func checkCameraPermissionAndSetupStack() {
    guard self.captureSession == nil else { return }

    let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    switch authStatus {
    case .authorized:
      self.setupAVStack()
    case .notDetermined:
      self.askForCameraPermission()
    case .denied:
      self.presentCameraRequiredDialog()
    case .restricted:
      self.presentCameraRestrictedDialog()
    }
  }

  private func setupAVStack() {
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

    do {
      let captureSession = AVCaptureSession()

      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)

      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      captureSession.addOutput(captureMetadataOutput)
      captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

      if let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer.frame = self.playerLayerView.bounds
        self.videoPreviewLayer = videoPreviewLayer
        self.playerLayerView.layer.addSublayer(videoPreviewLayer)
      }

      self.captureSession = captureSession
      captureSession.startRunning()
    } catch {
      AppLog.error("Error setting up AV stack: \(error)")
    }
  }

  private func askForCameraPermission() {
    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (enabled) in
      DispatchQueue.main.async {
        if enabled {
          self.setupAVStack()
        } else {
          self.presentCameraRequiredDialog()
        }
      }
    }
  }

  private func presentCameraRequiredDialog() {
    let alert = UIAlertController(title: "Camera Required", message: "Camera access is required for QR code scanning to work. Turn on camera permission in Settings.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
      if let url = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

  private func presentCameraRestrictedDialog() {
    let alert = UIAlertController(title: "Camera Required", message: "Camera access is required for QR code scanning to work. Turn on camera permission in Settings.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

}

extension AddAccountQRViewController: AVCaptureMetadataOutputObjectsDelegate {

  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
    guard self.foundAccount == false else { return }

    guard let metadataObjects = metadataObjects,
      metadataObjects.count > 0
      else {
        return
    }

    guard let qrCode = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
      qrCode.type == AVMetadataObjectTypeQRCode,
      let string = qrCode.stringValue
      else {
        return
    }

    guard let result = EmonCMSAPI.extractAPIDetailsFromURLString(string) else {
      return
    }

    self.foundAccount = true
    DispatchQueue.main.async {
      let account = Account(uuid: UUID(), url: result.host, apikey: result.apikey)
      self.delegate?.addAccountQRViewController(controller: self, didFinishWithAccount: account)
    }
  }

}
