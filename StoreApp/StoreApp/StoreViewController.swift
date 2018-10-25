//
//  ViewController.swift
//  StoreApp
//
//  Created by YOUTH2 on 2018. 6. 26..
//  Copyright © 2018년 JINiOS. All rights reserved.
//

import UIKit
import Toaster
import Alamofire

class StoreViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let rowHeightForCell: CGFloat = 100
    let rowHeightForHeader: CGFloat = 60

    var storeItems = StoreItems()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(setComplete(notification:)),name: .sectionSetComplete,object: nil)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = rowHeightForCell
        self.storeItems.set()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func resetTableView(indexPaths: [IndexPath]) {
        DispatchQueue.main.sync { [weak self] in
            self?.tableView.beginUpdates()
            let headerNumber = indexPaths[0][0]
            let numberOfRows = self!.tableView.numberOfRows(inSection: headerNumber)
            if numberOfRows > 0 {
                self?.tableView.deleteRows(at: indexPaths, with: .fade)
                print(self!.tableView.numberOfRows(inSection: headerNumber))
            }
            self?.tableView.insertRows(at: indexPaths, with: .fade)
            self?.tableView.endUpdates()
        }
    }

    @objc func setComplete(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let section = userInfo[Keyword.sectionPath] else { return }
        guard let sectionNumber = section as? [IndexPath] else { return }
        self.resetTableView(indexPaths: sectionNumber)
    }

    private func toUnreachableView() {
        if let unreachableVC = self.storyboard?.instantiateViewController(withIdentifier: "unreachableViewController") as? UnreachableViewController {
            self.navigationController?.pushViewController(unreachableVC, animated: true)
        }
    }

    private func runToast(indexPath: IndexPath) {
        Toast(text: "\(storeItems[indexPath.section][indexPath.row].alt)\n\(storeItems[indexPath.section][indexPath.row].s_price)",
            duration: Delay.short).show()
    }
}

extension StoreViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemCell = tableView.dequeueReusableCell(withIdentifier: Keyword.itemCell.rawValue, for: indexPath) as! StoreTableViewCell
        itemCell.itemData = storeItems[indexPath.section][indexPath.row]
        return itemCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.storeItems[section].count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.storeItems.countOfHeaders()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "itemDetailView") as? ItemViewController {
            if let selectedCell = tableView.cellForRow(at: indexPath) as? StoreTableViewCell {
                if selectedCell.isHashDataEnable {
                    self.runToast(indexPath: indexPath)
                    nextVC.itemData = selectedCell.detailHash
                    self.navigationController?.pushViewController(nextVC, animated: true)
                } else {
                    self.toUnreachableView()
                }
            }
        }
    }

}

extension StoreViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableCell(withIdentifier: Keyword.customHeader.rawValue) as? HeaderView else { return nil }
        headerView.data = StoreItems.categories[section]
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return rowHeightForHeader
    }

}

