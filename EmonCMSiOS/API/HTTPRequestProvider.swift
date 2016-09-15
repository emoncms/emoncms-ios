//
//  HTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

protocol HTTPRequestProvider {

  func request(url: URL) -> Observable<Data>

}
