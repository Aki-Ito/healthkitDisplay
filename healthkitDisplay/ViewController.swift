//
//  ViewController.swift
//  healthkitDisplay
//
//  Created by 伊藤明孝 on 2021/11/05.
//
import UIKit
import HealthKit

class ViewController: UIViewController{
    
    
    @IBOutlet var tableView: UITableView!
    
    var healthStore: HKHealthStore = HKHealthStore()
    
    var dataValues: [Double] = []
    var query : HKStatisticsCollectionQuery?
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        self.healthStore.requestAuthorization(toShare: [stepType], read: [stepType]){(success, error) in
            if success{
                self.calculateDailyStepCountForPastWeek()
            }
        }
        
        
        
        
    }
    
    func calculateDailyStepCountForPastWeek(){
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let daily = DateComponents(day: 1)
        
        let exactlySevenDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -7), to: Date())
        let startOfDate = Calendar.current.startOfDay(for: exactlySevenDaysAgo!)
        let oneWeekAgo = HKQuery.predicateForSamples(withStart: exactlySevenDaysAgo, end: nil, options: .strictStartDate)
        
        self.query = HKStatisticsCollectionQuery(quantityType: stepType,
                                                 quantitySamplePredicate: oneWeekAgo,
                                                 options: .cumulativeSum,
                                                 anchorDate: startOfDate,
                                                 intervalComponents: daily)
        
        self.query?.initialResultsHandler = { query, statisticsCollection, error in
            if let statisticsCollection = statisticsCollection{
                self.updateUIFromStatistics(statisticsCollection)
            }
        }
        
        
        self.healthStore.execute(query!)
    }
    
    func updateUIFromStatistics(_ statisticsCollection: HKStatisticsCollection){
        DispatchQueue.main.async {
            self.dataValues = []
            
            let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
            let endDate = Date()
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate){ statisics, stop in
                
                if let quantity = statisics.sumQuantity(){
                    let totalStepsCount = quantity.doubleValue(for: HKUnit.count())
                    self.dataValues.append(totalStepsCount)
                }
            }
            
            self.tableView.reloadData()
        }
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = String(dataValues[indexPath.row])+"歩"
        return cell
    }
}







