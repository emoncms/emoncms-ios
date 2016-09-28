//
//  LogController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 28/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import CocoaLumberjack

class LogController {

  private let fileLogger: DDFileLogger

  init() {
    let filelogger = DDFileLogger()!
    filelogger.rollingFrequency = 60 * 60 * 24
    filelogger.logFileManager.maximumNumberOfLogFiles = 7
    DDLog.add(filelogger)
    self.fileLogger = filelogger
  }

}
