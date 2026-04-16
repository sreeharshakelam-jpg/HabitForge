import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Descriptors
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "ForgeProgress",
                displayName: "Virtue Forge Progress",
                supportedFamilies: [
                    .circularSmall,
                    .modularSmall,
                    .graphicCircular,
                    .graphicBezel,
                    .graphicCorner
                ]
            )
        ]
        handler(descriptors)
    }

    // MARK: - Timeline
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let progress = UserDefaults.standard.double(forKey: "complication_progress")
        let streak = UserDefaults.standard.integer(forKey: "complication_streak")
        let entry = createEntry(progress: progress, streak: streak, for: complication, date: Date())
        handler(entry)
    }

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date().addingTimeInterval(60 * 60 * 24))
    }

    private func createEntry(progress: Double, streak: Int, for complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?

        switch complication.family {
        case .graphicCircular:
            let t = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            t.centerTextProvider = CLKSimpleTextProvider(text: "\(Int(progress * 100))%")
            t.bottomTextProvider = CLKSimpleTextProvider(text: "\(streak)🔥")
            t.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColors: [.purple, .blue], gaugeColorLocations: [0, 1], fillFraction: Float(progress))
            template = t

        case .circularSmall:
            let t = CLKComplicationTemplateCircularSmallRingText()
            t.textProvider = CLKSimpleTextProvider(text: "\(streak)")
            t.fillFraction = Float(progress)
            t.ringStyle = .closed
            template = t

        case .graphicCorner:
            let t = CLKComplicationTemplateGraphicCornerGaugeText()
            t.outerTextProvider = CLKSimpleTextProvider(text: "\(streak)🔥")
            t.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColors: [.purple], gaugeColorLocations: [0], fillFraction: Float(progress))
            template = t

        default:
            break
        }

        guard let t = template else { return nil }
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: t)
    }
}
