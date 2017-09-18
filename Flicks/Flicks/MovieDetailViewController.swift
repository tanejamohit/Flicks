//
//  MovieDetailViewController.swift
//  Flicks
//
//  Created by Mohit Taneja on 9/13/17.
//  Copyright © 2017 Mohit Taneja. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
  
  @IBOutlet weak var backgroundImageView: UIImageView!
  @IBOutlet weak var movieTitleLabel: UILabel!
  @IBOutlet weak var movieDescriptionLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var infoView: UIView!
  var movie: NSDictionary!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.height)
    
    movieTitleLabel.text = movie["title"] as?  String
    movieDescriptionLabel.text = movie["overview"] as?  String
    movieDescriptionLabel.sizeToFit()
    
    if let posterPath = movie["poster_path"] as? String {
      let baseURLLowRes = "http://image.tmdb.org/t/p/w92"
      let imageURLLowRes = URL(string: baseURLLowRes + posterPath)

      let baseURLHighRes = "http://image.tmdb.org/t/p/original"
      let imageURLHighRes = URL(string: baseURLHighRes + posterPath)
      
      backgroundImageView.setImageWithAnimation(imageURLLowRes!)
      backgroundImageView.setImageWith(imageURLHighRes!)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    // Show the navigation controller
    self.navigationController?.setNavigationBarHidden(false, animated: true)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
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
