//
//  TimeUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/20/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

struct TimeUtils {

    static func toDisplayTime(_ timeInSeconds: Int) -> String {
        let numMin = timeInSeconds / 60
        let numSec = timeInSeconds % 60

        let secString: String = numSec < 10 ? "0"+String(numSec) : String(numSec)
        return String(numMin) + ":" + secString
    }
}
