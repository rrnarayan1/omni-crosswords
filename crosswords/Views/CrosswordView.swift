//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import GameKit

struct CrosswordView: View {
    var crossword: Crossword
    var componentHeights: CGFloat {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        
        // 40 is height of keyboard toolbar
        // 45 is height of navigation bar
        // 10 is buffer
        return 40 + 45 + statusBarHeight + self.boxWidth*CGFloat(self.crossword.height) - 10
    }
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var timerWrapper : TimerWrapper
    
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var focusedTag: Int = -1
    @State var highlighted: Array<Int> = Array()
    @State var goingAcross: Bool = true
    @State var showShareSheet: Bool = false
    @State var isErrorTrackingEnabled: Bool = UserDefaults.standard.object(forKey: "defaultErrorTracking") as? Bool ?? false
    @State var forceUpdate = false
    @State var scrolledRow = 0
    @State var becomeFirstResponder: Bool = false
    
    var boxWidth: CGFloat {
        let maxSize: CGFloat = userSettings.largePrintMode ? 60.0 : 40.0
        let defaultSize: CGFloat = (UIScreen.screenWidth-5)/CGFloat(crossword.length)
        return min(defaultSize, maxSize)
    }
    
    var displayTitle: String {
        let date = self.crossword.date ?? Date.init(timeIntervalSinceNow: TimeInterval(0))
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateStyle = .short
        var prefix: String = self.forceUpdate ? "" : " "
        if (self.crossword.solved) {
            prefix = "Solved: "
        }
        return prefix + self.crossword.outletName! + " - " + formatter.string(from: date)
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let showTimer = UserDefaults.standard.object(forKey: "showTimer") as? Bool ?? true
    
    @ViewBuilder
    var body: some View {
        VStack{
            ScrollView {
                ScrollViewReader { scrollreader in
                    {() -> CrosswordGridView in
                        let currentClue = getCurrentClue()
                        return CrosswordGridView(crossword: self.crossword, boxWidth: self.boxWidth, currentClue: currentClue, doErrorTracking: self.isErrorTrackingEnabled, focusedTag: self.$focusedTag, highlighted: self.$highlighted, goingAcross: self.$goingAcross, forceUpdate: self.$forceUpdate, becomeFirstResponder: self.$becomeFirstResponder)
                    }()
                    .onChange(of: focusedTag, perform: {newFocusedTag in
                        let oneThirdsRowNumber = Int(self.crossword.height/3)
                        let middleRowNumber = Int(self.crossword.height/2)
                        let twoThirdsRowNumber = Int(self.crossword.height/3)*2
                        if (self.keyboardHeightHelper.keyboardHeight == 0) {
                            self.scrolledRow = middleRowNumber - 3
                        } else if (newFocusedTag >= 0 && self.shouldScroll(self.keyboardHeightHelper.keyboardHeight)) {
                            let newRowNumber = self.getRowNumberFromTag(newFocusedTag)
                            if (newRowNumber > twoThirdsRowNumber && self.scrolledRow != middleRowNumber + 3) {
                                scrollreader.scrollTo("row"+String(middleRowNumber + 3), anchor: .center)
                                self.scrolledRow = middleRowNumber + 3
                            } else if (newRowNumber < oneThirdsRowNumber && self.scrolledRow != middleRowNumber - 3){
                                scrollreader.scrollTo("row"+String(middleRowNumber - 3), anchor: .center)
                                self.scrolledRow = middleRowNumber - 3
                            }
                        }
                    })
                    .padding(.top, 10)
                    if (showTimer) {
                        Text(self.crossword.solved ?  String(toTime(Int(self.crossword.solvedTime))) :  String(toTime(self.timerWrapper.count)))
                            .frame(width: UIScreen.screenWidth-10, height: 10, alignment: .trailing)
                    }
                    Spacer()
                    if (self.focusedTag == -1) {
                        VStack (alignment: .center){
                            Text(self.crossword.title!).multilineTextAlignment(.center)
                            Text(self.crossword.author!).multilineTextAlignment(.center)
                            if (self.crossword.notes! != "") {
                                Text(self.crossword.notes!).multilineTextAlignment(.center)
                            }
                            Text(self.crossword.copyright!).multilineTextAlignment(.center)
                        }
                    }
                }
            }
        }
        .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded({ value in
                if value.translation.width < 0 && self.focusedTag != -1 {
                    // left
                    goToPreviousClue(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.$goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
                }

                if value.translation.width > 0 && self.focusedTag != -1 {
                    // right
                    goToNextClue(tag: self.focusedTag, crossword: self.crossword, goingAcross: self.$goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
                }
            }))
        .onAppear {
            if (!self.crossword.solved) {
                self.timerWrapper.start(Int(self.crossword.solvedTime))
            }
        }
        .onReceive(timer) { time in
            if (self.userSettings.gameCenterPlayer != nil && self.timerWrapper.count % 10 == 0) {
                let entryString: String = (self.crossword.entry?.joined(separator: ","))!
                
                self.userSettings.gameCenterPlayer!.saveGameData(
                    entryString.data(using: .utf8)!,
                    withName: self.crossword.id!, completionHandler: {_, error in
                        if let error = error {
                            print("Error saving to game center: \(error)")
                        }
                    })
            }
        }
        .navigationBarTitle(Text(verbatim: displayTitle), displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarColor(self.crossword.solved ? .systemGreen : .systemGray6)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CrosswordTrailingToolbarView(title: crossword.title!, author: crossword.author!, notes: crossword.notes!, copyright: crossword.copyright!, isSolved: crossword.solved, outletName: crossword.outletName!, isErrorTrackingEnabled: self.$isErrorTrackingEnabled, showSolution: showSolution, showSettings: showSettings)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                CrosswordLeadingToolbarView(goBack: goBack)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func resetArray(count: Int) -> Array<Bool> {
        return Array(repeating: false, count: count)
    }
    
    func getCurrentClue() -> String {
        if (self.focusedTag < 0 || self.crossword.tagToCluesMap?[self.focusedTag] == nil) {
            return ""
        }
        let possibleClues : Dictionary<String, String> = (self.crossword.tagToCluesMap?[self.focusedTag])!
        let directionalLetter : String = self.goingAcross ? "A" : "D"
        return self.crossword.clues![possibleClues[directionalLetter]!]!
    }
    
    func getRowNumberFromTag(_ tag: Int) -> Int {
        return tag / Int(self.crossword.length)
    }
    
    func shouldScroll(_ keyboardHeight: CGFloat) -> Bool {
//        print(self.componentHeights)
//        print(keyboardHeight)
//        print(UIScreen.screenHeight)
        return (self.componentHeights + keyboardHeight) > UIScreen.screenHeight
    }
    
    func showSolution() -> Void {
        self.crossword.entry = self.crossword.solution
        self.crossword.solved = true
        self.timerWrapper.stop()
        self.forceUpdate = !self.forceUpdate
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func showSettings() -> Void {
        self.becomeFirstResponder = false
        self.focusedTag = -1
        self.highlighted = Array()
    }
    
    func goBack() -> Void {
        self.becomeFirstResponder = false
        self.presentationMode.wrappedValue.dismiss()
    }
}

func toTime(_ currentTimeInSeconds: Int) -> String {
    let timeInSeconds = currentTimeInSeconds
    let numMin = timeInSeconds / 60
    let numSec = timeInSeconds % 60
    
    let secString: String = numSec < 10 ? "0"+String(numSec) : String(numSec)
    return String(numMin) + ":" + secString
}

struct CrosswordGridView: View {
    var crossword: Crossword
    var boxWidth: CGFloat
    var currentClue: String
    var doErrorTracking: Bool
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var forceUpdate: Bool
    @Binding var becomeFirstResponder: Bool
    
    var body: some View {
        let rows: [Int] = Array(0...Int(self.crossword.height)-1)
        let cols: [Int] = Array(0...Int(self.crossword.length)-1)
        return VStack(spacing: 0) {
            ForEach(rows, id: \.self) { rowNum in
                HStack (spacing: 0) {
                    ForEach(cols, id: \.self) { colNum in
                        makeCellView(colNum: colNum, rowNum: rowNum)
                    }
                }
                .id("row"+String(rowNum))
            }
            CrosswordTextFieldView(crossword: self.crossword, currentClue: self.currentClue, focusedTag: self.$focusedTag, highlighted: self.$highlighted, goingAcross: self.$goingAcross, forceUpdate: self.$forceUpdate, becomeFirstResponder: self.$becomeFirstResponder)
                .frame(width:1, height: 1)
        }
    }
    
    func makeCellView(colNum: Int, rowNum: Int) -> some View {
        let tag: Int = rowNum*Int(self.crossword.length)+colNum
        let value: String = self.crossword.entry![tag]
        let correctValue: String = self.crossword.solution![tag]
        let symbol: Int = self.crossword.symbols![tag]
        return CrosswordCellView(
            value: value,
            correctValue: correctValue,
            symbol: symbol,
            tag: tag,
            onTap: self.onTapCell,
            onLongPress: self.solveCell,
            boxWidth: self.boxWidth,
            isErrorTrackingEnabled: self.doErrorTracking,
            isFocused: self.focusedTag == tag,
            isHighlighted: self.highlighted.contains(tag)
        ).equatable().frame(width: self.boxWidth, height: self.boxWidth)
    }
    
    func onTapCell(tag: Int) -> Void {
        if (!self.becomeFirstResponder) {
            self.becomeFirstResponder = true
        }
        if (self.crossword.entry![tag] == ".") {
            return
        }
        if (tag == self.focusedTag) {
            toggleDirection(tag: tag, crossword: self.crossword, goingAcross: self.$goingAcross, isHighlighted: self.$highlighted)
        } else {
            changeFocus(tag: tag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
        }
    }
    
    func solveCell(tag: Int) -> Void {
        self.crossword.entry![tag] = self.crossword.solution![tag]
        if (self.crossword.entry == self.crossword.solution) {
            self.crossword.solved = true
        } else if (self.focusedTag == tag) {
            moveFocusToNextFieldAndCheck(currentTag: tag, crossword: self.crossword, goingAcross: self.$goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
        } else {
            changeFocus(tag: tag, crossword: self.crossword, goingAcross: self.goingAcross, focusedTag: self.$focusedTag, isHighlighted: self.$highlighted)
        }
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
