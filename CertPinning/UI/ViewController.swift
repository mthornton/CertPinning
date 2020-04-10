//
//  ViewController.swift
//  CertPinning
//
//  Created by Michael Thornton on 4/10/20.
//  Copyright © 2020 Michael Thornton. All rights reserved.
//

import UIKit




class ViewController: UIViewController {

    @IBOutlet weak var textViewResults : UITextView!

    
    private let pinnedURL = URL(string: "https://ghibliapi.herokuapp.com/films")!
    
    let network = SafeNetwork()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //cert sig for heroku
        MobileCoreConfig.shared.addPinnedHash("Vuy2zjFSPqF5Hz18k88DpUViKGbABaF3vZx5Raghplc=")
    }
    
    
    
    @IBAction func buttonFetch(_ sender: Any) {
        
        self.textViewResults.text = ""
        
        //exampleFetchData()
        
        exampleFetchWithCodableObject()
    }
    

    
    func exampleFetchData() {
        
        let urlRequest = URLRequest(url: pinnedURL)

        network.fetchWithURLRequest(urlRequest) { (data, additionalInformation, error) in

            if error != nil || data == nil {
                DispatchQueue.main.async {
                    self.textViewResults.text = "ERROR :: \(error?.localizedDescription ?? "no error message")"
                }
                return
            }


            if let data = data {
                DispatchQueue.main.async {
                    self.textViewResults.text = (String(data: data, encoding: .utf8))
                }
            }
        }
    }
    
    
    
    func exampleFetchWithCodableObject() {
        
        let urlRequest = URLRequest(url: pinnedURL)

        network.loadCodableObject([Movie].self, withURLRequest: urlRequest) { (object, data, urlResponse, error) in
          
            if let movies = object as? [Movie] {
                var s = ""
                
                for movie in movies {
                    s = "\(s) \n \(movie.title)"
                }
                
                DispatchQueue.main.async {
                    self.textViewResults.text = s
                }
            }
        }
    }
    
} // end class





class Movie: Codable {
    
    let id: String
    let title: String
    let description: String
    let releaseDate: String
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case releaseDate = "release_date"
    }
    
} // end class
