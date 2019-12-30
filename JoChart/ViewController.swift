//
//  ViewController.swift
//  JoChart
//
//  Created by jojo on 2019/12/29.
//  Copyright © 2019 joshin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var lineChart: JoLineChart = {
        let chart = JoLineChart.init()
        chart.backgroundColor = .lightGray
        return chart
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        lineChart.frame = CGRect.init(x: 0, y: 100, width: 414, height: 400)
        self.view.addSubview(lineChart)

        let btn = UIButton.init(frame: .init(x: 0, y: 40, width: 60, height: 40))
        btn.setTitle("draw", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(drawChart), for: .touchUpInside)
        self.view.addSubview(btn)
    }

    @objc func drawChart() {
        lineChart.draw()
    }
    
}

