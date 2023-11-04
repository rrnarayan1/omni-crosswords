//
//  UIImage+Size.swift
//  crosswords
//
//  Created by Rohan Narayan on 11/3/23.
//  Copyright © 2023 Rohan Narayan. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func imageWith(newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return image.withRenderingMode(renderingMode)
    }
}
