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

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
  
  @IBOutlet weak var moviesTableView: UITableView!
  @IBOutlet weak var networkErrorView: UIView!
  @IBOutlet weak var movieSearchBar: UISearchBar!
  @IBOutlet weak var moviesCollectionView: UICollectionView!
  @IBOutlet weak var navigationView: UINavigationItem!
  
  var moviesDictionaryArray: [NSDictionary]?
  var filteredMoviesDictionaryArray: [NSDictionary]?
  var endpoint: String!
  static let NUM_MOVIES_PER_ROW = 2;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the search bar
    self.movieSearchBar.delegate = self;
    
    // Set the data source and delegate
    moviesTableView.dataSource = self
    moviesTableView.delegate = self
    moviesCollectionView.dataSource = self
    moviesCollectionView.delegate = self
    
    // Set up the loading indicator
    ACProgressHUD.shared.progressText = "Fetching Movies..."
    ACProgressHUD.shared.showHUD()
    
    // Load Movie Data
    loadMovieData {}
    
    // Add UI refreshing on pull down
    let refreshControlForTable = UIRefreshControl()
    refreshControlForTable.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
    moviesTableView.insertSubview(refreshControlForTable, at: 0)
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
    moviesCollectionView.insertSubview(refreshControl, at: 0)
    
    // Hide the network error view
    networkErrorView.isHidden = true;
    
    // Switch between table and collection
    moviesCollectionView.isHidden = true;
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "collection_view"), style: .plain, target: self, action: #selector(switchBetweenTableAndCollection))
    navigationItem.leftBarButtonItem?.tintColor = UIColor.white
    self.navigationController?.navigationBar.tintColor = UIColor.white
    
    if endpoint == "now_playing" {
      navigationView.title = "Now Playing"
    }
    else if endpoint == "top_rated" {
      navigationView.title = "Top Rated"
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    // Hide the navigation controller
    // self.navigationController?.setNavigationBarHidden(true, animated: true)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func switchBetweenTableAndCollection() {
    if moviesCollectionView.isHidden {
      moviesCollectionView.isHidden = false
      moviesTableView.isHidden = true
      navigationItem.leftBarButtonItem?.image = UIImage(named: "list_view")
    }
    else {
      moviesCollectionView.isHidden = true
      moviesTableView.isHidden = false
      navigationItem.leftBarButtonItem?.image = UIImage(named: "collection_view")
    }
  }
  
  // MARK: - TableView Delegates

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
      let baseURL = "http://image.tmdb.org/t/p/w92";
      let imageURL = URL(string: baseURL + posterPath)
      cell.movieThumbnailImage.setImageWithAnimation(imageURL!)
    }
    
    cell.movieTitleLabel.text = title
    cell.movieDescriptionLabel.text = description
    return cell
  }
  
  // MARK: - CollectionView Delegates
  
  func totalNumberOfMovies() -> Int {
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
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return (totalNumberOfMovies() + 1)/MoviesViewController.NUM_MOVIES_PER_ROW
  }
  
  // Number of movies to be shown in each row
  func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    var numberOfItems: Int
    if (section + 1) == numberOfSections(in: collectionView) {
      numberOfItems = totalNumberOfMovies() - section*MoviesViewController.NUM_MOVIES_PER_ROW
    }
    else {
      numberOfItems = MoviesViewController.NUM_MOVIES_PER_ROW
    }
    return numberOfItems
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionCell", for: indexPath) as! MovieCollectionCell
    
    let movieIndex = indexPath.section*MoviesViewController.NUM_MOVIES_PER_ROW + indexPath.row;
    var movie:NSDictionary
    if searchBarIsEmpty() {
      movie = moviesDictionaryArray![movieIndex]
    }
    else {
      movie = filteredMoviesDictionaryArray![movieIndex]
    }
    
    if let posterPath = movie["poster_path"] as? String {
      let baseURL = "http://image.tmdb.org/t/p/w500";
      let imageURL = URL(string: baseURL + posterPath)
      cell.moviePosterView.setImageWithAnimation(imageURL!)
    }
        return cell

  }
  // MARK: - Navigation
  
  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    var movie:NSDictionary?
    if segue.identifier == "TableViewSegue" {
      let cell = sender as! UITableViewCell
      let indexPath = moviesTableView.indexPath(for: cell)
      movie = moviesDictionaryArray![indexPath!.row]
    }
    else if segue.identifier == "CollectionViewSegue" {
      let cell = sender as! UICollectionViewCell
      let indexPath = moviesCollectionView.indexPath(for: cell)
      let movieIndex = indexPath!.section*MoviesViewController.NUM_MOVIES_PER_ROW + indexPath!.row
      movie = moviesDictionaryArray![movieIndex]
    }
    let movieDetailViewController = segue.destination as! MovieDetailViewController
    movieDetailViewController.movie = movie;
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
        self.moviesCollectionView.reloadData()
        ACProgressHUD.shared.hideHUD()

        // Hide the network error view
        self.networkErrorView.isHidden = true;

        onDataLoad();
     }
      else if (error != nil) {
        // Show the network error view
        self.networkErrorView.isHidden = false;
        ACProgressHUD.shared.hideHUD()
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
    moviesCollectionView.reloadData()
  }


  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    filterContentForSearchText(searchBar.text!)
  }
}

extension UIImageView {
  func setImageWithAnimation(_ url:URL)  {
    
    let imageRequest = URLRequest.init(url: url)
    
    self.setImageWith(
      imageRequest,
      placeholderImage: nil,
      success: { (imageRequest, imageResponse, image) -> Void in
        
        // imageResponse will be nil if the image is cached
        if imageResponse != nil {
          self.alpha = 0.0
          self.image = image
          UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.alpha = 1.0
          })
        } else {
          self.image = image
        }
    },
      failure: { (imageRequest, imageResponse, error) -> Void in
        // do something for the failure condition
    })

  }
}
