//
//  TableViewController.swift
//  JoChart
//
//  Created by jojo on 2020/2/3.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

struct TableModel {
    var name: String
    var controllerType: UIViewController.Type
}

class TableViewController: UITableViewController {

    
    private let listVC: [TableModel] = [TableModel(name: "Line Chart", controllerType: LineViewController.self),
                                        TableModel(name: "Pie Chart", controllerType: PieViewController.self),
                                        TableModel(name: "Heat Chart", controllerType: HeatViewController.self),]
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return listVC.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SimpleCellReuseIdentifier", for: indexPath)

        cell.textLabel?.text = "\(listVC[indexPath.row].name)"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = listVC[indexPath.row]
        let vc = data.controllerType.init()
        vc.title = data.name
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
