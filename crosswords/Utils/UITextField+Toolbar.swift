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

let clueTitleFont = UIFont.systemFont(ofSize: 14)
let toolbarHeight = 40.0

extension UITextField {
    
    var nextImage: UIImage {
        UIImage.fontAwesomeIcon(name: .chevronRight, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
    }

    var previousImage: UIImage {
        UIImage.fontAwesomeIcon(name: .chevronLeft, style: FontAwesomeStyle.solid, textColor: UIColor.systemBlue, size: CGSize(width: 25, height: 25))
    }
    
    func changeToolbar(clueTitle: String, toggleImage: UIImage, coordinator: CrosswordTextFieldView.Coordinator, barColor: UIColor) {
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let clueTitleLabel = UILabel()
        clueTitleLabel.text = clueTitle
        clueTitleLabel.font = UIFont.systemFont(ofSize: 15)
        clueTitleLabel.textColor = UIColor.label
        clueTitleLabel.textAlignment = NSTextAlignment.center
        clueTitleLabel.numberOfLines = 2
        clueTitleLabel.lineBreakMode = .byWordWrapping
        clueTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        clueTitleLabel.preferredMaxLayoutWidth = UIScreen.screenWidth-150
        
        
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
    
    func addToolbar() {
        self.inputAccessoryView = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: Double(UIScreen.main.bounds.size.width), height: toolbarHeight))
    }
}
