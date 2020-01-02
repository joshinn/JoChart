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

        let btn2 = UIButton.init(frame: .init(x: 100, y: 40, width: 60, height: 40))
        btn2.setTitle("change", for: .normal)
        btn2.setTitleColor(.black, for: .normal)
        btn2.addTarget(self, action: #selector(changeData), for: .touchUpInside)
        self.view.addSubview(btn2)

        let btn3 = UIButton.init(frame: .init(x: 200, y: 40, width: 60, height: 40))
        btn3.setTitle("reset", for: .normal)
        btn3.setTitleColor(.black, for: .normal)
        btn3.addTarget(self, action: #selector(reset), for: .touchUpInside)
        self.view.addSubview(btn3)
    
        
        
    }

    @objc func drawChart() {
        lineChart.draw()
    }

    @objc func changeData() {
        lineChart.change()
    }

    @objc func reset() {
        lineChart.removeFromSuperview()
        lineChart = JoLineChart.init()

        lineChart.frame = CGRect.init(x: 0, y: 100, width: 414, height: 400)
        self.view.addSubview(lineChart)
    }

}

