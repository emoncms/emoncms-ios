//
//  EmonCMSTestCase.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick

class EmonCMSTestCase: QuickSpec {

  var dataDirectory: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("tests")
  }

}
