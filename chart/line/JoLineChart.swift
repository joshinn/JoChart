//
//  JoLineChart.swift
//  JoChart
//
//  Created by jojo on 2019/12/29.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

class JoLineChart: AxisChartBase {

    override func drawChart() {
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

