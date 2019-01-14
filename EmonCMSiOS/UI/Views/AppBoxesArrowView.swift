//
//  AppBoxesArrowView.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import CoreGraphics

final class AppBoxesArrowView: UIView {

  enum Direction {
    case up
    case down
    case left
    case right
  }

  var value: Double = 0.0
  var unit: String = "kWh"
  var direction: Direction = .up
  var arrowColor: UIColor = UIColor.darkGray

  private var valueLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupLabels()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setupLabels()
  }

  private func setupLabels() {
    let valueLabel = UILabel(frame: .zero)
    valueLabel.font = UIFont.systemFont(ofSize: 16.0)
    valueLabel.textAlignment = .center
    self.addSubview(valueLabel)
    self.valueLabel = valueLabel
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let bounds = self.bounds
    let arrowSize = bounds.height / 4.0

    let valueFrame: CGRect
    switch direction {
    case .up:
      valueFrame = CGRect(x: 0, y: arrowSize, width: bounds.width, height: bounds.height - arrowSize)
    case .down:
      valueFrame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - arrowSize)
    case .left:
      valueFrame = CGRect(x: arrowSize, y: 0, width: bounds.width - arrowSize, height: bounds.height)
    case .right:
      valueFrame = CGRect(x: 0, y: 0, width: bounds.width - arrowSize, height: bounds.height)
    }
    self.valueLabel.frame = valueFrame

    self.valueLabel.text = "\(self.value.prettyFormat(decimals: 1)) \(self.unit)"
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }

    context.saveGState()
    defer { context.restoreGState() }

    UIGraphicsPushContext(context)
    defer { UIGraphicsPopContext() }

    let bounds = self.bounds
    let sizeA = bounds.height / 4.0
    let sizeB = sizeA / 1.5

    let path = CGMutablePath.init()
    switch self.direction {
    case .up:
      path.move(to: CGPoint(x: bounds.midX, y: 0))
      path.addLine(to: CGPoint(x: bounds.midX + sizeB, y: sizeA))
      path.addLine(to: CGPoint(x: bounds.midX - sizeB, y: sizeA))
    case .down:
      path.move(to: CGPoint(x: bounds.midX, y: bounds.maxY))
      path.addLine(to: CGPoint(x: bounds.midX + sizeB, y: bounds.maxY - sizeA))
      path.addLine(to: CGPoint(x: bounds.midX - sizeB, y: bounds.maxY - sizeA))
    case .left:
      path.move(to: CGPoint(x: 0, y: bounds.midY))
      path.addLine(to: CGPoint(x: sizeA, y: bounds.midY - sizeB))
      path.addLine(to: CGPoint(x: sizeA, y: bounds.midY + sizeB))
    case .right:
      path.move(to: CGPoint(x: bounds.maxX, y: bounds.midY))
      path.addLine(to: CGPoint(x: bounds.maxX - sizeA, y: bounds.midY - sizeB))
      path.addLine(to: CGPoint(x: bounds.maxX - sizeA, y: bounds.midY + sizeB))
    }

    context.addPath(path)
    context.setFillColor(self.arrowColor.cgColor)
    context.fillPath()
  }

}
