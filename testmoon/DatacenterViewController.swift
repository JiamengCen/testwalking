//
//  DatacenterViewController.swift
//  testmoon
//
//  Created by Jiameng Cen on 17/5/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseFirestore
import Charts

class DatacenterViewController: UIViewController {
    var db:Firestore!
    var userWalkArray = [userWalk]()
    
    @IBOutlet weak var daydistance: UILabel!
    @IBOutlet weak var goodjob: UILabel!
    @IBOutlet weak var weekdistance: UILabel!
    @IBOutlet weak var weekgoal: UILabel!
    
 
    @IBOutlet weak var pieChart2: PieChartView!
    @IBOutlet weak var pieChart: PieChartView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var tableView: UITableView!
    var steps = [Step]()
    var users = [User]()
    var numberOfDownloadsDataEntries = [PieChartDataEntry]()
    var finishedDataEntry = PieChartDataEntry(value: 0)
    var unfinishedDataEntry = PieChartDataEntry(value: 0)
    var stepArray = [Double]()
    var days: [String]!
    var numberOfDownloadsDataEntries2 = [PieChartDataEntry]()
    var finishedDataEntry2 = PieChartDataEntry(value: 0)
    var unfinishedDataEntry2 = PieChartDataEntry(value: 0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        loadData()
        // Do any additional setup after loading the view.
        //piechart
        pieChart.chartDescription?.text = "Day progress"
        finishedDataEntry.value = 200
        
        finishedDataEntry.label = "finishedStep"
        unfinishedDataEntry.value = 700
        unfinishedDataEntry.label = "unfinishedStep"
        numberOfDownloadsDataEntries = [finishedDataEntry,unfinishedDataEntry]
        updateChartData()
        days = ["MO","Tu","We","Th","Fr","Sa","Su"]
        let steps1 = [110.0,90.0,128.0,130.0,105.0,120.0,110.0,90.0,128.0,130.0,105.0,80.0,110.0]
        self.setChart(dataPoints : self.days, values:steps1)
        
        //piechart2
        pieChart2.chartDescription?.text = "Weak progress"
        finishedDataEntry2.value = 6000
        finishedDataEntry2.label = "finished"
        unfinishedDataEntry2.value = 40000
        unfinishedDataEntry2.label = "unfinished"
        numberOfDownloadsDataEntries2 = [finishedDataEntry2,unfinishedDataEntry2]
        updateChartData2()
        
        
        // realtimeDB
        let uid = Auth.auth().currentUser?.uid
        let ref =  Database.database().reference().child("UploadSteps").child(uid!)
        let step = Step()
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let dictionary = snap.value as? [String : AnyObject]
                let stepcount = dictionary!["Steps"] as? String
                print(stepcount)
            }
        }) { (error)  in
            print(error.localizedDescription)
            
        }
        
        //text
        goodjob.text = "500"
        daydistance.text = "5km"
        weekgoal.text = "4000"
        weekdistance.text = "20km"
    }
    func loadData(){
        db.collection("userWalk").getDocuments(){
            QuerySnapshot, error in
            if let error = error {
                print("\(error.localizedDescription)")
            }else{
                self.userWalkArray = QuerySnapshot!.documents.flatMap({userWalk(dictionary: $0.data())})
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func setChart(dataPoints: [String] , values: [Double]){
        var dataEntries:[BarChartDataEntry] = []
        var counter = 0.0
        
        for i in 0..<dataPoints.count {
            counter += 1.0
            let dataEntry = BarChartDataEntry(x: counter, y:values[i])
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Daily Stamp")
        let chartData = BarChartData()
        chartData.addDataSet(chartDataSet)
        barChartView.data = chartData
        chartDataSet.colors = ChartColorTemplates.colorful()
        barChartView.animate(xAxisDuration:2.0,yAxisDuration:2.0)
    }
    
    func updateChartData(){
        let chartDataSet = PieChartDataSet(values: numberOfDownloadsDataEntries, label:nil)
        let chartData = PieChartData(dataSet: chartDataSet)
        let colors = [UIColor.orange,UIColor.cyan]
        chartDataSet.colors = colors as! [NSUIColor]
        
        pieChart.data = chartData
    }
    
    func updateChartData2(){
        let chartDataSet = PieChartDataSet(values: numberOfDownloadsDataEntries2, label:nil)
        let chartData = PieChartData(dataSet: chartDataSet)
        let colors = [UIColor.orange,UIColor.cyan]
        chartDataSet.colors = colors as! [NSUIColor]
        
        pieChart2.data = chartData
    }
    
    func fetchUser(){
        Database.database().reference().child("users").observe(.childAdded,with:{ (snapshot) in
            if let dictionary = snapshot.value as? [String : AnyObject]{
                let user = User()
                //user.setValuesForKeys(dictionary)
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                self.users.append(user)
                //print (snapshot)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleShow(){
        let ref = Database.database().reference().child("steps")
        let childRef = ref.childByAutoId()
        //is it there best thing to includethe name inside of the step node
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = NSDate()
        let values = ["fromId": fromId,"timestamp":timestamp] as [String : Any]
        childRef.updateChildValues(values){ (error,ref) in
            if error != nil{
                print(error)
                return
            }
            let userStepsRef =
                Database.database().reference().child("user-steps").child(fromId)
            
            let stepId = childRef.key
            userStepsRef.updateChildValues([stepId:1])
            let receipientUserStepRef = Database.database().reference().child("user-steps").child(fromId)
            receipientUserStepRef.updateChildValues([stepId:1])
            
            
        }
    }
    
    func obeserveUserStep(){
        guard let uid = Auth.auth().currentUser?.uid else{
            return
        }
        
        let ref = Database.database().reference().child("users").child(uid)
        ref.observe(.childAdded,with:{ (snapshot) in
            let stepId = snapshot.key
            let stepReference = Database.database().reference().child("steps").child(stepId)
            stepReference.observeSingleEvent(of: .value, with:{
                (snapshot) in
                //print (snapshot)
                
            })
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

