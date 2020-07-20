//
//  JoAxisChartBase.swift
//  JoChart
//
//  Created by jojo on 2020/1/10.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit


public struct JoLineValue {
    var value: CGFloat
    var point = CGPoint.zero
}

public struct JoAxisData {
    public var key = UUID.init().uuidString
    public var name: String
    var nameWidth: CGFloat = 0
    public var values: [JoLineValue]
    public var color: UIColor?
    public var active = true

    public init(name: String, values: [CGFloat]) {
        self.init(name: name, values: values, color: nil)
    }
    
    public init(name: String, values: [CGFloat], color: UIColor?) {
        self.name = name
        var array: [JoLineValue] = []
        for v in values {
            array.append(.init(value: v))
        }
        self.values = array
        self.color = color
    }
}

class YAxisLabel: UIView {

    public var existFlag = false

    private lazy var titleLabel: UILabel = {
        let label = UILabel.init()
        label.tag = 99945
        label.font = .systemFont(ofSize: 9)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    private lazy var leftLine: UIView = {
        let li = UIView.init()
        li.tag = 99845
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

class XAxisLabel: UILabel {

    public var existFlag = false

    private lazy var line: UIView = {
        let l = UIView.init()
        l.tag = 99844
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

public class JoAxisChartBase: JoChartBase {

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
//        v.isUserInteractionEnabled = true
//        v.backgroundColor = .init(white: 1, alpha: 0.4)
        return v
    }()
    
    public override func enableTouch(_ enable: Bool) {
        mEnableTouch = enable
        if enable {
            if self.pan.view == nil {
                canvasView.addGestureRecognizer(self.pan)
            }
        } else {
            if self.pan.view == self {
                canvasView.removeGestureRecognizer(self.pan)
            }
        }
    }
   
    lazy var indicatorCV: UICollectionView = {
        [unowned self] in
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
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

    var yAxisLimit: CGFloat = 0

    public var showLegend = true {
        didSet {
            indicatorCV.isHidden = !showLegend
        }
    }

    public var axisLineColor: UIColor? {
        didSet {
            if axisLineColor != nil {
                xAxisLine.strokeColor = axisLineColor!.cgColor
                yAxisLine.strokeColor = axisLineColor!.cgColor
            } else {
                xAxisLine.strokeColor = UIColor.black.cgColor
                yAxisLine.strokeColor = UIColor.black.cgColor
            }
        }
    }

    public var yAxisLabelColor: UIColor?

    public var xAxisLabelColor: UIColor?

    public override init() {
        super.init()

        self.enableTouch(true)
        self.toastView.offset = .init(x: 40, y: 20)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func drawChart() {
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
}

extension JoAxisChartBase: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JoIndicatorCell.ReuseIdentifier, for: indexPath) as! JoIndicatorCell

        cell.setData(data: listData[indexPath.item])
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        listData.count
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = listData[indexPath.item]
        return .init(width: data.nameWidth <= 0 ? 60 : data.nameWidth, height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        listData[indexPath.item].active = !listData[indexPath.item].active
        collectionView.reloadItems(at: [indexPath])

        self.drawChart()
    }
}


extension JoAxisChartBase {
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

            yLabel!.viewWithTag(99845)?.backgroundColor = axisLineColor ?? UIColor.black
            (yLabel!.viewWithTag(99945) as? UILabel)?.textColor = yAxisLabelColor ?? UIColor.black
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

            xLabel!.viewWithTag(99844)?.backgroundColor = axisLineColor ?? UIColor.black
            xLabel!.textColor = xAxisLabelColor ?? UIColor.black
        }

        for sv in self.subviews {
            if let label = sv as? XAxisLabel {
                if !label.existFlag {
                    label.removeFromSuperview()
                }
            }
        }
    }
}

extension JoAxisChartBase {
    public func setOptions(data: [JoAxisData]) {
        setOptions(data: data, xAxis: xLabels)
    }

    public func setOptions(data: [JoAxisData], xAxis: [String]) {
        listData.removeAll()
        listData += data
        var colorIndex = 0
        let cellTitleFont = UIFont.systemFont(ofSize: JoIndicatorCell.TitleFontSize)
        for i in 0..<listData.count {
            if listData[i].color == nil {
                listData[i].color = JoChartBase.colors[colorIndex % JoChartBase.colors.count]
                colorIndex += 1
            }
            listData[i].nameWidth = listData[i].name.width(withConstrainedHeight: 18, font: cellTitleFont) + JoIndicatorCell.TitleOffset
        }

        xLabels = xAxis
    }
}

private class JoIndicatorCell: UICollectionViewCell {
    static let ReuseIdentifier = "JoIndicatorCellReuseIdentifier"
    static let TitleFontSize: CGFloat = 9
    static let TitleOffset: CGFloat = 18

    private lazy var titleLabel: UILabel = {
        let la = UILabel.init()
        la.font = .systemFont(ofSize: JoIndicatorCell.TitleFontSize)
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
        let offset = JoIndicatorCell.TitleOffset
        let iconWidth = offset - 2
        titleLabel.frame = .init(x: offset, y: 0, width: frame.width - offset, height: frame.height)

        self.contentView.layer.addSublayer(shape)
        shape.addSublayer(circle)
        let path = UIBezierPath.init()
        path.move(to: .init(x: 0, y: self.bounds.midY))
        path.addLine(to: .init(x: iconWidth, y: self.bounds.midY))
        shape.path = path.cgPath

        path.removeAllPoints()
        path.addArc(withCenter: .init(x: iconWidth / 2, y: self.bounds.midY), radius: 3, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
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
