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

    private lazy var pieChart: JoPieChart = {
        let chart = JoPieChart.init()
        return chart
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

//        lineChart.frame = CGRect.init(x: 0, y: 100, width: 414, height: 400)
//        self.view.addSubview(lineChart)

        pieChart.frame = CGRect.init(x: 0, y: 100, width: 414, height: 400)
        self.view.addSubview(pieChart)


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

    private var list: [JoPieValue] = []

    @objc func drawChart() {

//        let data = JoAxisData.init(name: "邮件营销邮件营销", values: [120, 132.56, 101, 134, 90, 230.3333333, 230.3333333])
//
//        lineChart.setOptions(data: [data], xAxis: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
//        lineChart.drawChart()

        list.removeAll()
        list.append(JoPieValue(name: "邮件", value: 321))
        list.append(JoPieValue(name: "发帖", value: 291))
        list.append(JoPieValue(name: "post commend", value: 421))
        list.append(JoPieValue(name: "chat each otehr", value: 121))

        pieChart.setOptions(list)
        pieChart.pieWidth = 60
        pieChart.drawChart()
    }

    @objc func changeData() {
//        let data = JoAxisData.init(name: "邮件营销邮件营销", values: [120, 132.56, 101, 134, 90, 230.3333333, 230.3333333])
//        var data2 = JoAxisData.init(name: "呵呵哒", values: [140, 12.56, 400, 320, 345, 10, 300])
//        data2.color = UIColor.green
//
//        lineChart.setOptions(data: [data, data2])
//        lineChart.drawChart()

        list[2].value = CGFloat.random(in: 100...1600)
        list[0].value = CGFloat.random(in: 100...1600)
        pieChart.setOptions(list)
        pieChart.drawChart()
    }


    @objc func reset() {
//        lineChart.removeFromSuperview()
//        lineChart = JoLineChart.init()
//
//        lineChart.frame = CGRect.init(x: 0, y: 100, width: 414, height: 400)
//        self.view.addSubview(lineChart)
    }

}

