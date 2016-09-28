//
//  ComplicationController.swift
//  EmonCMSWatch Extension
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {

  let mainController: MainController

  override init() {
    let extensionDelegate = WKExtension.shared().delegate! as! ExtensionDelegate
    self.mainController = extensionDelegate.mainController

    super.init()
  }

  func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
    handler([])
  }

  func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
    handler(.hideOnLockScreen)
  }

  func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
    let viewModel = self.mainController.complicationViewModel
    let template = self.template(for: complication, feed: viewModel.currentFeedData)
    handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
  }

  func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    let template = self.template(for: complication, feed: ComplicationViewModel.placeholderFeedData())
    handler(template)
  }

  private func template(for complication: CLKComplication, feed: ComplicationViewModel.FeedData?) -> CLKComplicationTemplate {
    let template: CLKComplicationTemplate

    if let feed = feed {
      let name = CLKSimpleTextProvider(text: feed.name)
      let value = CLKSimpleTextProvider(text: feed.value)

      switch complication.family {
      case .modularSmall:
        let t = CLKComplicationTemplateModularSmallStackText()
        t.line1TextProvider = name
        t.line2TextProvider = value
        template = t
      case .modularLarge:
        let t = CLKComplicationTemplateModularLargeTallBody()
        t.headerTextProvider = name
        t.bodyTextProvider = value
        template = t
      case .circularSmall:
        let t = CLKComplicationTemplateCircularSmallStackText()
        t.line1TextProvider = name
        t.line2TextProvider = value
        template = t
      case .extraLarge:
        let t = CLKComplicationTemplateExtraLargeStackText()
        t.line1TextProvider = name
        t.line2TextProvider = value
        template = t
      case .utilitarianLarge:
        let t = CLKComplicationTemplateUtilitarianLargeFlat()
        t.textProvider = value
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Utilitarian")!)
        template = t
      case .utilitarianSmall:
        let t = CLKComplicationTemplateUtilitarianSmallSquare()
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      case .utilitarianSmallFlat:
        let t = CLKComplicationTemplateUtilitarianSmallFlat()
        t.textProvider = value
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      }
    } else {
      switch complication.family {
      case .modularSmall:
        let t = CLKComplicationTemplateModularSmallSimpleImage()
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      case .modularLarge:
        let t = CLKComplicationTemplateModularLargeTallBody()
        t.headerTextProvider = CLKSimpleTextProvider(text: "Emoncms")
        t.bodyTextProvider = CLKSimpleTextProvider(text: "Select feed in iOS app")
        template = t
      case .circularSmall:
        let t = CLKComplicationTemplateCircularSmallSimpleImage()
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      case .extraLarge:
        let t = CLKComplicationTemplateExtraLargeStackText()
        t.line1TextProvider = CLKSimpleTextProvider(text: "Emoncms")
        t.line2TextProvider = CLKSimpleTextProvider(text: "Select feed in iOS app")
        template = t
      case .utilitarianLarge:
        let t = CLKComplicationTemplateUtilitarianLargeFlat()
        t.textProvider = CLKSimpleTextProvider(text: "Emoncms")
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Utilitarian")!)
        template = t
      case .utilitarianSmall:
        let t = CLKComplicationTemplateUtilitarianSmallSquare()
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      case .utilitarianSmallFlat:
        let t = CLKComplicationTemplateUtilitarianSmallFlat()
        t.textProvider = CLKSimpleTextProvider(text: "Emoncms")
        t.imageProvider = CLKImageProvider(onePieceImage: UIImage.init(named: "Complication/Circular")!)
        template = t
      }
    }

    return template
  }

}
