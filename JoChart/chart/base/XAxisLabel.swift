//
//  XAxisLabel.swift
//  JoChart
//
//  Created by jojo on 2020/1/2.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class XAxisLabel: UILabel {

    public var existFlag = false

    private lazy var line: UIView = {
        let l = UIView.init()
        l.backgroundColor = .black
        return l
    }()

    override var frame: CGRect {
        set {
            super.frame = newValue
            line.frame = .init(x: self.bounds.maxX - 1, y: 0, width: 1, height: 6)
        }
        get {
            super.frame
        }
    }

    init() {
        super.init(frame: .zero)

        self.font = .systemFont(ofSize: 9)
        self.text = text
        self.textColor = .black
        self.textAlignment = .center
        self.lineBreakMode = .byTruncatingMiddle

        self.addSubview(line)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
