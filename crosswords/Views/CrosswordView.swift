//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import FontAwesome_swift

struct CrosswordView: View {
    var crossword: Crossword
    var componentHeights: CGFloat {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        
        // 40 is height of keyboard toolbar
        // 45 is height of navigation bar
        return 40 + 45 + statusBarHeight + self.boxWidth*CGFloat(self.crossword.height)
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var timerWrapper : TimerWrapper
    
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var focusedTag: Int = -1
    @State var highlighted: Array<Int> = Array()
    @State var goingAcross: Bool = true
    @State var showCrosswordSettings = false
    @State var showShareSheet = false
    @State var errorTracking : Bool = false
    @State var forceUpdate = false
    @State var scrolledRow = 0
    @State var isKeyboardOpen = false
    
    var boxWidth: CGFloat {
        let maxSize: CGFloat = 40.0
        let defaultSize: CGFloat = (UIScreen.screenWidth-5)/CGFloat(crossword.length)
        return min(defaultSize, maxSize)
    }
    
    var displayTitle: String {
        let date = self.crossword.date!
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
                        return CrosswordGridView(crossword: self.crossword, boxWidth: self.boxWidth, currentClue: currentClue, focusedTag: self.$focusedTag, highlighted: self.$highlighted, goingAcross: self.$goingAcross, doErrorTracking: self.$errorTracking, forceUpdate: self.$forceUpdate, isKeyboardOpen: self.$isKeyboardOpen)
                    }()
                    .onChange(of: focusedTag, perform: {newFocusedTag in
                        if (newFocusedTag < 0) {
                            self.isKeyboardOpen = false
                        }
                        if (newFocusedTag >= 0 && self.shouldScroll(self.keyboardHeightHelper.keyboardHeight)) {
                            let newRowNumber = self.getRowNumberFromTag(newFocusedTag)
                            let oneThirdsRowNumber = Int(self.crossword.height/3)
                            let middleRowNumber = Int(self.crossword.height/2)
                            let twoThirdsRowNumber = Int(self.crossword.height/3)*2
                            if (newRowNumber > twoThirdsRowNumber && self.scrolledRow != middleRowNumber + 2) {
                                scrollreader.scrollTo("row"+String(middleRowNumber + 2), anchor: .center)
                                self.scrolledRow = middleRowNumber + 2
                            } else if (newRowNumber < oneThirdsRowNumber && self.scrolledRow != middleRowNumber - 2){
                                scrollreader.scrollTo("row"+String(middleRowNumber - 2), anchor: .center)
                                self.scrolledRow = middleRowNumber - 2
                            }
                        }
                    })
                    .padding(.top, 30)
                    if (showTimer) {
                        Text(self.crossword.solved ?  String(toTime(Int(self.crossword.solvedTime))) :  String(toTime(self.timerWrapper.count)))
                            .frame(width: UIScreen.screenWidth-10, height: 10, alignment: .trailing)
                    }
                    Spacer()
                    VStack (alignment: .center){
                        if (self.focusedTag == -1) {
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
        .onAppear {
            self.errorTracking = UserDefaults.standard.object(forKey: "defaultErrorTracking") as? Bool ?? false
            if (!self.crossword.solved) {
                self.timerWrapper.start(Int(self.crossword.solvedTime))
            }
        }
            .navigationBarTitle(Text(verbatim: displayTitle), displayMode: .inline)
            .navigationBarColor(self.crossword.solved ? .systemGreen : .systemGray6)
            .navigationBarItems(trailing:
                HStack {
                    Button(action: {
                        self.showCrosswordSettings.toggle()
                    }) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .slidersH, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize.init(width: 30, height: 30)))
                    }
                    .sheet(isPresented: $showCrosswordSettings) {
                        CrosswordSettingsView(errorTracking: self.$errorTracking)
                    }
                    Button(action: shareSheet) {
                        Image(uiImage: UIImage.fontAwesomeIcon(name: .shareAlt, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize.init(width: 30, height: 30)))
                    }
                }
            )
    }
    
    func shareSheet() {
        var shareMessage: String
        if (self.crossword.solved) {
            shareMessage = "I solved the " + self.crossword.outletName! + " crossword in "
            shareMessage += String(toTime(Int(self.crossword.solvedTime)))
            shareMessage += ". Download OmniCrosswords and try to beat my time!"
        } else {
            shareMessage = "I'm in the middle of solving the " + self.crossword.outletName! + " crossword"
            shareMessage += ". Download OmniCrosswords and help me out!"
        }
        let items: [Any] = [shareMessage, URL(string: "https://apps.apple.com/us/app/omni-crosswords/id1530129670")!]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
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
        return (self.componentHeights + keyboardHeight) > UIScreen.screenHeight;
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
    
    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var doErrorTracking: Bool
    @Binding var forceUpdate: Bool
    @Binding var isKeyboardOpen: Bool
    
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach((0...self.crossword.height-1), id: \.self) { rowNum in
                HStack (spacing: 0) {
                    ForEach((0...self.crossword.length-1), id: \.self) { colNum in
                        CrosswordCellView(
                            crossword: self.crossword,
                            boxWidth: self.boxWidth,
                            rowNum: Int(rowNum),
                            colNum: Int(colNum),
                            currentClue: self.currentClue, focusedTag: self.$focusedTag,
                            isHighlighted: self.$highlighted,
                            goingAcross: self.$goingAcross,
                            doErrorTracking: self.$doErrorTracking,
                            forceUpdate: self.$forceUpdate,
                            isKeyboardOpen: self.$isKeyboardOpen
                        ).frame(width: self.boxWidth, height: self.boxWidth)
                        .id("row"+String(rowNum))
                    }
                }
            }
        }
    }
}
