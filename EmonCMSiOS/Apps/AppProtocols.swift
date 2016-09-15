//
//  AppProtocols.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

protocol AppViewModel {}

protocol AppViewController: class {

  // TODO: There must be a better way to do this. Perhaps with an `associatedtype`?
  var genericViewModel: AppViewModel! { get set }

}
