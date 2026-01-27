//
//  TimeUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/20/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import Foundation

struct TimeUtils {

    static func toDisplayTime(_ timeInSeconds: Int) -> String {
        let numMin = timeInSeconds / 60
        let numSec = timeInSeconds % 60

        let secString: String = numSec < 10 ? "0"+String(numSec) : String(numSec)
        return String(numMin) + ":" + secString
    }
}

extension Date {
    func startOfYear() -> Date {
        return Calendar.current.date(from: Calendar.current
            .dateComponents([.year],from: Calendar.current.startOfDay(for: self)))!
    }

    func subtractMonths(_ numMonths: Int) -> Date {
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month,
                                                                      value: -1 * numMonths, to: self)!)
    }

    func subtractWeeks(_ numWeeks: Int) -> Date {
        return Calendar.current.startOfDay(for: (Calendar.current.date(byAdding: .weekOfYear,
                                                                       value: -1 * numWeeks, to: self)!))
    }

    func getDayOfWeek() -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-AI")
        dateFormatter.dateFormat = "e"
        return Int(dateFormatter.string(from: self)) ?? 0
    }

    static func getDay(_ dayId: Int) -> String {
        // 1 is monday, 7 is sunday
        var components = DateComponents()
        // this is a sunday, so adding 1 day to it will give monday
        components.year = 2022
        components.month = 7
        components.day = 31
        let date: Date = Calendar.current.date(from: components)!
        let newDate: Date = Calendar.current.startOfDay(for: (Calendar.current.date(byAdding: .day,
                                                                                    value: dayId,
                                                                                    to: date)!))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-AI")
        dateFormatter.dateFormat = "EE"
        return dateFormatter.string(from: newDate)
    }
}
