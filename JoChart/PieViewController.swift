//
//  PieViewController.swift
//  JoChart
//
//  Created by jojo on 2020/2/3.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class PieViewController: BaseViewController {
    
    
    private lazy var pieChart: JoPieChart = {
        let chart = JoPieChart.init()
        return chart
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        pieChart.frame = CGRect.init(x: 0, y: 200, width: CGFloat.screenWidth, height: 400)
        self.view.addSubview(pieChart)
        
        
        let btn = UIButton.init(frame: .init(x: 0, y: 100, width: 60, height: 40))
        btn.setTitle("draw", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(drawChart), for: .touchUpInside)
        self.view.addSubview(btn)
        
        let btn2 = UIButton.init(frame: .init(x: 100, y: 100, width: 60, height: 40))
        btn2.setTitle("active", for: .normal)
        btn2.setTitleColor(.black, for: .normal)
        btn2.addTarget(self, action: #selector(activeData), for: .touchUpInside)
        self.view.addSubview(btn2)
        
        let btn3 = UIButton.init(frame: .init(x: 200, y: 100, width: 60, height: 40))
        btn3.setTitle("change", for: .normal)
        btn3.setTitleColor(.black, for: .normal)
        btn3.addTarget(self, action: #selector(changeData), for: .touchUpInside)
        self.view.addSubview(btn3)
    }
    
    private var list: [JoPieValue] = []
    
    @objc func drawChart() {
        
        list.removeAll()
        list.append(JoPieValue(name: "邮件", value: 321, color: JoChartBase.colors[0]))
        list.append(JoPieValue(name: "发帖", value: 291, color: JoChartBase.colors[1]))
        list.append(JoPieValue(name: "post commend", value: 421, color: JoChartBase.colors[2]))
        list.append(JoPieValue(name: "chat each otehr", value: 121, color: JoChartBase.colors[3]))
        
        pieChart.setOptions(list)
        pieChart.pieWidth = 60
        pieChart.drawChart()
    }
    
    @objc func activeData() {
        
        list[1].active = !list[1].active
        pieChart.setOptions(list)
        pieChart.drawChart()
    }
    
    
    @objc func changeData() {
        list[0].value = CGFloat.random(in: 100...1600)
        list[2].value = CGFloat.random(in: 100...1600)
        pieChart.setOptions(list)
        pieChart.drawChart()
    }
    
}
