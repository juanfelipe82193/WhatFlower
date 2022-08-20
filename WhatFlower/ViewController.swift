//
//  ViewController.swift
//  WhatFlower
//
//  Created by Juan Felipe Zorrilla Ocampo on 15/08/22.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //MARK: - IBActions methods

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        openCamera()
    }
    
    @IBAction func libraryTapped(_ sender: UIBarButtonItem) {
        openLibrary()
    }
    
    //MARK: - Own ViewController methods
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Warning", message: "Camera not found", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func openLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Warning", message: "You don't have permission to access gallery", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func detect(flowerImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            
//            print(results)
            
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters: [String:String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("Got the wikipedia info.")
                print(response)
                
                let flowerJSON: JSON = JSON(response.result.value!)
                
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                
                self.label.text = flowerDescription
                
            }
        }
    }
    
}

//MARK: - UIImagePicker and Navigation Controller methods

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let userPickerImage = info[.editedImage] as? UIImage,
              let ciimage = CIImage(image: userPickerImage) else {
            fatalError("Could not convert picked image to UIImage or CIImage")
        }
        
        imageView.image = userPickerImage
         detect(flowerImage: ciimage)
        
        dismiss(animated: true)
    }
    
}

