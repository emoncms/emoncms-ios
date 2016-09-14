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

  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Scan Code"
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
  }

  func cancel() {
    self.delegate?.addAccountQRViewControllerDidCancel(controller: self)
  }

  private func setupAVStack() {
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

    do {
      let captureSession = AVCaptureSession()

      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)

      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
      captureSession.addOutput(captureMetadataOutput)

      if let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer.frame = self.playerLayerView.layer.bounds
        self.videoPreviewLayer = videoPreviewLayer
        self.playerLayerView.layer.addSublayer(videoPreviewLayer)
      }

      self.captureSession = captureSession
      captureSession.startRunning()
    } catch {
      print("Error setting up AV stack: \(error)")
    }
  }

}

extension AddAccountQRViewController: AVCaptureMetadataOutputObjectsDelegate {

  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
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

    guard let url = URLComponents(string: string),
      let queryItems = url.queryItems
      else {
        print("No query parameters")
        return
    }

    var apikey: String? = nil
    for item in queryItems {
      if item.name == "apikey" {
        apikey = item.value
      }
    }

    if let apikey = apikey, let host = url.host {
      let account = Account(url: host, apikey: apikey)
      self.delegate?.addAccountQRViewController(controller: self, didFinishWithAccount: account)
    }
  }
  
}
