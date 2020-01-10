//
//  YAxisLabel.swift
//  JoChart
//
//  Created by jojo on 2020/1/2.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class YAxisLabel: UIView {

    public var existFlag = false

    private lazy var titleLabel: UILabel = {
        let label = UILabel.init()
        label.font = .systemFont(ofSize: 9)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    private lazy var leftLine: UIView = {
        let li = UIView.init()
        li.backgroundColor = .black
        return li
    }()

    private lazy var rightLine: UIView = {
        let li = UIView.init()
        li.backgroundColor = .lightGray
        return li
    }()

    public var text: String? {
        didSet {
            titleLabel.text = text
            leftLine.isHidden = text == "0"
            rightLine.isHidden = text == "0"
        }
    }

    public var titleWidth: CGFloat = 0 {
        didSet {
            var frame = titleLabel.frame
            frame.size.width = titleWidth
            titleLabel.frame = frame
        }
    }

    override var frame: CGRect {
        set {
            super.frame = newValue
            titleLabel.frame = .init(x: 0, y: 0, width: titleWidth, height: frame.height)
            leftLine.frame = .init(x: titleLabel.frame.maxX + 2, y: titleLabel.frame.midY, width: 6, height: 1)
            rightLine.frame = .init(x: leftLine.frame.maxX, y: titleLabel.frame.midY, width: newValue.width - leftLine.frame.maxX, height: 1)
        }
        get {
            super.frame
        }
    }

    init() {
        super.init(frame: .zero)

        self.addSubview(titleLabel)
        self.addSubview(leftLine)
        self.addSubview(rightLine)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
