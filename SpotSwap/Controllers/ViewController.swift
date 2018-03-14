//
//  ViewController.swift
//  SpotSwap
//
//  Created by Yaseen Al Dallash on 3/14/18.
//  Copyright © 2018 Yaseen Al Dallash. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var allCarMakes = [CarMake](){
        didSet{
            print(allCarMakes[0].makeName)
        }
    }
    func loadAllCarMakes() {
        CarMakeAPIClient.manager.getAllCarMakes(completion: {self.allCarMakes = $0}, errorHandler: {print($0)})
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
        loadAllCarMakes()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

