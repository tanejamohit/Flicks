//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Mohit Taneja on 9/12/17.
//  Copyright © 2017 Mohit Taneja. All rights reserved.
//

import UIKit
import AFNetworking
import ACProgressHUD_Swift

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
  
  @IBOutlet weak var moviesTableView: UITableView!
  @IBOutlet weak var networkErrorView: UIView!
  @IBOutlet weak var movieSearchBar: UISearchBar!
  
  var moviesDictionaryArray: [NSDictionary]?
  var filteredMoviesDictionaryArray: [NSDictionary]?
  var endpoint: String!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the search bar
    self.movieSearchBar.delegate = self;
    
    // Set the data source and delegate
    moviesTableView.dataSource = self
    moviesTableView.delegate = self
    
    // Set up the loading indicator
    ACProgressHUD.shared.progressText = "Fetching Movies..."
    ACProgressHUD.shared.showHUD()
    
    // Load Movie Data
    loadMovieData {}
    
    // Add UI refreshing on pull down
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
    moviesTableView.insertSubview(refreshControl, at: 0)
    
    // Hide the network error view
    networkErrorView.isHidden = true;
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    // Hide the navigation controller
    self.navigationController?.setNavigationBarHidden(true, animated: true)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    var moviesFinal:[NSDictionary]?
    moviesFinal = []
    if searchBarIsEmpty() {
      if let movies = moviesDictionaryArray {
        moviesFinal = movies
      }
          }
    else {
      if let movies = filteredMoviesDictionaryArray {
        moviesFinal = movies
      }
    }
    return (moviesFinal?.count)!
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
    
    var movie:NSDictionary
    if searchBarIsEmpty() {
      movie = moviesDictionaryArray![indexPath.row]
    }
    else {
      movie = filteredMoviesDictionaryArray![indexPath.row]
    }

    let title = movie["title"] as! String
    let description = movie["overview"] as! String
    
    if let posterPath = movie["poster_path"] as? String {
      let baseURL = "http://image.tmdb.org/t/p/w500";
      let imageURL = URL(string: baseURL + posterPath)
      cell.movieThumbnailImage.setImageWith(imageURL!)
    }
    
    cell.movieTitleLabel.text = title
    cell.movieDescriptionLabel.text = description
    return cell
  }
  
  
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    let cell = sender as! UITableViewCell
    let indexPath = moviesTableView.indexPath(for: cell)
    let movie = moviesDictionaryArray![indexPath!.row]
    
    let movieDetailViewController = segue.destination as! MovieDetailViewController
    movieDetailViewController.movie = movie;
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  
  
  
  func loadMovieData(onDataLoad:@escaping ()->Void) {
    // Get the data from the movie database
    let urlString = "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"
    let url = URL(string:urlString)
    var request = URLRequest(url: url!)
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    let session = URLSession(
      configuration: URLSessionConfiguration.default,
      delegate:nil,
      delegateQueue:OperationQueue.main
    )
    
    let task : URLSessionDataTask = session.dataTask(with: request, completionHandler:
    { (dataOrNil, response, error) in
      if let data = dataOrNil {
        
        let dictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        self.moviesDictionaryArray = dictionary["results"] as? [NSDictionary]
        print(dictionary)
        self.moviesTableView.reloadData()
        ACProgressHUD.shared.hideHUD()

        // Hide the network error view
        self.networkErrorView.isHidden = true;

        onDataLoad();
     }
      else if (error != nil) {
        // Show the network error view
        self.networkErrorView.isHidden = false;
        onDataLoad();
      }
    });
    task.resume()
  }
  
  // Function called when user tries to refresh
  func refreshControlAction(_ refreshControl: UIRefreshControl) {
    loadMovieData {
      refreshControl.endRefreshing();
    }
  }
  
  func searchBarIsEmpty() -> Bool {
    // Returns true if the text is empty or nil
    return self.movieSearchBar.text?.isEmpty ?? true
  }
  
  func isFiltering() -> Bool {
    return self.movieSearchBar.isFocused && !searchBarIsEmpty()
  }

  func filterContentForSearchText(_ searchText: String) {
    filteredMoviesDictionaryArray = moviesDictionaryArray?.filter({( movie : NSDictionary) -> Bool in
      
      let title = movie["title"] as! String
      let description = movie["overview"] as! String
      
      return (title.lowercased().range(of:searchText.lowercased()) != nil) || (description.lowercased().range(of:searchText.lowercased()) != nil)
    })
    moviesTableView.reloadData()
  }


  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    filterContentForSearchText(searchBar.text!)
  }
}
