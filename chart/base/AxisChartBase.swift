//
//  AxisChartBase.swift
//  JoChart
//
//  Created by jojo on 2020/1/10.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit


struct ValueModel {
    var value: CGFloat
    var point = CGPoint.zero
}

struct JoAxisData {
    var key = UUID.init().uuidString
    var name: String
    var values: [ValueModel]
    var color: UIColor?
    var active = true

    init(name: String, values: [CGFloat]) {
        self.name = name
        var array: [ValueModel] = []
        for v in values {
            array.append(.init(value: v))
        }
        self.values = array
    }
}

class AxisChartBase: ChartBase {

    lazy var xAxisLine: CAShapeLayer = {
        let line = CAShapeLayer.init()
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        return line
    }()

    lazy var yAxisLine: CAShapeLayer = {
        let line = CAShapeLayer.init()
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        return line
    }()

    lazy var canvasView: UIView = {
        let v = UIView.init()
        v.backgroundColor = .init(white: 1, alpha: 0.4)
        return v
    }()

    lazy var indicatorCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let cv = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self

        cv.register(JoIndicatorCell.self, forCellWithReuseIdentifier: JoIndicatorCell.ReuseIdentifier)
        return cv
    }()

    var zeroPoint = CGPoint.zero

    var listData: [JoAxisData] = []

    var xLabels: [String] = []

    var lines: [JoLine] = []

    var yAxisLimit: CGFloat = 0

    public var showLegend = true {
        didSet {
            indicatorCV.isHidden = !showLegend
        }
    }

    open func handleYAxis() {
        var maxValue: CGFloat = 0
        for data in listData {
            if data.active {
                for value in data.values {
                    if value.value > maxValue {
                        maxValue = value.value
                    }
                }
            }
        }

        if maxValue == 0 { // 如果y轴最大值是0，则不绘制Y轴标签，并移除所有旧的
            let subviews = self.subviews
            for sv in subviews {
                if let label = sv as? YAxisLabel {
                    label.removeFromSuperview()
                }
            }

            return
        }

        var temp: CGFloat = 10
        var n = 0
        var scale = 1
        var limit: CGFloat = 0
        if (maxValue < 1) {

            while (temp * maxValue) < 1 {
                temp *= 10
            }

            temp /= 10

            temp = 1 / temp

            if (maxValue > 5 * temp) {
                scale = 2
            }
            for i in 1...5 {
                limit = CGFloat(i) * temp * CGFloat(scale)
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
            if (maxValue > 5 * temp) {
                scale = 2
            }

            for i in 1...5 {
                limit = CGFloat(i * scale) * temp
                if limit >= maxValue {
                    n = i
                    print("limit=\(limit) i=\(i)")
                    break
                }
            }
        }


        let yAxisItemWidth = canvasView.frame.height / CGFloat(n)

        for sv in self.subviews {
            if let label = sv as? YAxisLabel {
                label.existFlag = false
            }
        }

        var subviews = self.subviews

        for i in 0...n {
            var yLabel: YAxisLabel? = nil
            var text: String
            if temp > 1 {
                text = "\(Int(temp) * i * scale)"
            } else {
                text = "\(temp * CGFloat(i * scale))"
            }

            let y = zeroPoint.y - 6 - CGFloat(i) * yAxisItemWidth
            let yTitleWidth = canvasView.frame.minX - 8
            let frame = CGRect.init(x: 0, y: y, width: canvasView.frame.maxX, height: 12)
            for (index, sv) in subviews.enumerated() {
                if let label = sv as? YAxisLabel {
                    if (label.text == text) {
                        yLabel = label
                        subviews.remove(at: index) // remove item for next loop fast
                        break
                    }
                }
            }

            if yLabel != nil {
                yLabel!.titleWidth = yTitleWidth
                yLabel!.existFlag = true
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    yLabel!.frame = frame
                }, completion: nil)
            } else {
                yLabel = YAxisLabel.init()
                yLabel!.titleWidth = yTitleWidth
                yLabel!.existFlag = true
                yLabel!.text = text
                yLabel!.frame = frame
                self.insertSubview(yLabel!, at: 0)
            }

        }

        for sv in self.subviews {
            if let label = sv as? YAxisLabel {
                if !label.existFlag {
                    label.removeFromSuperview()
                }
            }
        }

        yAxisLimit = limit
    }

    open func handleXAxis() {
        let xAxisLength = canvasView.frame.width
        let xLabelWidth = xAxisLength / CGFloat(xLabels.count)

        for sv in self.subviews {
            if let label = sv as? XAxisLabel {
                label.existFlag = false
            }
        }

        var subviews = self.subviews

        for (index, text) in xLabels.enumerated() {
            var xLabel: XAxisLabel? = nil

            for (i, sv) in subviews.enumerated() {
                if let label = sv as? XAxisLabel {
                    if (label.text == text) {
                        xLabel = label
                        subviews.remove(at: i) // remove item for next loop fast
                        break
                    }
                }
            }

            let frame = CGRect.init(x: canvasView.frame.minX + CGFloat(index) * xLabelWidth, y: canvasView.frame.maxY, width: xLabelWidth, height: 18)
            if xLabel != nil {
                xLabel!.existFlag = true
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    xLabel!.frame = frame
                }, completion: nil)

            } else {
                xLabel = XAxisLabel.init()
                xLabel!.existFlag = true
                xLabel!.text = text
                xLabel!.frame = frame
                self.addSubview(xLabel!)
            }
        }

        for sv in self.subviews {
            if let label = sv as? XAxisLabel {
                if !label.existFlag {
                    label.removeFromSuperview()
                }
            }
        }
    }

    override func drawChart() {
        super.drawChart()

        if xAxisLine.superlayer == nil {
            self.layer.addSublayer(xAxisLine)
        }
        if yAxisLine.superlayer == nil {
            self.layer.addSublayer(yAxisLine)
        }
        if canvasView.superview == nil {
            self.addSubview(canvasView)
        }
        if indicatorCV.superview == nil {
            self.addSubview(indicatorCV)
        }

        indicatorCV.reloadData()

        canvasView.frame = .init(x: 40, y: 20, width: self.bounds.maxX - 40 - 20, height: self.bounds.maxY - 40 - 20)
        zeroPoint.x = canvasView.frame.minX
        zeroPoint.y = canvasView.frame.maxY
        indicatorCV.frame = .init(x: zeroPoint.x, y: canvasView.frame.maxY + 12 + 6, width: canvasView.frame.width, height: self.bounds.maxY - canvasView.frame.maxY - 12 - 6)

        let path = UIBezierPath.init()
        path.move(to: .init(x: zeroPoint.x - 5, y: zeroPoint.y))
        path.addLine(to: CGPoint.init(x: canvasView.frame.maxX, y: zeroPoint.y))
        xAxisLine.path = path.cgPath

        path.removeAllPoints()

        path.move(to: .init(x: zeroPoint.x, y: zeroPoint.y + 5))
        path.addLine(to: CGPoint.init(x: zeroPoint.x, y: canvasView.frame.minY))
        yAxisLine.path = path.cgPath

        handleYAxis()
        handleXAxis()
    }

    public func setData(list: [JoAxisData]) {
        setOptions(list: list, xAxis: xLabels)
    }

    public func setOptions(list: [JoAxisData], xAxis: [String]) {
        listData.removeAll()
        listData += list
        var index = 0
        for i in 0..<listData.count {
            if listData[i].color == nil {
                listData[i].color = colors[index % colors.count]
                index += 1
            }
        }

        xLabels = xAxis
    }
}


extension AxisChartBase: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JoIndicatorCell.ReuseIdentifier, for: indexPath) as! JoIndicatorCell

        cell.setData(data: listData[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        listData.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: 60, height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        listData[indexPath.item].active = !listData[indexPath.item].active
        collectionView.reloadItems(at: [indexPath])

        self.drawChart()
    }
}

private class JoIndicatorCell: UICollectionViewCell {
    static let ReuseIdentifier = "JoIndicatorCellReuseIdentifier"

    private lazy var titleLabel: UILabel = {
        let la = UILabel.init()
        la.font = .systemFont(ofSize: 9)
        la.textColor = .black
        return la
    }()

    private lazy var shape: CAShapeLayer = {
        let layer = CAShapeLayer.init()
        layer.lineWidth = 1
        layer.fillColor = nil
        return layer
    }()

    private lazy var circle: CAShapeLayer = {
        let layer = CAShapeLayer.init()
        layer.lineWidth = 1
        layer.fillColor = UIColor.white.cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(titleLabel)
        titleLabel.frame = .init(x: 18, y: 0, width: frame.width - 18, height: frame.height)

        self.contentView.layer.addSublayer(shape)
        shape.addSublayer(circle)
        let path = UIBezierPath.init()
        path.move(to: .init(x: 0, y: self.bounds.midY))
        path.addLine(to: .init(x: 16, y: self.bounds.midY))
        shape.path = path.cgPath

        path.removeAllPoints()
        path.addArc(withCenter: .init(x: 8, y: self.bounds.midY), radius: 3, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        circle.path = path.cgPath

        print("cell \(frame)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(data: JoAxisData) {
        if data.active {
            shape.strokeColor = data.color!.cgColor
            circle.strokeColor = data.color!.cgColor
            titleLabel.textColor = .black
        } else {
            shape.strokeColor = UIColor.lightGray.cgColor
            circle.strokeColor = UIColor.lightGray.cgColor
            titleLabel.textColor = .lightGray
        }

        titleLabel.text = data.name
    }
}
