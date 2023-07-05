//
//  UITextField+Toolbar.swift
//  crosswords
//
//  Created by Rohan Narayan on 12/11/20.
//  Copyright © 2020 Rohan Narayan. All rights reserved.
//

import UIKit
import SwiftUI
import FontAwesome_swift

let toolbarHeight = 40.0

extension UITextField {
    
    var nextImage: UIImage {
        UIImage.fontAwesomeIcon(name: .chevronRight, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
    }

    var previousImage: UIImage {
        UIImage.fontAwesomeIcon(name: .chevronLeft, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
    }
    
    func changeToolbar(clueTitle: String, toggleImage: UIImage, barColor: UIColor) {
        let uiTextFieldToolbar = self.inputAccessoryView as! UIToolbar
        let clueTitleLabel = uiTextFieldToolbar.items![3].customView as! UITextView
        if (uiTextFieldToolbar.backgroundColor != barColor) {
            uiTextFieldToolbar.backgroundColor = barColor
        }
        if (clueTitleLabel.text != clueTitle) {
            uiTextFieldToolbar.items?.remove(at: 3)
            clueTitleLabel.text = clueTitle
            uiTextFieldToolbar.items?.insert(UIBarButtonItem.init(customView: clueTitleLabel), at: 3)
        }
        if (uiTextFieldToolbar.items![5].image != toggleImage) {
            uiTextFieldToolbar.items![5].image = toggleImage
        }
    }
    
    func addToolbar(coordinator: CrosswordTextFieldView.Coordinator, clueTitle: String, toggleImage: UIImage, barColor: UIColor) {
        self.inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.size.width), height: toolbarHeight))
        
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let clueTitleLabel = UITextView()
        var clueFontSize = UserDefaults.standard.integer(forKey: "clueSize")
        if (clueFontSize < 13) {
            clueFontSize = 13
        }
        
        clueTitleLabel.text = clueTitle
        clueTitleLabel.font = UIFont.systemFont(ofSize: CGFloat(clueFontSize))
        clueTitleLabel.textColor = UIColor.label
        clueTitleLabel.frame.size.width = UIScreen.screenWidth-150
        clueTitleLabel.backgroundColor = UIColor.clear
        clueTitleLabel.isEditable = false
        clueTitleLabel.textAlignment = NSTextAlignment.center
        clueTitleLabel.allowsEditingTextAttributes = false
        clueTitleLabel.isSelectable = false
        
        
        let clueTitle = UIBarButtonItem.init(customView: clueTitleLabel)
        
        
        let leftButton = UIBarButtonItem()
        leftButton.image = previousImage
        leftButton.target = coordinator
        leftButton.action = #selector(coordinator.goToPreviousClue)
        
        let rightButton = UIBarButtonItem()
        rightButton.image = nextImage
        rightButton.target = coordinator
        rightButton.action = #selector(coordinator.goToNextClue)
        
        let toggleButton = UIBarButtonItem()
        toggleButton.image = toggleImage
        toggleButton.target = coordinator
        toggleButton.action = #selector(coordinator.pressToggleButton)
        
        (self.inputAccessoryView as! UIToolbar).setItems([leftButton, rightButton, flexible, clueTitle, flexible, toggleButton], animated: false)
        
        (self.inputAccessoryView as! UIToolbar).backgroundColor = barColor
    }
}
