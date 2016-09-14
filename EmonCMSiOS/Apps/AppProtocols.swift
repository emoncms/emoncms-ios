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

  var genericViewModel: AppViewModel! { get set }

}
