//
//  UITextField+Toolbar.swift
//  crosswords
//
//  Created by Rohan Narayan on 12/11/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import UIKit
import SwiftUI

let toolbarHeight = 40.0

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
    
    
    func changeToolbar(clueTitle: String, toggleImage: UIImage, barColor: UIColor) {
        
        guard let uiTextFieldToolbar = self.inputAccessoryView as? UIToolbar else {
            print("inputAccessoryView is nil or not a UIToolbar")
            return
        }

        let clueTitleIndex = 3
        let clueTitleLabel = uiTextFieldToolbar.items![clueTitleIndex].customView as! UITextView
        let toggleButtonIndex =
            switch UserDefaults.standard.integer(forKey: "clueCyclePlacement") {
                case 1:
                    4
                case 2:
                    0
                default:
                    6
            }

        if (uiTextFieldToolbar.backgroundColor != barColor) {
            uiTextFieldToolbar.backgroundColor = barColor
        }
        if (clueTitleLabel.text.trimmingCharacters(in: .whitespaces) != clueTitle.trimmingCharacters(in: .whitespaces)) {
            uiTextFieldToolbar.items?.remove(at: clueTitleIndex)
            clueTitleLabel.text = clueTitle
            uiTextFieldToolbar.items?.insert(UIBarButtonItem.init(customView: clueTitleLabel), at: clueTitleIndex)
        }
        
        let toggle = uiTextFieldToolbar.items![toggleButtonIndex]
        if (toggle.image != toggleImage) {
            toggle.image = toggleImage
        }
    }
    
    func addToolbar(coordinator: CrosswordTextFieldView.Coordinator, clueTitle: String, toggleImage: UIImage, barColor: UIColor) {
        self.inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.size.width), height: toolbarHeight))
                
        let clueTitleLabel = UITextView()
        var clueFontSize = UserDefaults.standard.integer(forKey: "clueSize")
        if (clueFontSize < 13) {
            clueFontSize = 13
        }
        
        clueTitleLabel.text = clueTitle
        clueTitleLabel.font = UIFont.systemFont(ofSize: CGFloat(clueFontSize))
        clueTitleLabel.textColor = UIColor.label
        clueTitleLabel.backgroundColor = UIColor.clear
        clueTitleLabel.isEditable = false
        clueTitleLabel.textAlignment = NSTextAlignment.center
        clueTitleLabel.allowsEditingTextAttributes = false
        clueTitleLabel.isSelectable = false
        
        let widthConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIScreen.screenWidth-150)
        let heightConstraint = NSLayoutConstraint(item: clueTitleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: toolbarHeight)

        clueTitleLabel.addConstraints([widthConstraint, heightConstraint])
        
        var configuredToolbarItems: [UIBarButtonItem] {
            
            let clueTitle = UIBarButtonItem(customView: clueTitleLabel)
            
            let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                           target: nil,
                                           action: nil)

            let leftButton = UIBarButtonItem(image: previousImage,
                                             style: .plain,
                                             target: coordinator,
                                             action: #selector(coordinator.goToPreviousClue))
            
            let rightButton = UIBarButtonItem(image: nextImage,
                                              style: .plain,
                                              target: coordinator,
                                              action: #selector(coordinator.goToNextClue))

            let toggleButton = UIBarButtonItem(image: toggleImage,
                                               style: .plain,
                                               target: coordinator,
                                               action: #selector(coordinator.pressToggleButton))

            let solveCellButton: UIBarButtonItem = {
                if coordinator.isSolutionAvailable(textField: self as! NoActionTextField) {
                    return UIBarButtonItem(image: solveCellImage, style: .plain, target: coordinator, action: #selector(coordinator.solveCell))
                } else {
                    return flexible
                }
            }()
            
            switch UserDefaults.standard.integer(forKey: "clueCyclePlacement") {
            case 1:
                return [leftButton, flexible, solveCellButton, clueTitle, toggleButton, flexible, rightButton]
            case 2:
                return [toggleButton, solveCellButton, flexible, clueTitle, flexible, leftButton, rightButton]
            default:
                return [leftButton, rightButton, flexible, clueTitle, flexible, solveCellButton, toggleButton]
            }
        }
        
        (self.inputAccessoryView as! UIToolbar).setItems(configuredToolbarItems, animated: false)
        
        (self.inputAccessoryView as! UIToolbar).backgroundColor = barColor
    }
}
