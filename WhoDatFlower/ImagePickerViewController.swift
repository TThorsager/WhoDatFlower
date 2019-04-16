//
//  ViewController.swift
//  WhoDatFlower
//
//  Created by Thomas Thorsager on 08/03/2019.
//  Copyright © 2019 TThorsager. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ImagePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var flowerInfoLabel: UILabel!
    
    @IBOutlet weak var userPickedImageView: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
         
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Can not convert to CIImage")
            }
            
            detect(image: convertedCIImage)
            
            //If you want the image taken by the user to be displayed
            //userPickedImageView.image = userPickedImage
            
            
            
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Can not import model from mlmodel")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image")
            }
            
            //print(request.results as Any)
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
        
    }
    
    
    func requestInfo(flowerName: String) {
       
        //These parameters is used to determine which data we get from the chosen wikipedia article
        let wikiParameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: wikiParameters).responseJSON {
            (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info")
                print(response)
                
                let flowerInfoJSON : JSON = JSON(response.result.value!)
                
                let pageId = flowerInfoJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerInfoJSON["query"]["pages"][pageId]["extract"].stringValue
                
                let flowerImageUrl = flowerInfoJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                self.userPickedImageView.sd_setImage(with: URL(string: flowerImageUrl))
                
                self.flowerInfoLabel.text = flowerDescription
                
                
            }
        }
        
    }
    
    
    @IBAction func pickImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

