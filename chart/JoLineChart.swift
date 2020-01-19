//
//  JoLineChart.swift
//  JoChart
//
//  Created by jojo on 2019/12/29.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

struct SelectIndex {
    var index1 = -1
    var index2 = -1
}

public class JoLineChart: JoAxisChartBase {

    private var lines: [JoLine] = []

    override public func drawChart() {
        super.drawChart()
        handleLines()
    }

    private var panSelectIndex = SelectIndex()
    public var touchBlock: ((_ name: String, _ value: CGFloat, _ color: UIColor) -> String)? = nil

    private func handleLines() {

        let xAxisLength = canvasView.frame.width
        let xLabelWidth = xAxisLength / CGFloat(xLabels.count)

        var circleX = xLabelWidth / CGFloat(2)

        lines.forEach {
            $0.existFlag = false
        }

        for (i, var data) in listData.enumerated() {
            var points: [CGPoint] = []

            var line: JoLine? = nil
            for (j, var value) in data.values.enumerated() {
                value.point.x = circleX
                value.point.y = (yAxisLimit - value.value) / yAxisLimit * canvasView.bounds.maxY

                data.values[j] = value

                circleX += xLabelWidth

                points.append(value.point)
            }

            for li in lines {
                if li.key == data.key && data.active {
                    line = li
                    li.existFlag = true
                    break
                }
            }

            circleX = xLabelWidth / CGFloat(2)

            if line != nil {
                line!.lineColor = data.color
                line!.removeFromSuperlayer()
                canvasView.layer.addSublayer(line!)
                line!.update(points: points)
            } else if data.active {
                line = JoLine.init(key: data.key, points: points)
                line!.lineColor = data.color
                line!.existFlag = true
                lines.append(line!)
                canvasView.layer.addSublayer(line!)
                line!.appear()
            }

            listData[i] = data
        }

        lines.removeAll {
            if !$0.existFlag {
                $0.removeFromSuperlayer()
            }
            return !$0.existFlag
        }
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

extension JoLineChart {

    func panBegin(_ sender: UIPanGestureRecognizer) {
        handleTouch(sender.location(in: self.canvasView))
    }

    func panMove(_ sender: UIPanGestureRecognizer) {
        handleTouch(sender.location(in: self.canvasView))
    }

    func panEnd(_ sender: UIPanGestureRecognizer) {
        panSelectIndex = SelectIndex()
        lines.forEach {
            if $0.selected {
                $0.selected = false
            }
        }
        toastView.hide()
    }

    func handleTouch(_ location: CGPoint) {

        var minDistance: CGFloat = -1
        var selectLineIndex = -1
        var selectPointIndex = -1

        for (i, lineData) in listData.enumerated() {
            if !lineData.active {
                continue
            }

            var lastDistance: CGFloat = -1

            for (j, pointData) in lineData.values.enumerated() {

                let distance = hypot(location.x - pointData.point.x, location.y - pointData.point.y)
//                let distance = abs(location.x - pointData.point.x)

                if distance < 15 {
                    if minDistance < 0 {
                        selectLineIndex = i
                        selectPointIndex = j
                        minDistance = distance
                        lastDistance = distance

                    } else if distance < minDistance {
                        selectLineIndex = i
                        selectPointIndex = j
                        minDistance = distance

                        if lastDistance >= 0 && lastDistance < distance {
                            break
                        }
                        lastDistance = distance
                    }
                }

            }
        }

        if selectLineIndex >= 0 && selectPointIndex >= 0 {
            if panSelectIndex.index1 != selectLineIndex || panSelectIndex.index2 != selectPointIndex {
                panSelectIndex.index1 = selectLineIndex
                panSelectIndex.index2 = selectPointIndex

                let lineData = listData[selectLineIndex]
                let pointData = lineData.values[selectPointIndex]

                lines.forEach {
                    $0.selected = $0.key == lineData.key
                }
                
                if let callback = touchBlock {
                    let msg = callback(lineData.name, pointData.value, lineData.color!)
                    toastView.show(message: msg, location: pointData.point)
                } else {
                    toastView.show(message: "\(lineData.name): \(pointData.value)", location: pointData.point)
                }

            }
        }
    }
}

class JoLine: CAShapeLayer {
    private var points: [CGPoint] = []
    private var circlePoints: [JoLinePoint] = []

    public private(set) var key: String

    public var existFlag = false
    
    public var selected = false {
        didSet {
            circlePoints.forEach {
                $0.selected = selected
            }
        }
    }

    public var lineColor: UIColor? {
        didSet {
            if lineColor != nil {
                self.strokeColor = lineColor!.cgColor
                for circle in circlePoints {
                    circle.strokeColor = lineColor!.cgColor
                }
            }
        }
    }

    init(key: String, points: [CGPoint]) {
        self.key = key

        super.init()

        self.points += points

        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 1.5
        self.fillColor = nil
        self.strokeStart = 0
        self.strokeEnd = 1

        let path = UIBezierPath.init()
        for (index, p) in points.enumerated() {
            let circlePoint = JoLinePoint.init(location: p)
            circlePoints.append(circlePoint)
            self.addSublayer(circlePoint)

            if index == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }
        }
        self.path = path.cgPath
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension JoLine {
    func update(points: [CGPoint]) {
        self.points.removeAll()
        self.points += points

        let path = UIBezierPath.init()

        for (index, p) in points.enumerated() {
            var circle: JoLinePoint? = nil

            if circlePoints.count > index {
                circle = circlePoints[index]
                circle!.update(location: p, radius: 3, duration: 0.3)
            } else {
                circle = JoLinePoint.init(location: p)
                circlePoints.append(circle!)
                self.addSublayer(circle!)
            }

            if index == 0 {
                path.move(to: p)
            } else {
                path.addLine(to: p)
            }

            if index == points.count - 1 && circlePoints.count - index > 1 { // 有多余的圆圈
                let range = index + 1...circlePoints.count - 1
                for i in range {
                    circlePoints[i].removeFromSuperlayer()
                }
                circlePoints.removeSubrange(range)
            }

        }

        let animation = CABasicAnimation.init(keyPath: "path")
        animation.fromValue = self.path
        animation.toValue = path.cgPath
        animation.duration = 0.3
        animation.timingFunction = .init(name: .linear)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        self.add(animation, forKey: "changePath")
        self.path = path.cgPath

    }

    func appear() {
        let animation = CABasicAnimation.init(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.5
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        self.add(animation, forKey: "drawLine")
    }
}

class JoLinePoint: CAShapeLayer {
    private var location: CGPoint
    
    public var selected = false {
        didSet {
            update(location: location, radius: selected ? 5 : 3, duration: 0.15)
        }
    }
    
    init(location: CGPoint) {
        self.location = location
        
        super.init()

        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 1
        self.fillColor = UIColor.white.cgColor

        let path = UIBezierPath.init(arcCenter: location, radius: 3, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        self.path = path.cgPath
    }
    
    override init(layer: Any) {
        location = .zero
        if let line  = layer as? JoLinePoint {
            location = line.location
        }
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension JoLinePoint {
    func update(location: CGPoint, radius: CGFloat, duration: CFTimeInterval) {
        self.location = location
        
        let path = UIBezierPath.init(arcCenter: location, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        let animation = CABasicAnimation.init(keyPath: "path")
        animation.fromValue = self.path
        self.path = path.cgPath
        animation.toValue = self.path
        animation.duration = duration
        animation.timingFunction = .init(name: .linear)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        self.add(animation, forKey: "changePath")
    }
    
}
