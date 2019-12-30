//
//  JoLine.swift
//  JoChart
//
//  Created by jojo on 2019/12/30.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

class JoLine: CAShapeLayer {
    private var points: [CGPoint] = []
    private var circlePoints: [JoPoint] = []
    
    init(points: [CGPoint]) {
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
    
    func appear() {
        let anima = CABasicAnimation.init(keyPath: "strokeEnd")
        anima.fromValue = 0
        anima.toValue = 1
        anima.duration = 0.5
        anima.timingFunction = .init(name: .easeInEaseOut)
        anima.isRemovedOnCompletion = true
        self.add(anima, forKey: "drawLine")
    }
}

class JoPoint: CAShapeLayer {
    init(location: CGPoint) {
        super.init()
        
        self.strokeColor = UIColor.black.cgColor
        self.lineWidth = 1
        self.fillColor = UIColor.white.cgColor
        
        let path = UIBezierPath.init(arcCenter: location, radius: 3, startAngle: 0, endAngle:2 * CGFloat.pi, clockwise: true)
        self.path = path.cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
