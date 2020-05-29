//
//  Util.swift
//  JoChart
//
//  Created by jojo on 2020/2/3.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

extension CGFloat {
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    static var OnePixel: CGFloat  {
        return 1 / UIScreen.main.scale
    }
}
