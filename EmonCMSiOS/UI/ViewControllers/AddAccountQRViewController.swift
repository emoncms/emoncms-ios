//
//  AddAccountQRViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import AVFoundation
import UIKit

protocol AddAccountQRViewControllerDelegate: AnyObject {
  func addAccountQRViewController(controller: AddAccountQRViewController,
                                  didFinishWithAccountCredentials accountCredentials: AccountCredentials)
  func addAccountQRViewControllerDidCancel(controller: AddAccountQRViewController)
}

final class AddAccountQRViewController: UIViewController {
  weak var delegate: AddAccountQRViewControllerDelegate?

  @IBOutlet var playerLayerView: UIView!

  private var captureSession: AVCaptureSession?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  fileprivate var foundAccount = false

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Scan Code"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.AddAccountQRView
    self.navigationItem
      .leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel))
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

  @objc private dynamic func cancel() {
    self.delegate?.addAccountQRViewControllerDidCancel(controller: self)
  }

  private func checkCameraPermissionAndSetupStack() {
    guard self.captureSession == nil else { return }

    let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch authStatus {
    case .authorized:
      self.setupAVStack()
    case .notDetermined:
      self.askForCameraPermission()
    case .denied:
      self.presentCameraRequiredDialog()
    case .restricted:
      self.presentCameraRestrictedDialog()
    @unknown default:
      self.presentCameraRequiredDialog()
    }
  }

  private func setupAVStack() {
    guard let captureDevice = AVCaptureDevice.default(for: .video) else {
      AppLog.error("No capture device!")
      return
    }

    do {
      let captureSession = AVCaptureSession()

      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)

      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      captureSession.addOutput(captureMetadataOutput)
      captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

      let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
      videoPreviewLayer.frame = self.playerLayerView.bounds
      self.videoPreviewLayer = videoPreviewLayer
      self.playerLayerView.layer.addSublayer(videoPreviewLayer)

      self.captureSession = captureSession
      captureSession.startRunning()
    } catch {
      AppLog.error("Error setting up AV stack: \(error)")
    }
  }

  private func askForCameraPermission() {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { enabled in
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
    let alert = UIAlertController(title: "Camera Required",
                                  message: "Camera access is required for QR code scanning to work. Turn on camera permission in Settings.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

  private func presentCameraRestrictedDialog() {
    let alert = UIAlertController(title: "Camera Required",
                                  message: "Camera access is required for QR code scanning to work. Turn on camera permission in Settings.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
}

extension AddAccountQRViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(
    _ captureOutput: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection) {
    guard self.foundAccount == false else { return }

    guard metadataObjects.count > 0 else { return }

    guard let qrCode = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
      qrCode.type == AVMetadataObject.ObjectType.qr,
      let string = qrCode.stringValue
    else {
      return
    }

    guard let result = EmonCMSAPI.extractAPIDetailsFromURLString(string) else {
      return
    }

    self.foundAccount = true
    DispatchQueue.main.async {
      self.delegate?.addAccountQRViewController(controller: self, didFinishWithAccountCredentials: result)
    }
  }
}
