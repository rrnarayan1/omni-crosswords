//
//  CrosswordView.swift
//  crosswords
//
//  Created by Rohan Narayan on 7/20/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI

struct CrosswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var managedObjectContext

    @ObservedObject var crossword: Crossword
    @ObservedObject var userSettings: UserSettings
    @StateObject var keyboardHeightHelper = KeyboardHeightHelper()

    @State var focusedTag: Int = -1
    @State var highlighted: Array<Int> = Array()
    @State var goingAcross: Bool = true
    @State var isErrorTrackingEnabled: Bool = false
    @State var forceUpdate = false
    @State var becomeFirstResponder: Bool = false
    @State var boxWidth: CGFloat = 0.0

    @State var isZoomed: Bool = false
    @State var isRebusMode: Bool = false
    @State var isPaused: Bool = false

    // height of components. does not include keyboard height
    var componentHeights: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.filter {$0.isKeyWindow}.first
        let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let crosswordHeight = self.getInitialBoxWidth()*CGFloat(self.crossword.height)
        let barHeights: CGFloat = CGFloat(Constants.keybordToolbarHeight) + statusBarHeight

        return barHeights + crosswordHeight - 10
    }
    
    var displayTitle: String {
        let date = self.crossword.date ?? Date.init(timeIntervalSinceNow: TimeInterval(0))
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateStyle = .short
        var prefix: String = ""
        if (self.crossword.solved) {
            prefix = "Solved: "
        }
        return prefix + self.crossword.outletName! + " - " + formatter.string(from: date)
    }

    init(crossword: Crossword, userSettings: UserSettings) {
        self.crossword = crossword
        self.userSettings = userSettings
        self._isErrorTrackingEnabled = State(initialValue:
                                                CrosswordUtils.isSolutionAvailable(crossword: crossword)
                                             ? self.userSettings.defaultErrorTracking
                                             : false)
        self._boxWidth = State(initialValue: self.getInitialBoxWidth())
    }

    @ViewBuilder
    var body: some View {
        VStack {
            if (self.horizontalSizeClass == .compact) {
                HStack {
                    CrosswordLeadingToolbarView(goBack: self.goBack)
                        .padding(.leading)
                    Spacer()
                    Text(verbatim: self.displayTitle)
                        .bold()
                    Spacer()
                    CrosswordTrailingToolbarView(title: self.crossword.title!,
                                                 author: self.crossword.author!,
                                                 notes: self.crossword.notes!,
                                                 copyright: self.crossword.copyright!,
                                                 isSolved: self.crossword.solved,
                                                 outletName: self.crossword.outletName!,
                                                 isSolutionAvailable:
                                                    CrosswordUtils.isSolutionAvailable(crossword:
                                                                                        self.crossword),
                                                 isErrorTrackingEnabled: self.$isErrorTrackingEnabled,
                                                 showSolution: self.showSolution,
                                                 showSettings: self.showSettings)
                    .padding(.trailing)
                }
                .background(self.crossword.solved ? .green : Color(UIColor.systemBackground))
            }

            ScrollView([.horizontal, .vertical]) {
                ScrollViewReader { scrollreader in
                    CrosswordGridView(crossword: self.crossword, boxWidth: self.boxWidth,
                                      currentClue: CrosswordUtils.getClue(focusedTag: self.focusedTag,
                                                                          crossword: self.crossword,
                                                                          goingAcross: self.goingAcross),
                                      doErrorTracking: self.isErrorTrackingEnabled,
                                      userSettings: self.userSettings,
                                      focusedTag: self.$focusedTag,
                                      highlighted: self.$highlighted,
                                      goingAcross: self.$goingAcross,
                                      forceUpdate: self.$forceUpdate,
                                      becomeFirstResponder: self.$becomeFirstResponder,
                                      isRebusMode: self.$isRebusMode)
                    .onChange(of: self.focusedTag) {_, newFocusedTag in
                        if (self.isZoomed) {
                            scrollreader.scrollTo("cell"+String(newFocusedTag))
                            return
                        } else if (newFocusedTag >= 0 && self.shouldScroll()) {
                            let newRowNumber = CrosswordUtils.getRowNumberFromTag(tag: newFocusedTag,
                                                                                  crossword:
                                                                                    self.crossword)
                            scrollreader.scrollTo("row"+String(newRowNumber), anchor: .center)
                        }
                    }
                }
            }
            //.background(.random)
            .frame(width: UIScreen.screenWidth)

            HStack {
                if (self.focusedTag != -1) {
                    Button(action: {self.zoom()}) {
                        Image(systemName: self.isZoomed ? "minus.magnifyingglass"
                              : "plus.magnifyingglass")
                    }
                    Button(action: {self.isRebusMode.toggle()}) {
                        Image(systemName: self.isRebusMode ? "r.square.fill" : "r.square")
                    }
                    if (self.userSettings.showTimer) {
                        Button(action: {self.isPaused.toggle()}) {
                            Image(systemName: "pause.fill")
                        }
                    }
                }
                Spacer()
                if (self.userSettings.showTimer) {
                    TimerView(isSolved: self.crossword.solved, solvedTime: Int(self.crossword.solvedTime),
                              isPaused: self.isPaused)
                }
            }.frame(width: self.getInitialBoxWidth()*CGFloat(self.crossword.length), height: 10)

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
        .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded({ value in
                if (value.translation.width < 0 && self.focusedTag != -1) {
                    // left
                    ChangeFocusUtils.goToPreviousClue(focusedTag: self.$focusedTag,
                                                      crossword: self.crossword,
                                                      userSettings: self.userSettings,
                                                      goingAcross: self.$goingAcross,
                                                      isHighlighted: self.$highlighted)
                }

                if (value.translation.width > 0 && self.focusedTag != -1) {
                    // right
                    ChangeFocusUtils.goToNextClue(focusedTag: self.$focusedTag,
                                                  crossword: self.crossword,
                                                  userSettings: self.userSettings,
                                                  goingAcross: self.$goingAcross,
                                                  isHighlighted: self.$highlighted)
                }
            }))
        .toolbar(self.horizontalSizeClass == .compact ? .hidden : .automatic)
        .navigationBarTitle(Text(verbatim: displayTitle), displayMode: .inline)
        .navigationBarColor(self.crossword.solved ? .systemGreen : .systemBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CrosswordTrailingToolbarView(title: self.crossword.title!, author: self.crossword.author!,
                                             notes: self.crossword.notes!,
                                             copyright: self.crossword.copyright!,
                                             isSolved: self.crossword.solved,
                                             outletName: self.crossword.outletName!,
                                             isSolutionAvailable:
                                                CrosswordUtils.isSolutionAvailable(crossword:
                                                                                    self.crossword),
                                             isErrorTrackingEnabled: self.$isErrorTrackingEnabled,
                                             showSolution: self.showSolution,
                                             showSettings: self.showSettings)
            }.hideSharedBackgroundIfAvailable()
            ToolbarItem(placement: .navigationBarLeading) {
                CrosswordLeadingToolbarView(goBack: self.goBack)
            }.hideSharedBackgroundIfAvailable()
        }
        // custom back button added in leading toolbar view
        .navigationBarBackButtonHidden(true)
    }
    
    func getInitialBoxWidth() -> CGFloat {
        let maxInitialSize: CGFloat = CGFloat(Constants.maxInitialCellSize)
        let defaultSize: CGFloat = (UIScreen.screenWidth-5)/CGFloat(self.crossword.length)
        return min(defaultSize, maxInitialSize)
    }
    
    func zoom() -> Void {
        self.isZoomed.toggle()
        let initialWidth = self.getInitialBoxWidth()
        self.boxWidth = self.isZoomed
            ? initialWidth * CGFloat(self.userSettings.zoomMagnificationLevel)
            : initialWidth
    }
    
    func shouldScroll() -> Bool {
        let navigationBarHeight = self.horizontalSizeClass == .compact ?
            Constants.crosswordToolbarButtonSize : Constants.navigationBarHeight
        let componentHeights = self.componentHeights + navigationBarHeight
            + self.keyboardHeightHelper.keyboardHeight
//        print(componentHeights)
//        print(UIScreen.main.bounds.size.height)
//        print("")
        return componentHeights > UIScreen.main.bounds.size.height
    }
    
    func showSolution() -> Void {
        self.crossword.entry = self.crossword.solution
        self.forceUpdate.toggle()
        CrosswordUtils.solutionHandler(crossword: self.crossword, shouldAddStatistics: false,
                                       userSettings: self.userSettings, focusedTag: self.$focusedTag,
                                       becomeFirstResponder: self.$becomeFirstResponder,
                                       isHighlighted: self.$highlighted, timerWrapper: nil,
                                       managedObjectContext: self.managedObjectContext)
    }
    
    func showSettings() -> Void {
        self.becomeFirstResponder = false
        self.focusedTag = -1
        self.highlighted = Array()
    }
    
    func goBack() -> Void {
        self.becomeFirstResponder = false
        DispatchQueue.main.async {
            self.dismiss()
        }
    }
}

struct CrosswordGridView: View {
    var crossword: Crossword
    var boxWidth: CGFloat
    var currentClue: String
    var doErrorTracking: Bool

    @ObservedObject var userSettings: UserSettings

    @Binding var focusedTag: Int
    @Binding var highlighted: Array<Int>
    @Binding var goingAcross: Bool
    @Binding var forceUpdate: Bool
    @Binding var becomeFirstResponder: Bool
    @Binding var isRebusMode: Bool
    
    var body: some View {
        let rows: [Int] = Array(0...Int(self.crossword.height)-1)
        let cols: [Int] = Array(0...Int(self.crossword.length)-1)
        return VStack(spacing: 0) {
            ForEach(rows, id: \.self) { rowNum in
                HStack(spacing: 0) {
                    ForEach(cols, id: \.self) { colNum in
                        self.makeCellView(rowNum: rowNum, colNum: colNum)
                    }
                }
                .id("row"+String(rowNum))
            }
            CrosswordTextFieldView(crossword: self.crossword, currentClue: self.currentClue,
                                   userSettings: self.userSettings, focusedTag: self.$focusedTag,
                                   highlighted: self.$highlighted, goingAcross: self.$goingAcross,
                                   forceUpdate: self.$forceUpdate,
                                   becomeFirstResponder: self.$becomeFirstResponder,
                                   isRebusMode: self.$isRebusMode)
                .frame(width: 1, height: 1)
        }
    }
    
    func makeCellView(rowNum: Int, colNum: Int) -> some View {
        let tag: Int = CrosswordUtils.getTagFromRowAndColNumbers(rowNum: rowNum, colNum: colNum,
                                                                 crossword: self.crossword)
        return CrosswordCellView(
            value: self.crossword.entry![tag],
            correctValue: self.crossword.solution![tag],
            symbol: self.crossword.symbols![tag],
            tag: tag,
            onTap: self.onTapCell,
            boxWidth: self.boxWidth,
            isErrorTrackingEnabled: self.doErrorTracking,
            isFocused: self.focusedTag == tag,
            isHighlighted: self.highlighted.contains(tag),
        )
        .equatable()
        .frame(width: self.boxWidth, height: self.boxWidth).id("cell"+String(tag))
    }
    
    func onTapCell(tag: Int) -> Void {
        if (self.crossword.entry![tag] == ".") {
            return
        }

        if (!self.becomeFirstResponder) {
            self.becomeFirstResponder = true
        }

        if (tag == self.focusedTag) {
            ChangeFocusUtils.toggleDirection(focusedTag: tag, crossword: self.crossword,
                                             goingAcross: self.$goingAcross,
                                             isHighlighted: self.$highlighted)
        } else {
            self.isRebusMode = false
            ChangeFocusUtils.changeFocus(tag: tag, crossword: self.crossword,
                                         goingAcross: self.$goingAcross, focusedTag: self.$focusedTag,
                                         isHighlighted: self.$highlighted)
        }
    }
}
