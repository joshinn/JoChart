//
//  JoPieChart.swift
//  JoChart
//
//  Created by jojo on 2020/1/16.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

public class JoPieChart: JoChartBase {

    private var listData: [JoPieValue] = []
    private var pies: [JoPiePart] = []

    private lazy var centerLabel: UILabel = {
        let lab = UILabel.init()
        lab.adjustsFontSizeToFitWidth = true
        lab.textAlignment = .center
        lab.numberOfLines = 0
        self.addSubview(lab)
        return lab
    }()

    private var panSelectIndex = -1

    public var pieWidth: CGFloat = 5
    public var pieCenter: CGPoint? = nil
    public var pieRadius: CGFloat? = nil

    public var touchBlock: ((_ name: String, _ value: CGFloat, _ color: UIColor) -> String)? = nil
    
    public var selectKey: String? {
        didSet {
            if selectKey != nil {
                pies.forEach {
                    $0.selected = selectKey == $0.key
                }
                for data in listData {
                    if data.key == selectKey {
                        centerLabel.text = data.name
                        centerLabel.textColor = data.color ?? .white
                    }
                }
            } else {
                pies.forEach {
                    $0.selected = false
                }
                centerLabel.text = nil
            }
        }
    }

    public override init() {
        super.init()
        self.enableTouch = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func drawChart() {
        super.drawChart()

        handlePie()
    }

    private func handlePie() {

        if pieRadius == nil {
            pieRadius = min(self.bounds.width, self.bounds.height) / 2 - pieWidth / 2
        }

        if pieCenter == nil {
            pieCenter = .init(x: self.bounds.midX, y: self.bounds.midY)
        }

        let labelWidth = (pieRadius! - pieWidth / 2) * 1.4
        self.centerLabel.frame = .init(x: 0, y: 0, width: labelWidth, height: labelWidth)
        self.centerLabel.center = pieCenter!
        self.centerLabel.font = .systemFont(ofSize: max(10, labelWidth / 6))

        pies.forEach {
            $0.existFlag = false
        }
        
        var sum: CGFloat = 0
        var colorIndex = 0
        for (i, data) in listData.enumerated() {
            if !data.active {
                continue
            }
            sum += data.value

            if data.color == nil {
                
                listData[i].color = JoChartBase.colors[colorIndex % JoChartBase.colors.count]
                colorIndex += 1
            }
        }

        var accumulate: CGFloat = 0 //< 百分比累计
        for (i, data) in listData.enumerated() {
            if !data.active {
                continue
            }
            
            var pie: JoPiePart? = nil
            for p in pies {
                if p.key == data.key {
                    pie = p
                    pie?.existFlag = true
                    p.removeFromSuperlayer()
                    self.layer.addSublayer(p)
                    break
                }
            }

            var isNewPie = false
            if pie == nil {
                isNewPie = true
                pie = JoPiePart.init(key: data.key)
                pie!.existFlag = true
                pies.append(pie!)
                self.layer.addSublayer(pie!)
            }

            pie!.pieWidth = pieWidth
            pie!.strokeColor = data.color!.cgColor
            pie!.path = UIBezierPath.init(arcCenter: pieCenter!, radius: pieRadius!, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 2 * 3, clockwise: true).cgPath

            let from = accumulate

            listData[i].percent = data.value / sum
            accumulate += listData[i].percent

            let to = accumulate

            if isNewPie {
                pie!.strokeStart = from
                pie!.strokeEnd = to
                pie!.appear()
            } else {
                
                pie!.update(start: from, end: to)
            }
        }

        pies.removeAll {
            if !$0.existFlag {
                $0.removeFromSuperlayer()
            }
            return !$0.existFlag
        }
        
    }

    public func setOptions(_ data: [JoPieValue]) {
        listData.removeAll()
        listData += data
    }

    public override func onPanTouch(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            panBegin(sender)

        } else if sender.state == .changed {
            panMove(sender)

        } else if sender.state == .ended || sender.state == .cancelled {
            panEnd(sender)
        }
    }
}

extension JoPieChart {
    func panBegin(_ sender: UIPanGestureRecognizer) {
        handleTouch(sender.location(in: self))
    }

    func panMove(_ sender: UIPanGestureRecognizer) {
        handleTouch(sender.location(in: self))
    }

    func panEnd(_ sender: UIPanGestureRecognizer) {
        clearToast()
    }

    func clearToast() {
        panSelectIndex = -1
        if let s = selectKey {
            selectKey = s
        } else {
            pies.forEach {
                $0.selected = false
            }
            centerLabel.text = nil
        }
        
        toastView.hide()
    }

    func handleTouch(_ location: CGPoint) {

        // is location in pie area
        let distance = hypot(location.x - self.pieCenter!.x, location.y - self.pieCenter!.y)
        if distance > self.pieRadius! + self.pieWidth / 2 || distance < self.pieRadius! - self.pieWidth / 2 {
            clearToast()
            return
        }


        var selectPieIndex = -1

        let angle = atan2(location.y - self.pieCenter!.y, location.x - self.pieCenter!.x)
        var percent: CGFloat = 0
        if angle < -CGFloat.pi / 2 {
            percent = (2 * CGFloat.pi + angle + CGFloat.pi / 2) / CGFloat.pi / 2
        } else {
            percent = (angle + CGFloat.pi / 2) / CGFloat.pi / 2
        }

        var accumulate: CGFloat = 0
        for (i, data) in listData.enumerated() {
            if !data.active {
                continue
            }

            accumulate += data.percent

            if percent < accumulate {
                selectPieIndex = i
                break
            }
        }

        if selectPieIndex < 0 || selectPieIndex == panSelectIndex {
            return
        }

        panSelectIndex = selectPieIndex

        for pie in pies {
            pie.selected = pie.key == listData[selectPieIndex].key
        }

        let selectData = listData[selectPieIndex]
        self.centerLabel.text = selectData.name
        self.centerLabel.textColor = selectData.color

        if let callback = touchBlock {
            let msg = callback(selectData.name, selectData.value, selectData.color!)
            toastView.show(message: msg, location: location)
        } else {
            let perValue = round(selectData.percent * 100 * 100) / 100
            toastView.show(message: "\(selectData.name): \(selectData.value)(\(perValue)%)", location: location)
        }
    }
}

public struct JoPieValue {
    public var key = UUID.init().uuidString
    public var name: String
    public var value: CGFloat
    public var color: UIColor?
    public var active = true
    public var percent: CGFloat = 0

    public init(name: String, value: CGFloat, color: UIColor?) {
        self.name = name
        self.value = value
        self.color = color
    }

    public init(name: String, value: CGFloat) {
        self.init(name: name, value: value, color: nil)
    }

}

class JoPiePart: CAShapeLayer {

    public private(set) var key: String

    public var existFlag = false

    /// 替代lineWidth
    public var pieWidth: CGFloat = 0 {
        didSet {
            self.lineWidth = pieWidth
            selectedWidth = min(0.2 * pieWidth, 10)
            selectedWidth = max(selectedWidth, 5)
        }
    }
    private var selectedWidth: CGFloat = 0

    public var selected = false {
        didSet {
            if selected {
                self.lineWidth = pieWidth + selectedWidth
                self.shadowColor = UIColor.black.cgColor
                self.shadowOffset = .init(width: 1, height: 1)
                self.shadowRadius = 4
                self.shadowOpacity = 0.35
            } else {
                self.lineWidth = pieWidth
                self.shadowColor = nil
                self.shadowOpacity = 0
                self.shadowOffset = .zero
            }
        }
    }

    init(key: String) {
        self.key = key

        super.init()

        self.fillColor = nil

    }

    override init(layer: Any) {
        self.key = ""
        if let part  = layer as? JoPiePart {
            self.key = part.key
        }
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension JoPiePart {
    func appear() {
        let animation = CABasicAnimation.init(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.5
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        self.add(animation, forKey: "drawPie")
    }

    func update(start: CGFloat, end: CGFloat) {

        let group = CAAnimationGroup.init()
        group.isRemovedOnCompletion = true

        let startAnim = CABasicAnimation.init(keyPath: "strokeStart")
        startAnim.fromValue = self.strokeStart
        startAnim.toValue = start
        startAnim.duration = 0.3
        startAnim.timingFunction = .init(name: .linear)
        startAnim.fillMode = .forwards

        let endAnim = CABasicAnimation.init(keyPath: "strokeEnd")
        endAnim.fromValue = self.strokeEnd
        endAnim.toValue = end
        endAnim.duration = 0.3
        endAnim.timingFunction = .init(name: .linear)
        endAnim.fillMode = .forwards

        group.animations = [startAnim, endAnim]
        self.add(group, forKey: "updatePie")

        self.strokeStart = start
        self.strokeEnd = end

    }
}
