//
//  HeatViewController.swift
//  JoChart
//
//  Created by jojo on 2020/2/4.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class HeatViewController: BaseViewController {

    private let Radius: CGFloat = 10
    
    private lazy var heatChart: JoHeatChart = {
        let v = JoHeatChart(render: .GPU)
        v.backgroundColor = .hex(value: 0x03a9f4)
        return v
    }()
    
    private lazy var heat2Chart: JoHeatChart = {
        let v = JoHeatChart(render: .CPU)
        v.backgroundColor = .hex(value: 0x03a9f4)
        return v
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let btn = UIButton.init(frame: .init(x: 0, y: 100, width: 60, height: 40))
        btn.setTitle("draw", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(drawChart), for: .touchUpInside)
        self.view.addSubview(btn)

        let lab1 = UILabel()
        lab1.textColor = .black
        lab1.font = .systemFont(ofSize: 14)
        lab1.text = "GPU render"
        lab1.frame = CGRect(x: 0, y: 140, width: 100, height: 18)
        view.addSubview(lab1)
      
        heatChart.frame = CGRect.init(x: 0, y: 160, width: CGFloat.screenWidth, height: 300)
        view.addSubview(heatChart)
        
        
        let lab2 = UILabel()
        lab2.textColor = .black
        lab2.font = .systemFont(ofSize: 14)
        lab2.text = "CPU render"
        lab2.frame = CGRect(x: 0, y: 470, width: 100, height: 18)
        view.addSubview(lab2)
        
        heat2Chart.frame = CGRect.init(x: 0, y: 490, width: CGFloat.screenWidth, height: 300)
        view.addSubview(heat2Chart)
                
    }
}

extension HeatViewController {
    @objc private func drawChart() {
        var list = [JoHeatValue]()
        
        let width = Int(CGFloat.screenWidth)
        let height = Int(CGFloat.screenHeight)
        
        /// 自定义半径，太大太小影响最终效果。
        let radius: CGFloat = 8
        
        for _ in 0..<5000 {
            list.append(JoHeatValue(value: CGFloat.random(in: 40...100), location: .init(x: Int.random(in: 0...width), y: Int.random(in: 0...height)), radius: radius))
        }
        
        heatChart.setOptions(data: list)
        heatChart.drawChart()
        
        heat2Chart.setOptions(data: list)
        heat2Chart.drawChart()
    }
    
    
}

