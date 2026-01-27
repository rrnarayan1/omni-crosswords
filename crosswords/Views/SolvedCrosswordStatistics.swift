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
    
    init(afterDate: Date, outletName: String?, graphStatEnum: SolvedCrosswordGraphStat) {
        let timePredicate = NSPredicate(format: "date > %@", afterDate as NSDate)
        let outletPredicate = outletName == nil || outletName!.isEmpty
            ? NSPredicate.init(value: true)
            : NSPredicate(format: "outletName == %@", outletName!)
        let predicateCompound = NSCompoundPredicate.init(type: .and,
                                                         subpredicates: [timePredicate, outletPredicate])
        self._fetchRequest = FetchRequest<SolvedCrossword>(sortDescriptors: [],
                                                           predicate: predicateCompound)
        self.graphStat = graphStatEnum
    }
    let colWidth = (UIScreen.main.bounds.size.width - 100) / 7

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text(String(self.fetchRequest.count))
                    .bold()
                Text("Total Puzzles Solved")
            }
            HStack {
                Text(String(self.fetchRequest.map({$0.numClues}).reduce(0, +)))
                    .bold()
                Text("Total Clues Solved")
            }
            
            let groupByDay = Dictionary(grouping: self.fetchRequest, by: {$0.date!.getDayOfWeek()})
            let maxValue: Double? = groupByDay.values.map({self.getValue(solvedCrosswordGroup: $0)}).max()
            let maxValueSafe: Double = (maxValue == nil || Int(maxValue!) == 0) ? 10.0 : maxValue!

            HStack(alignment: .bottom) {
                ForEach((1..<8)) { dayId in
                    let value = self.getValue(solvedCrosswordGroup: groupByDay[dayId])
                    VStack {
                        let proportionOfMax: Double = Double(value) / maxValueSafe
                        ZStack {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(width: self.colWidth,
                                           height: proportionOfMax * Constants.statisticsPageMaxHeight)
                                    .foregroundColor(.blue)
                                    .frame(alignment: .bottom)
                            }
                            
                            if (value > 0) {
                                VStack {
                                    Spacer()
                                    Text(String(format: "%.0f", value))
                                        .foregroundColor(Color(UIColor.systemBackground))
                                        .frame(alignment: .bottom)
                                        .padding(5)
                                }
                            }
                        }
                        .frame(alignment: .bottom)

                        Text(Date.getDay(dayId))
                    }
                    .frame(width: self.colWidth)
                }
            }.frame(maxHeight: Constants.statisticsPageMaxHeight+30)
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
}
