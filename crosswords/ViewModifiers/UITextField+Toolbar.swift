//
//  UITextField+Toolbar.swift
//  crosswords
//
//  Created by Rohan Narayan on 12/11/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import UIKit
import SwiftUI

extension UITextField {
    
    var nextImage: UIImage {
        return UIImage(systemName: "chevron.right")!
    }

    var previousImage: UIImage {
        return UIImage(systemName: "chevron.left")!
    }
    
    var solveCellImage: UIImage {
        return UIImage(systemName: "lifepreserver")!
    }
    
    var toggleImage: UIImage {
        return UIImage(systemName: "arrow.2.squarepath")!
    }
    
    func changeToolbar(clueTitle: String) {
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

        if (clueTitleLabel.text.trimmingCharacters(in: .whitespaces) != clueTitle.trimmingCharacters(in: .whitespaces)) {
            uiTextFieldToolbar.items?.remove(at: clueTitleIndex)
            clueTitleLabel.text = clueTitle
            uiTextFieldToolbar.items?.insert(
                UIBarButtonItem.init(customView: clueTitleLabel).hideSharedBackgroundIfAvailable(),
                at: clueTitleIndex
            )
        }
    }
    
    func addToolbar(coordinator: CrosswordTextFieldView.Coordinator) {
        self.inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0,
                                                          width: Double(UIScreen.main.bounds.size.width),
                                                          height: Double(Constants.keybordToolbarHeight)))
        let clueTitleLabel = UITextView()
        var clueFontSize = coordinator.parent.userSettings.clueSize
        if (clueFontSize < 13) {
            clueFontSize = 13
        }
        
        clueTitleLabel.text = ""
        clueTitleLabel.font = UIFont.systemFont(ofSize: CGFloat(clueFontSize))
        clueTitleLabel.textColor = UIColor.label
        clueTitleLabel.backgroundColor = UIColor.clear
        clueTitleLabel.isEditable = false
        clueTitleLabel.textAlignment = NSTextAlignment.center
        clueTitleLabel.allowsEditingTextAttributes = false
        clueTitleLabel.isSelectable = false
        
        let widthConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .width, relatedBy: .equal,
                                                 toItem: nil, attribute: .notAnAttribute, multiplier: 1.0,
                                                 constant: UIScreen.main.bounds.size.width-170)
        let heightConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .height, relatedBy: .equal,
                                                  toItem: nil, attribute: .notAnAttribute, multiplier: 1.0,
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
            fixed.width = 5

            let previousButton = UIButton.systemButton(with: previousImage,
                                                   target: coordinator,
                                                   action: #selector(coordinator.goToPreviousClue))

            let nextButton = UIButton.systemButton(with: nextImage,
                                                   target: coordinator,
                                                   action: #selector(coordinator.goToNextClue))

            let toggleButton = UIButton.systemButton(with: toggleImage,
                                                     target: coordinator,
                                                     action: #selector(coordinator.pressToggleButton))

            var solveCellButton = UIButton.systemButton(with: solveCellImage,
                                                        target: coordinator,
                                                        action: #selector(coordinator.solveCell))
            let emptyButton = UIButton()

            if (!CrosswordUtils.isSolutionAvailable(crossword: coordinator.parent.crossword)) {
                solveCellButton = emptyButton
            }

            if #available(iOS 26.0, *) {
                var leftContainerButton: UIBarButtonItem
                var rightContainerButton: UIBarButtonItem

                switch (coordinator.parent.userSettings.clueCyclePlacement) {
                case 1: // split
                    leftContainerButton = createCustomButtonGroup(firstButton: previousButton,
                                                                      secondButton: solveCellButton,
                                                                      firstButtonWidth: 20,
                                                                      secondButtonWidth: 20)
                    rightContainerButton = createCustomButtonGroup(firstButton: toggleButton,
                                                                       secondButton: nextButton,
                                                                       firstButtonWidth: 20,
                                                                       secondButtonWidth: 20)
                case 2: // right
                    leftContainerButton = createCustomButtonGroup(firstButton: toggleButton,
                                                                      secondButton: solveCellButton,
                                                                      firstButtonWidth: 20,
                                                                      secondButtonWidth: 20)
                    rightContainerButton = createCustomButtonGroup(firstButton: previousButton,
                                                                       secondButton: nextButton,
                                                                       firstButtonWidth: 20,
                                                                       secondButtonWidth: 20)
                default: // left
                    leftContainerButton = createCustomButtonGroup(firstButton: previousButton,
                                                                      secondButton: nextButton,
                                                                      firstButtonWidth: 20,
                                                                      secondButtonWidth: 20)
                    rightContainerButton = createCustomButtonGroup(firstButton: solveCellButton,
                                                                       secondButton: toggleButton,
                                                                       firstButtonWidth: 20,
                                                                       secondButtonWidth: 20)
                }

                return [leftContainerButton, flexible, clueTitle, flexible, rightContainerButton]
            } else {
                // for some reason in < iOS 18 the container groups don't work
                switch (coordinator.parent.userSettings.clueCyclePlacement) {
                case 1: // split
                    return [UIBarButtonItem(customView: previousButton), flexible,
                            UIBarButtonItem(customView: solveCellButton), fixed, clueTitle,
                            UIBarButtonItem(customView: toggleButton), flexible,
                            UIBarButtonItem(customView: nextButton)]
                case 2: // right
                    return [UIBarButtonItem(customView: toggleButton), fixed,
                            UIBarButtonItem(customView: solveCellButton), flexible, clueTitle, flexible,
                            UIBarButtonItem(customView: previousButton), fixed,
                            UIBarButtonItem(customView: nextButton)]
                default: // left
                    return [UIBarButtonItem(customView: previousButton), fixed,
                            UIBarButtonItem(customView: nextButton), flexible, clueTitle, flexible,
                            UIBarButtonItem(customView: solveCellButton), fixed,
                            UIBarButtonItem(customView: toggleButton)]
                }
            }
        }

        (self.inputAccessoryView as! UIToolbar).setItems(configuredToolbarItems, animated: false)

        (self.inputAccessoryView as! UIToolbar).backgroundColor = UIColor.systemGray6
    }

    func createCustomButtonGroup(firstButton: UIButton, secondButton: UIButton, firstButtonWidth: CGFloat,
                                 secondButtonWidth: CGFloat) -> UIBarButtonItem {
        let containerWidth = firstButtonWidth+secondButtonWidth+15
        let containerView = UIView(frame: CGRectMake(0, 0, containerWidth,
                                                     Double(Constants.keybordToolbarHeight)))
        containerView.widthAnchor.constraint(equalToConstant: containerWidth).isActive = true
        firstButton.translatesAutoresizingMaskIntoConstraints = false
        secondButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(firstButton)
        containerView.addSubview(secondButton)

        NSLayoutConstraint.activate([
            firstButton.widthAnchor.constraint(equalToConstant: firstButtonWidth),
            firstButton.heightAnchor.constraint(equalToConstant: firstButtonWidth),
            firstButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            firstButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: 0)
        ])
        NSLayoutConstraint.activate([
            secondButton.widthAnchor.constraint(equalToConstant: secondButtonWidth),
            secondButton.heightAnchor.constraint(equalToConstant: secondButtonWidth),
            secondButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            secondButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: containerWidth/2)
        ])
        return UIBarButtonItem(customView: containerView)
            .hideSharedBackgroundIfAvailable()
    }
}
