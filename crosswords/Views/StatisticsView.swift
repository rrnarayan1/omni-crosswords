//
//  StatisticsView.swift
//  crosswords
//
//  Created by Rohan Narayan on 1/15/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct StatisticsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var userSettings = UserSettings()
    @State var timeFilter: Date = Date().subtractWeeks(2)
    @State var outletNameFilter: String = ""
    @State var graphStatistic: SolvedCrosswordGraphStat = SolvedCrosswordGraphStat.NUM_PUZZLES
    
    var body: some View {
        VStack(alignment: .center) {
            let date = Date()
            HStack {
                VStack(alignment: .leading) {
                    Text("Time")
                        .bold()
                        .padding(.leading, 10)
                    Picker("Time", selection: $timeFilter) {
                        Text("2 weeks").tag(date.subtractWeeks(2))
                        Text("1 month").tag(date.subtractMonths(1))
                        Text("3 months").tag(date.subtractMonths(3))
                        Text("6 months").tag(date.subtractMonths(6))
                        Text("Year to Date").tag(date.startOfYear())
                        Text("All Time").tag(Date(timeIntervalSince1970: 0))
                    }
                    .pickerStyle(.menu)
                }
                
                Spacer()
                
                VStack (alignment: .trailing){
                    Text("Outlet")
                        .bold()
                    Picker("Outlet Name", selection: $outletNameFilter) {
                        Text("All").tag("")
                        ForEach(userSettings.subscriptions, id: \.self) {subscription in
                            Text(subscription).tag(subscription)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            SolvedCrosswordStatistics(afterDate: timeFilter, outletName: outletNameFilter, graphStatEnum: graphStatistic)
            
            Picker("Statistic", selection: $graphStatistic) {
                Text("Num Puzzles").tag(SolvedCrosswordGraphStat.NUM_PUZZLES)
                Text("Num Clues").tag(SolvedCrosswordGraphStat.NUM_CLUES)
                if (userSettings.showTimer) {
                    Text("Avg Time").tag(SolvedCrosswordGraphStat.AVG_TIME)
                }
            }
            .pickerStyle(.segmented)

            Text("Note: Only shows data for puzzles completed after app version 1.6 update")

            Spacer()
            
            Text("This feature is in Beta - please reach out with suggestions.")
            Link(destination: URL(string: "https://rrnarayan1.github.io/omni-crosswords/#four")!) {
                Text("Contact Me!")
            }
            
            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Statistics")
        .navigationBarColor(.systemGray6)
        .padding(30)
    }
}

extension Date {
    func startOfYear() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func subtractMonths(_ numMonths: Int) -> Date {
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .month, value: -1*numMonths, to: self)!)
    }
    
    func subtractWeeks(_ numWeeks: Int) -> Date {
        return Calendar.current.startOfDay(for: (Calendar.current.date(byAdding: .weekOfYear, value: -1*numWeeks, to: self)!))
    }
    
    func getDayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-US")
        dateFormatter.dateFormat = "e"
        return dateFormatter.string(from: self)
    }
}
