//
//  LogController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 28/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import XCGLogger

var AppLog: XCGLogger {
  guard LogController.shared.initialised else { fatalError("Logging not initialised yet!") }
  return LogController.shared.logger
}

final class LogController {
  static let shared = LogController()

  fileprivate var initialised: Bool
  private let fileManager: FileManager
  private let logDirectory: URL

  fileprivate let logger: XCGLogger
  private var fileDestination: FileDestination?

  private static let FileName: String = "log.txt"

  private init() {
    self.initialised = false
    self.fileManager = FileManager()

    let urls = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    let url = urls.last!.appendingPathComponent("logs")
    self.logDirectory = url

    let log = XCGLogger.default
    self.logger = log
  }

  private var mainLogFile: URL {
    return self.logDirectory.appendingPathComponent(LogController.FileName)
  }

  private func internalSetup() {
    self.ensureLogDirectoryExists()

    #if DEBUG
      let systemDestination = AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier)
      systemDestination.outputLevel = .debug
      systemDestination.showLogIdentifier = false
      systemDestination.showFunctionName = true
      systemDestination.showThreadName = true
      systemDestination.showLevel = true
      systemDestination.showFileName = true
      systemDestination.showLineNumber = true
      systemDestination.showDate = true
      self.logger.add(destination: systemDestination)
    #endif

    let logPath: URL = self.mainLogFile
    let fileDestination = FileDestination(writeToFile: logPath,
                                          identifier: XCGLogger.Constants.fileDestinationIdentifier)
    fileDestination.outputLevel = .debug
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true
    fileDestination.logQueue = XCGLogger.logQueue
    self.logger.add(destination: fileDestination)
    self.fileDestination = fileDestination
  }

  private func ensureLogDirectoryExists() {
    let url = self.logDirectory
    var isDirectory: ObjCBool = false
    let exists = self.fileManager.fileExists(atPath: url.absoluteString, isDirectory: &isDirectory)
    if !exists {
      do {
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("Failed to create log directory!")
      }
    } else if !isDirectory.boolValue {
      print("There's a file where we want to put our log directory!")
    }
  }

  func initialise() {
    self.internalSetup()
    self.initialised = true
    AppLog.logAppDetails()
  }

  var logFiles: [URL] {
    guard self.initialised else { return [] }

    let directory = self.logDirectory
    guard let enumerator = self.fileManager.enumerator(at: directory, includingPropertiesForKeys: nil, options: [],
                                                       errorHandler: nil) else {
      return []
    }

    var fileUrls: [URL] = []
    for case let file as URL in enumerator {
      if file.lastPathComponent.hasPrefix(LogController.FileName) {
        fileUrls.append(file)
      }
    }

    return fileUrls
  }

  func flushFile() {
    self.fileDestination?.flush()
  }
}
