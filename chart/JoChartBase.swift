//
//  JoChartBase.swift
//  JoChart
//
//  Created by jojo on 2020/1/10.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

public class JoChartBase: UIView {

    let colors: [UIColor] = [.hex(value: 0xc23531), .hex(value: 0xf4554), .hex(value: 0x61a0a8),
                             .hex(value: 0xd48265), .hex(value: 0x91c7ae), .hex(value: 0x749f83),
                             .hex(value: 0xca8622), .hex(value: 0xbda29a), .hex(value: 0x6e7074),
                             .hex(value: 0x546570), .hex(value: 0xc4ccd3)]

    lazy var toastView: JoToastView = {
        let toast = JoToastView.init()
        self.addSubview(toast)
        return toast
    }()

    private lazy var pan: JoImmediatelyPanGestureRecognizer = {
        [unowned self] in
        let gesture = JoImmediatelyPanGestureRecognizer.init(target: self, action: #selector(self.onPanTouch(sender:)))
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()

    public var enableTouch = false {
        didSet {
            if enableTouch {
                if self.pan.view == nil {
                    self.addGestureRecognizer(self.pan)
                }
            } else {
                if self.pan.view == self {
                    self.removeGestureRecognizer(self.pan)
                }
            }
        }
    }

    public init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func drawChart() {

    }

    @objc open func onPanTouch(sender: UIPanGestureRecognizer) {

    }
}

class JoToastView: UIView {
    private lazy var titleLabel: UILabel = {
        let lab = UILabel.init()
        lab.font = .systemFont(ofSize: 12)
        lab.numberOfLines = 0
        lab.textColor = .hex(value: 0x040404)
        return lab
    }()

    /// 显示位置的偏移修正
    public var offset = CGPoint.zero

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.layer.cornerRadius = 6
        self.alpha = 0
        self.isHidden = true
        self.addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    func show(message: NSAttributedString, location: CGPoint) {
//        var attributes = message.attributes(at: 0, effectiveRange: nil)
//        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
//        message.boundingRect(with: .init(width: 10, height: 10), options: options, context: nil)
//    }

    func show(message: String, location: CGPoint) {
        var maxWidth: CGFloat = 0
        if let sv = self.superview {
            maxWidth = sv.bounds.width / 2
            sv.bringSubviewToFront(self)
        }
        maxWidth = max(maxWidth, 200)

        let textBounding = message.bounding(withConstrainedWidth: maxWidth, font: titleLabel.font)
        let padding: CGFloat = 16
        let margin: CGFloat = 30
        let width = textBounding.width + padding
        let height = textBounding.height + padding
        var x = location.x - padding - width
        var y = location.y - padding - height

        if let sv = self.superview {
            if x + width > sv.bounds.maxX {
                x -= width + margin
            }
            if x < sv.bounds.minX {
                x += width + margin
            }

            if y < 0 {
                y += height + margin
                let frame = CGRect.init(x: x, y: y, width: width, height: height)
                if frame.contains(location) {
                    x = location.x + padding
                    y = 0
                }
            }
            if y + height > sv.bounds.maxY {
                y -= height + margin
            }
        }

        titleLabel.frame = .init(x: padding / 2, y: padding / 2, width: width - padding, height: height - padding)
        titleLabel.text = message

        x += offset.x
        y += offset.y

        if self.isHidden || self.alpha == 0 {
            self.frame = .init(x: x, y: y, width: width, height: height)
        } else {
            UIView.animate(withDuration: 0.15, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
                self.frame = .init(x: x, y: y, width: width, height: height)
            }, completion: nil)
        }

        self.isHidden = false
        if self.alpha < 1 {
            UIView.animate(withDuration: 0.15, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
                self.alpha = 1
            }, completion: nil)
        }
    }

    func hide() {
        if self.alpha == 0 || self.isHidden {
            return
        }

        UIView.animate(withDuration: 0.8, delay: 0, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
            self.alpha = 0
        }) {
            if $0 {
                self.isHidden = true
            }
        }
    }
}

class JoImmediatelyPanGestureRecognizer: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        self.state = .began
    }
}


extension UIColor {
    static func hex(value: Int) -> UIColor {
        let r = ((CGFloat)((value & 0xFF0000) >> 16)) / 255.0
        let g = ((CGFloat)((value & 0xFF00) >> 8)) / 255.0
        let b = ((CGFloat)(value & 0xFF)) / 255.0
        return UIColor.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension String {
    func bounding(withConstrainedWidth width: CGFloat, font: UIFont) -> CGRect {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        var boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        boundingBox.size.width = ceil(boundingBox.width)
        boundingBox.size.height = ceil(boundingBox.height)
        return boundingBox
    }

    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        return bounding(withConstrainedWidth: width, font: font).width
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension NSAttributedString {
    func bounding(withConstrainedWidth width: CGFloat) -> CGRect {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        var boundingBox = self.boundingRect(with: constraintRect, options: options, context: nil)

        boundingBox.size.width = ceil(boundingBox.width)
        boundingBox.size.height = ceil(boundingBox.height)
        return boundingBox
    }
}


extension CGFloat {
    func distance() {

    }
}
