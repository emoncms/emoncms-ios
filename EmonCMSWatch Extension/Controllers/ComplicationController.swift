//
//  ComplicationController.swift
//  EmonCMSWatch Extension
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {

  func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
    handler([])
  }

  func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
    handler(.hideOnLockScreen)
  }

  func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
    let template = self.template(for: complication, feed: FeedViewModel())
    handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template))
  }

  func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
    let template = self.template(for: complication, feed: FeedViewModel())
    handler(template)
  }

  private func template(for complication: CLKComplication, feed: FeedViewModel) -> CLKComplicationTemplate {
    let template: CLKComplicationTemplate

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

    return template
  }

}
