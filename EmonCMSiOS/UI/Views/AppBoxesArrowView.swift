//
//  AppBoxesArrowView.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import CoreGraphics

@IBDesignable final class AppBoxesArrowView: UIView {

  enum Direction {
    case up
    case down
    case left
    case right
  }

  @IBInspectable var value: Double = 0 { didSet { hasSetValue = true; self.updateLabels() } }
  @IBInspectable var unit: String = "kWh" { didSet { self.updateLabels() } }
  @IBInspectable var arrowColor: UIColor = UIColor.darkGray { didSet { self.setNeedsDisplay() } }
  @IBInspectable var arrowSize: CGFloat = 10.0 { didSet { self.setNeedsUpdateConstraints() } }
  var direction: Direction = .up { didSet { self.setNeedsUpdateConstraints(); self.setNeedsDisplay() } }

  private let valueLabel = UILabel(frame: .zero)
  private var internalConstraints = [NSLayoutConstraint]()
  private var hasSetValue = false;

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupLabels()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setupLabels()
  }

  private func setupLabels() {
    self.translatesAutoresizingMaskIntoConstraints = false

    self.valueLabel.font = UIFont.systemFont(ofSize: 16.0)
    self.valueLabel.textAlignment = .center
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.valueLabel)

    self.updateLabels()
  }

  private func updateLabels() {
    if self.hasSetValue {
      self.valueLabel.text = "\(self.value.prettyFormat(decimals: 1)) \(self.unit)"
    } else {
      self.valueLabel.text = "-"
    }
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }

    context.saveGState()
    defer { context.restoreGState() }

    UIGraphicsPushContext(context)
    defer { UIGraphicsPopContext() }

    let bounds = self.bounds
    let sizeA = self.arrowSize
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

  override func updateConstraints() {
    super.updateConstraints()

    self.removeConstraints(self.internalConstraints)
    self.internalConstraints.removeAll()

    let views = ["valueLabel": self.valueLabel]
    let metrics = ["spacing": self.arrowSize + 2]

    switch self.direction {
    case .up:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-spacing-[valueLabel]-2-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    case .down:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[valueLabel]-spacing-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    case .left, .right:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[valueLabel]-2-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    }

    switch self.direction {
    case .up, .down:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[valueLabel]-2-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    case .left:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-spacing-[valueLabel]-2-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    case .right:
      self.internalConstraints +=
        NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[valueLabel]-spacing-|",
                                       options: [],
                                       metrics: metrics,
                                       views: views)
    }

    self.addConstraints(self.internalConstraints)
  }

}
