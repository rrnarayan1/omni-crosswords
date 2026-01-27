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
    @ObservedObject var userSettings: UserSettings
    @State var timeFilter: Date = Date().subtractWeeks(2)
    @State var outletNameFilter: String?
    @State var graphStatistic: SolvedCrosswordGraphStat = SolvedCrosswordGraphStat.NUM_PUZZLES
    
    var body: some View {
        VStack(alignment: .center) {
            let date = Date()
            HStack {
                VStack(alignment: .leading) {
                    Text("Time")
                        .bold()
                        .padding(.leading, 10)
                    Picker("Time", selection: self.$timeFilter) {
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
                    Picker("Outlet Name", selection: self.$outletNameFilter) {
                        Text("All").tag(nil as String?)
                        ForEach(self.userSettings.subscriptions, id: \.self) {subscription in
                            Text(subscription).tag(subscription)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            SolvedCrosswordStatistics(afterDate: self.timeFilter, outletName: self.outletNameFilter,
                                      graphStatEnum: self.graphStatistic)

            Picker("Statistic", selection: self.$graphStatistic) {
                Text("Num Puzzles").tag(SolvedCrosswordGraphStat.NUM_PUZZLES)
                Text("Num Clues").tag(SolvedCrosswordGraphStat.NUM_CLUES)
                if (self.userSettings.showTimer) {
                    Text("Avg Time").tag(SolvedCrosswordGraphStat.AVG_TIME)
                }
            }
            .pickerStyle(.segmented)

            Spacer()
        }
        .frame(width: min(UIScreen.screenWidth * 0.9, 400))
        .navigationBarTitle("Statistics")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Link(destination: URL(string: "https://omnicrosswords.app")!) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
        }
    }
}
