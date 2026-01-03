//
//  SolvedCrosswordFilteredList.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/15/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

enum SolvedCrosswordGraphStat {
    case NUM_PUZZLES,
     NUM_CLUES,
     AVG_TIME
}

struct SolvedCrosswordStatistics: View {
    @FetchRequest var fetchRequest: FetchedResults<SolvedCrossword>
    var graphStat: SolvedCrosswordGraphStat
    
    init(afterDate: Date, outletName: String, graphStatEnum: SolvedCrosswordGraphStat) {
        let timePredicate = NSPredicate(format: "date > %@", afterDate as NSDate)
        let outletPredicate = outletName.isEmpty
            ? NSPredicate.init(value: true)
            : NSPredicate(format: "outletName == %@", outletName)
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [timePredicate, outletPredicate])
        _fetchRequest = FetchRequest<SolvedCrossword>(sortDescriptors: [], predicate: predicateCompound)
        graphStat = graphStatEnum
    }
    let maxHeight = 200.0
    let colWidth = (UIScreen.main.bounds.size.width - 100)/7
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text(String(fetchRequest.count))
                    .bold()
                Text("Total Puzzles Solved")
            }
            HStack {
                Text(String(fetchRequest.map({$0.numClues}).reduce(0,+)))
                    .bold()
                Text("Total Clues Solved")
            }
            
            let groupByDay = Dictionary( grouping: fetchRequest, by: { $0.date!.getDayOfWeek() })
            let maxValue = Double(groupByDay.values.map({getValue(solvedCrosswordGroup: $0)}).max() ?? 10)
            let maxValueSafe = Int(maxValue) == 0 ? 10.0 : maxValue
            
            HStack(alignment: .bottom) {
                ForEach((1..<8)) { dayId in
                    let value = getValue(solvedCrosswordGroup: groupByDay[String(dayId)])
                    VStack {
                        let proportionOfMax: Double = Double(value) / maxValueSafe
                        ZStack {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(width: colWidth, height: proportionOfMax*maxHeight)
                                    .foregroundColor(Color(UIColor.systemBlue.withAlphaComponent(0.5)))
                                    .frame(alignment: .bottom)
                            }
                            
                            if (value > 0) {
                                VStack {
                                    Spacer()
                                    Text(String(format: "%g", value))
                                        .foregroundColor(Color(UIColor.systemBackground))
                                        .frame(alignment: .bottom)
                                        .padding(5)
                                }
                            }
                        }
                        .frame(alignment: .bottom)
                        Text(getDayName(dayId))
                    }
                    .frame(width: colWidth)
                }
            }.frame(maxHeight: maxHeight+30)
        }
    }
    
    func getValue(solvedCrosswordGroup: Optional<[FetchedResults<SolvedCrossword>.Element]>) -> Double {
        if (self.graphStat == SolvedCrosswordGraphStat.NUM_PUZZLES) {
            return Double(solvedCrosswordGroup?.count ?? 0)
        } else if (self.graphStat == SolvedCrosswordGraphStat.NUM_CLUES) {
            return Double(solvedCrosswordGroup?.map({Double($0.numClues)}).reduce(0,+) ?? 0.0)
        } else if (self.graphStat == SolvedCrosswordGraphStat.AVG_TIME) {
            let count = Double(solvedCrosswordGroup?.count ?? 0)
            let totalTime = solvedCrosswordGroup?.map({$0.solveTime}).reduce(0,+) ?? 0
            return count == 0 ? 0.0 : (Double(totalTime) / count)
        }
        return 0.0
    }
    
    func getDayName(_ dayId: Int) -> String {
        var dayName: String
        switch dayId {
            case (1):
                dayName = "Mon"
            case (2):
                dayName = "Tue"
            case (3):
                dayName = "Wed"
            case (4):
                dayName = "Thu"
            case (5):
                dayName = "Fri"
            case (6):
                dayName = "Sat"
            case (7):
                dayName = "Sun"
            default:
                dayName = "Unk"
        }
        return dayName
    }
    
}
