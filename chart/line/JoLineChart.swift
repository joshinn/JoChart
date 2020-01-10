//
//  JoLineChart.swift
//  JoChart
//
//  Created by jojo on 2019/12/29.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

public class JoLineChart: AxisChartBase {

    override public func drawChart() {
        super.drawChart()
        handleLines()
    }

    private func handleLines() {

        let xAxisLength = canvasView.frame.width
        let xLabelWidth = xAxisLength / CGFloat(xLabels.count)

        var circleX = xLabelWidth / CGFloat(2)

        for line in lines {
            line.existFlag = false
        }

        for data in listData {
            var points: [CGPoint] = []

            var line: JoLine? = nil
            for var value in data.values {
                value.point.x = circleX
                value.point.y = (yAxisLimit - value.value) / yAxisLimit * canvasView.bounds.maxY

                circleX += xLabelWidth

                points.append(value.point)
            }

            for li in lines {
                if li.key == data.key && data.active {
                    line = li
                    li.existFlag = true

                }
            }

            circleX = xLabelWidth / CGFloat(2)

            if line != nil {
                line!.lineColor = data.color
                line!.update(points: points)
            } else if data.active {
                line = JoLine.init(key: data.key, points: points)
                line!.lineColor = data.color
                line!.existFlag = true
                lines.append(line!)
                canvasView.layer.addSublayer(line!)
                line!.appear()
            }

        }

        lines.removeAll {
            if !$0.existFlag {
                $0.removeFromSuperlayer()
            }
            return !$0.existFlag
        }
    }
}

class JoLine: CAShapeLayer {
    private var points: [CGPoint] = []
    private var circlePoints: [JoPoint] = []

    public private(set) var key: String

    public var existFlag = false

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
            let circlePoint = JoPoint.init(location: p)
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

    func update(points: [CGPoint]) {
        self.points.removeAll()
        self.points += points

        let path = UIBezierPath.init()

        for (index, p) in points.enumerated() {
            var circle: JoPoint? = nil

            if circlePoints.count > index {
                circle = circlePoints[index]
                circle!.update(location: p)
            } else {
                circle = JoPoint.init(location: p)
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

class JoPoint: CAShapeLayer {
    init(location: CGPoint) {
        super.init()

        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 1
        self.fillColor = UIColor.white.cgColor

        let path = UIBezierPath.init(arcCenter: location, radius: 3, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        self.path = path.cgPath
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(location: CGPoint) {

        let path = UIBezierPath.init(arcCenter: location, radius: 3, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        let animation = CABasicAnimation.init(keyPath: "path")
        animation.fromValue = self.path
        self.path = path.cgPath
        animation.toValue = self.path
        animation.duration = 0.3
        animation.timingFunction = .init(name: .linear)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        self.add(animation, forKey: "changePath")

    }
}
