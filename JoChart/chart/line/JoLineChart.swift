//
//  JoLineChart.swift
//  JoChart
//
//  Created by jojo on 2019/12/29.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

class JoLineChart: UIView {

    private lazy var xAxisLine: CAShapeLayer = {
        let line = CAShapeLayer.init()
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        return line
    }()

    private lazy var yAxisLine: CAShapeLayer = {
        let line = CAShapeLayer.init()
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        return line
    }()
    
    private lazy var canvasView: UIView = {
        let v = UIView.init()
        v.backgroundColor = .init(white: 1, alpha: 0.4)
        return v
    }()

    private var zeroPoint = CGPoint.zero
    
    private var listData: [JoLineData] = []
    
    private var xLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    private var lines: [JoLine] = []

    func draw() {
        for line in lines {
            line.removeFromSuperlayer()
        }
        lines.removeAll()
        listData.removeAll()
        
        listData.append(.init(name: "邮件营销", values: [120, 132.56, 101, 134, 90, 230.3333333, 230.3333333]))
        
        if xAxisLine.superlayer == nil {
            self.layer.addSublayer(xAxisLine)
        }
        if yAxisLine.superlayer == nil {
            self.layer.addSublayer(yAxisLine)
        }
        if canvasView.superview == nil {
            self.addSubview(canvasView)
        }

        canvasView.frame = .init(x: 40, y: 20, width: self.bounds.maxX - 40 - 20, height: self.bounds.maxY - 40 - 20)
        zeroPoint.x = canvasView.frame.minX
        zeroPoint.y = canvasView.frame.maxY

        let path = UIBezierPath.init()
        path.move(to: .init(x: zeroPoint.x - 5, y: zeroPoint.y))
        path.addLine(to: CGPoint.init(x: canvasView.frame.maxX, y: zeroPoint.y))
        xAxisLine.path = path.cgPath
        
        let xAxisLength = canvasView.frame.width
        
        path.removeAllPoints()
        
        path.move(to: .init(x: zeroPoint.x, y: zeroPoint.y + 5))
        path.addLine(to: CGPoint.init(x: zeroPoint.x, y: canvasView.frame.minY))
        yAxisLine.path = path.cgPath
        
        let yAxisLength = canvasView.frame.height
        
        let (limit, n) = handleYAxis()
        
        let yLabel = UILabel.init()
        yLabel.font = .systemFont(ofSize: 9)
        if limit > 1 {
            yLabel.text = "\(Int(limit))"
        } else {
            yLabel.text = "\(limit)"
        }
        yLabel.textColor = .black
        yLabel.textAlignment = .right
        self.addSubview(yLabel)
        yLabel.frame = .init(x: 0, y: canvasView.frame.minY - 6, width: canvasView.frame.minX - 8, height: 12)
        
        
        let xLabelWidth = xAxisLength / CGFloat(xLabels.count)
        var xLabelX = xLabelWidth / CGFloat(2)
        
        for (index, text) in xLabels.enumerated() {
            let xLabel = UILabel.init()
            xLabel.font = .systemFont(ofSize: 9)
            xLabel.text = text
            xLabel.textColor = .black
            xLabel.textAlignment = .center
            self.addSubview(xLabel)
            xLabel.frame = .init(x: canvasView.frame.minX + CGFloat(index) * xLabelWidth, y: canvasView.frame.maxY + 6, width: xLabelWidth, height: 12)
            
        }
        
        for data in listData {
            var points: [CGPoint] = []
            
            for  var value in data.values {
                value.point.x = xLabelX
                value.point.y = (limit - value.value) / limit * canvasView.bounds.maxY
                
                xLabelX += xLabelWidth
                
                points.append(value.point)
            }
            
            xLabelX = xLabelWidth / CGFloat(2)
            
            let line = JoLine.init(points: points)
            lines.append(line)
            canvasView.layer.addSublayer(line)
            line.appear()
        }
    }

    func handleYAxis() -> (yLimit: CGFloat, count: Int) {
        var maxValue:CGFloat = 0
        for data in listData {
            for value in data.values {
                if value.value > maxValue {
                    maxValue = value.value
                }
            }
        }
        
        var temp: CGFloat = 10
        var n = 0
        var limit: CGFloat = 0
        if (maxValue < 1) {
            
            while (temp * maxValue) < 1 {
                temp *= 10
            }
            
            temp /= 10
            
            temp = 1 / temp
            for i in 1...10 {
                limit = CGFloat(i) * temp
                if limit >= maxValue {
                    n = i
                    print("limit=\(limit) i=\(i)")
                    break
                }
            }
            
        } else {
            
            while (maxValue / temp) > 1 {
                temp *= 10
            }
            
            temp /= 10
            
            for i in 1...10 {
                limit = CGFloat(i) * temp
                if limit >= maxValue {
                    n = i
                    print("limit=\(limit) i=\(i)")
                    break
                }
            }
        }
        
        return (limit, n)
    }
}

struct ValueModel {
    var value:CGFloat
    var point = CGPoint.zero
}

struct JoLineData {
    var name: String
    var values: [ValueModel]
    
    init(name: String, values: [CGFloat]) {
        self.name = name
        var array: [ValueModel] = []
        for v in values {
            array.append(.init(value: v))
        }
        self.values = array
    }
}
