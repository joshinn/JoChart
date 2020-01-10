//
//  ChartBase.swift
//  JoChart
//
//  Created by jojo on 2020/1/10.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class ChartBase: UIView {

    let colors: [UIColor] = [.hex(value: 0xc23531), .hex(value: 0xf4554), .hex(value: 0x61a0a8),
                             .hex(value: 0xd48265), .hex(value: 0x91c7ae), .hex(value: 0x749f83),
                             .hex(value: 0xca8622), .hex(value: 0xbda29a), .hex(value: 0x6e7074),
                             .hex(value: 0x546570), .hex(value: 0xc4ccd3)]

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func drawChart() {

    }
}


extension UIColor {
    fileprivate static func hex(value: Int) -> UIColor {
        let r = ((CGFloat)((value & 0xFF0000) >> 16)) / 255.0
        let g = ((CGFloat)((value & 0xFF00) >> 8)) / 255.0
        let b = ((CGFloat)(value & 0xFF)) / 255.0
        return UIColor.init(red: r, green: g, blue: b, alpha: 1)
    }
}