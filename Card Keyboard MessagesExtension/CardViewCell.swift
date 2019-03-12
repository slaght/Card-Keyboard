//
//  CardViewCell.swift
//  Card Keyboard MessagesExtension
//
//  Created by Brandon Slaght on 3/28/18.
//  Copyright © 2018 Brandon Slaght. All rights reserved.
//

import Foundation
import UIKit
import MTGSDKSwift

class CardViewCell: UICollectionViewCell {
    
    var card = Card()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    func setupBorder() {
        imageView.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        imageView.layer.cornerRadius = 5.0
        imageView.layer.borderWidth = 1
    }

    func set(card: Card) {
        self.card = card
        imageView.image = nil
        imageView.setNeedsLayout()
        errorLabel.isHidden = true
        spinner.isHidden = false

        DispatchQueue.main.async {
            self.spinner.startAnimating()
        }
        
        guard let urlString = card.imageUrl else {
            handleNoImage(error: card.name!)
            return
        }
        guard let url = URL(string: urlString) else {
            handleNoImage(error: urlString)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let recievedError = error {
                self.errorLabel.text = recievedError.localizedDescription
                self.errorLabel.isHidden = false
                self.spinner.isHidden = true
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.errorLabel.text = "Not a proper HTTPURLResponse or statusCode"
                self.errorLabel.isHidden = false
                self.spinner.isHidden = true
                return
            }
            DispatchQueue.main.async {
                UIView.transition(with: self.imageView,
                                  duration:0.5,
                                  options: .transitionCrossDissolve,
                                  animations: { self.imageView.image = UIImage(data: data!) },
                                  completion: nil)
            }
        }.resume()
    }
    
    func handleNoImage(error message: String) {
        print(message)
    }
}
