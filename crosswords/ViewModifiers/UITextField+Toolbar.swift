//
//  UITextField+Toolbar.swift
//  crosswords
//
//  Created by Rohan Narayan on 12/11/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import SwiftUI
import UIKit

extension UITextField {

    var nextImage: UIImage {
        return UIImage(systemName: "chevron.right")!
    }

    var previousImage: UIImage {
        return UIImage(systemName: "chevron.left")!
    }
    
    var solveImage: UIImage {
        return UIImage(systemName: "lifepreserver")!
    }
    
    var toggleImage: UIImage {
        return UIImage(systemName: "arrow.2.squarepath")!
    }
    
    func changeToolbar(userSettings: UserSettings, clueTitle: String) {
        guard let uiTextFieldToolbar = self.inputAccessoryView as? UIToolbar else {
            print("inputAccessoryView is nil or not a UIToolbar")
            return
        }
        var clueTitleIndex: Int
        if #available(iOS 26.0, *) {
            clueTitleIndex = 2
        } else {
            clueTitleIndex = 4
        }
        let clueTitleLabel = uiTextFieldToolbar.items![clueTitleIndex].customView as! UITextView
        let attributedText = clueTitleLabel.attributedText
        var newAttributedString: NSMutableAttributedString

        do {
            newAttributedString = try NSMutableAttributedString(AttributedString(markdown: clueTitle))
        } catch {
            print("Failure in creating attributed text: \(error)")
            return
        }

        if (attributedText!.string.trimmingCharacters(in: .whitespaces)
            != newAttributedString.string.trimmingCharacters(in: .whitespaces)) {
            uiTextFieldToolbar.items?.remove(at: clueTitleIndex)
            clueTitleLabel.attributedText = self.formatClueTitle(userSettings: userSettings,
                                                                 attributedString: newAttributedString)
            uiTextFieldToolbar.items?.insert(
                UIBarButtonItem.init(customView: clueTitleLabel).hideSharedBackgroundIfAvailable(),
                at: clueTitleIndex
            )
        }
    }

    func formatClueTitle(userSettings: UserSettings, attributedString: NSMutableAttributedString)
    -> NSAttributedString {
        var clueFontSize = userSettings.clueSize
        if (clueFontSize < 13) {
            clueFontSize = 13
        }
        let fullRange: NSRange = NSRange(location: 0, length: attributedString.length)
        let centerAlignment = NSMutableParagraphStyle()
        centerAlignment.alignment = NSTextAlignment.center
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: CGFloat(clueFontSize)),
                                      range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: centerAlignment, range: fullRange)

        return attributedString
    }

    func addToolbar(coordinator: CrosswordTextFieldView.Coordinator) {
        self.inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0,
                                                          width: Double(UIScreen.main.bounds.size.width),
                                                          height: Double(Constants.keybordToolbarHeight)))
        let clueTitleLabel = UITextView()

        clueTitleLabel.attributedText = NSAttributedString(string: "")
        clueTitleLabel.backgroundColor = UIColor.clear
        clueTitleLabel.isEditable = false
        clueTitleLabel.allowsEditingTextAttributes = false
        clueTitleLabel.isSelectable = false
        
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.tapClue))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        clueTitleLabel.addGestureRecognizer(tapGesture)

        let actionButtonsInToolbar = coordinator.parent.userSettings.actionButtonsInToolbar
        let clueCyclePlacement = coordinator.parent.userSettings.clueCyclePlacement

        let numButtonsInToolbar: Int = actionButtonsInToolbar ? 4 : 2
        // only 1 group iff action buttons are not in toolbar and clue cycle is not split
        let numButtonGroups: Int =
            !actionButtonsInToolbar && clueCyclePlacement != 1 ? 1 : 2
        let toolbarButtonSize: CGFloat =
            Constants.crosswordToolbarIconSize * CGFloat(numButtonsInToolbar)
        let mandatedToolbarGroupPadding: CGFloat =
            Constants.mandatedToolbarGroupPadding * CGFloat(numButtonGroups * 2)
        let otherElementsInToolbar: CGFloat =
            toolbarButtonSize
            + mandatedToolbarGroupPadding
            + Constants.crosswordToolbarPadding * 2

        let widthConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .width,
                                                 relatedBy: .equal, toItem: nil,
                                                 attribute: .notAnAttribute, multiplier: 1.0,
                                                 constant: UIScreen.main.bounds.size.width-otherElementsInToolbar)
        let heightConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .height,
                                                  relatedBy: .equal, toItem: nil,
                                                  attribute: .notAnAttribute, multiplier: 1.0,
                                                  constant: Double(Constants.keybordToolbarHeight))

        clueTitleLabel.addConstraints([widthConstraint, heightConstraint])
        
        var configuredToolbarItems: [UIBarButtonItem] {
            
            let clueTitle = UIBarButtonItem(customView: clueTitleLabel)
                .hideSharedBackgroundIfAvailable()

            let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                           target: nil,
                                           action: nil)
            let fixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                                           target: nil,
                                           action: nil)
            fixed.width = Constants.crosswordToolbarPadding

            let previousButton = UIButton.systemButton(
                with: self.previousImage,
                target: coordinator,
                action: #selector(coordinator.goToPreviousClue)
            )
            let previousButtonWithSize = UIButtonWithSize(
                button: previousButton,
                width: Constants.crosswordToolbarIconSize,
                height: Constants.crosswordToolbarIconSize * 1.32
            )

            let nextButton = UIButton.systemButton(
                with: self.nextImage,
                target: coordinator,
                action: #selector(coordinator.goToNextClue)
            )
            let nextButtonWithSize = UIButtonWithSize(
                button: nextButton,
                width: Constants.crosswordToolbarIconSize,
                height: Constants.crosswordToolbarIconSize * 1.32
            )

            var toggleButton = UIButton.systemButton(
                with: self.toggleImage,
                target: coordinator,
                action: #selector(coordinator.pressToggleButton)
            )

            var solveButton = UIButton.systemButton(
                with: self.solveImage,
                target: coordinator,
                action: #selector(coordinator.solveCell)
            )

            let emptyButton = UIButton()

            if (!CrosswordUtils.isSolutionAvailable(
                crossword: coordinator.parent.crossword
            )) {
                solveButton = emptyButton
            }

            if (!actionButtonsInToolbar) {
                solveButton = emptyButton
                toggleButton = emptyButton
            }

            let solveButtonWithSize = UIButtonWithSize(
                button: solveButton,
                width: actionButtonsInToolbar ? Constants.crosswordToolbarIconSize : 0,
                height: Constants.crosswordToolbarIconSize
            )

            let toggleButtonWithSize = UIButtonWithSize(
                button: toggleButton,
                width: actionButtonsInToolbar ? Constants.crosswordToolbarIconSize : 0,
                height: Constants.crosswordToolbarIconSize
            )


            if #available(iOS 26.0, *) {
                var leftContainerButton: UIBarButtonItem
                var rightContainerButton: UIBarButtonItem

                switch (clueCyclePlacement) {
                case 1: // split
                    leftContainerButton = self.createCustomButtonGroup(firstButton:
                                                                        previousButtonWithSize,
                                                                       secondButton: solveButtonWithSize)
                    rightContainerButton = self.createCustomButtonGroup(firstButton: toggleButtonWithSize,
                                                                        secondButton: nextButtonWithSize)
                case 2: // right
                    leftContainerButton = self.createCustomButtonGroup(firstButton: toggleButtonWithSize,
                                                                       secondButton: solveButtonWithSize)
                    rightContainerButton = self.createCustomButtonGroup(firstButton:
                                                                            previousButtonWithSize,
                                                                        secondButton: nextButtonWithSize)
                default: // left
                    leftContainerButton = self.createCustomButtonGroup(firstButton:
                                                                        previousButtonWithSize,
                                                                       secondButton: nextButtonWithSize)
                    rightContainerButton = self.createCustomButtonGroup(firstButton: solveButtonWithSize,
                                                                        secondButton:
                                                                            toggleButtonWithSize)
                }

                return [leftContainerButton, flexible, clueTitle, flexible, rightContainerButton]
            } else {
                // for some reason in < iOS 18 the container groups don't work
                switch (clueCyclePlacement) {
                case 1: // split
                    return [UIBarButtonItem(customView: previousButton), flexible,
                            UIBarButtonItem(customView: solveButton), fixed, clueTitle,
                            UIBarButtonItem(customView: toggleButton), flexible,
                            UIBarButtonItem(customView: nextButton)]
                case 2: // right
                    return [UIBarButtonItem(customView: toggleButton), fixed,
                            UIBarButtonItem(customView: solveButton), flexible, clueTitle, flexible,
                            UIBarButtonItem(customView: previousButton), fixed,
                            UIBarButtonItem(customView: nextButton)]
                default: // left
                    return [UIBarButtonItem(customView: previousButton), fixed,
                            UIBarButtonItem(customView: nextButton), flexible, clueTitle, flexible,
                            UIBarButtonItem(customView: solveButton), fixed,
                            UIBarButtonItem(customView: toggleButton)]
                }
            }
        }

        (self.inputAccessoryView as! UIToolbar).setItems(configuredToolbarItems, animated: false)

        (self.inputAccessoryView as! UIToolbar).backgroundColor = UIColor.systemGray6
    }

    func createCustomButtonGroup(firstButton: UIButtonWithSize, secondButton: UIButtonWithSize)
    -> UIBarButtonItem {
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                       target: nil,
                                       action: nil)
        if ((firstButton.width + secondButton.width) == 0) {
            return flexible
        }
        let containerWidth = firstButton.width + secondButton.width + (Constants.crosswordToolbarPadding)
        let containerView = UIView(frame: CGRectMake(0, 0, containerWidth,
                                                     Double(Constants.keybordToolbarHeight)))
        containerView.widthAnchor.constraint(equalToConstant: containerWidth).isActive = true
        firstButton.button.translatesAutoresizingMaskIntoConstraints = false
        secondButton.button.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(firstButton.button)
        containerView.addSubview(secondButton.button)

        NSLayoutConstraint.activate([
            firstButton.button.widthAnchor.constraint(equalToConstant: firstButton.width),
            firstButton.button.heightAnchor.constraint(equalToConstant: firstButton.height),
            firstButton.button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            firstButton.button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: 0)
        ])
        NSLayoutConstraint.activate([
            secondButton.button.widthAnchor.constraint(equalToConstant: secondButton.width),
            secondButton.button.heightAnchor.constraint(equalToConstant: secondButton.height),
            secondButton.button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            secondButton.button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: containerWidth/2)
        ])
        return UIBarButtonItem(customView: containerView)
            .hideSharedBackgroundIfAvailable()
    }
}
