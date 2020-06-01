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
        let v = JoHeatChart()
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

      
        heatChart.frame = CGRect.init(x: 0, y: 200, width: CGFloat.screenWidth, height: 300)
        view.addSubview(heatChart)
                
    }
}

extension HeatViewController {
    @objc private func drawChart() {
        var list = [JoHeatValue]()
        for _ in 0...Int.random(in: 500...1000) {
            list.append(JoHeatValue(location: .init(x: 40 + Int.random(in: 0...230), y: 60 + Int.random(in: 0...200)), value: CGFloat.random(in: 40...100)))
        }
        
        heatChart.setOptions(data: list)
        heatChart.drawChart()
    }
    
    
}

