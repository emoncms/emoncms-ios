//
//  MyElectricAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Charts

class MyElectricAppViewController: UIViewController, AppViewController {

  var viewModel: MyElectricAppViewModel!

  var genericViewModel: AppViewModel! {
    get {
      return self.viewModel
    }
    set(vm) {
      self.viewModel = vm as! MyElectricAppViewModel
    }
  }

  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var useTodayLabel: UILabel!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var barChart: BarChartView!

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "My Electric"
  }

}
