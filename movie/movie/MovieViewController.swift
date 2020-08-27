//
//  MovieViewController.swift
//  movie
//
//  Created by 60080252 on 2020/08/25.
//  Copyright © 2020 60080252. All rights reserved.
//

import UIKit
import Kingfisher

class MovieViewController: UIViewController {
    private let country: String = ""
    private let displayCount: Int = 100
    private let appendCount: Int = 20
    private var queryString: String?
    private var itemStartIdx: Int = 0
    
    private var movies: MovieSearchResult = MovieSearchResult()
    private var movieItems: [Moive] = []
    
    @IBOutlet weak var movieTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // prefetch시 movieItems배열에 appendCount만큼 추가
    func appendMovies(count: Int) {
        guard let total = self.movies.total else { return }
        if self.itemStartIdx >= total { return }
        
        if self.itemStartIdx + count < total {
            movieItems.append(contentsOf: self.movies.items[self.itemStartIdx ..< self.itemStartIdx + count])
            self.itemStartIdx += self.appendCount
        } else {
            movieItems.append(contentsOf: self.movies.items[self.itemStartIdx ..< total])
            self.itemStartIdx = total
        }
        
        if self.itemStartIdx % self.displayCount == 0 {
            self.loadMoreMovies()
        }
        self.movieTableView.reloadData()
    }
    
    // SearchBar로 검색 시
    func loadMovies(queryValue: String?) {
        guard let queryString = queryValue else { return }
        self.itemStartIdx = 0
        self.movieItems.removeAll()
        MovieService.movieSearchList(queryString: queryString, country: self.country, start: 1, display: self.displayCount) { result in
            if result.total != 0 {
                self.movies = result
                self.appendMovies(count: self.appendCount)
            } else {
                self.movies = MovieSearchResult()
            }
            self.movieTableView.setContentOffset(.zero, animated: true)
            self.movieTableView.reloadData()
        }
    }
    
    // pagination 처리 - 추가 결과를 보여줌
    func loadMoreMovies() {
        guard let queryString = self.queryString else { return }
        MovieService.movieSearchList(queryString: queryString, country: self.country, start: self.itemStartIdx + 1, display: self.displayCount) { result in
            if result.total != 0 {
                self.movies.items.append(contentsOf: result.items)
            }
        }
    }
}

extension MovieViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if movieItems.count - 1 == indexPath.row {
                appendMovies(count: self.appendCount)
            }
        }
    }
}

extension MovieViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.queryString = searchBar.text
        searchBar.endEditing(true)
        loadMovies(queryValue: searchBar.text)
    }
}

extension MovieViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell", for: indexPath) as! MovieTableViewCell

        let currentCellMovie = self.movieItems[indexPath.row]

        let font = UIFont(name: "AppleSDGothicNeo-Regular", size: 15)!
        if let tmpKorMovieTitle = currentCellMovie.movieTitle {
            cell.korMovieTitle.attributedText = tmpKorMovieTitle.htmlEscaped(isTitle: true, colorHex: "#a0b4fa", font: font)
        }
        if let tmpEngMovieTitle = currentCellMovie.movieSubtitle {
            cell.engMovieTitle.attributedText = tmpEngMovieTitle.htmlEscaped(isTitle: false, colorHex: "#a0b4fa", font: font)
        }

        // 이미지URL이 없을 경우 default이미지로 대체
        if currentCellMovie.movieImage != "" {
            if let imageUrlStr = currentCellMovie.movieImage {
                let imageUrl = URL(string: imageUrlStr)
                cell.movieImage.kf.setImage(with: imageUrl)
            }
        } else {
            cell.movieImage.image = UIImage(named: "defaultImg.png")
        }
        
        return cell
    }
    
    //셀의 높이변경
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension MovieViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        if let cell = tableView.cellForRow(at: indexPath) as! MovieTableViewCell? {
            print(cell.korMovieTitle?.text)
        }
    }
}

extension String {
    // <b> 하이라이트 효과
    func htmlEscaped(isTitle: Bool, colorHex: String, font: UIFont) -> NSAttributedString {
        let titleStyle = """
                        <style>
                        body {
                        font-size: 17px;
                        font-family: \(font.familyName);
                        font-weight: bolder;
                        }
                        b {
                        color: \(colorHex);
                        }
                        </style>
                        """
        
        let subtitleStyle = """
                            <style>
                            body {
                            font-family: \(font.familyName);
                            font-size: 13px;
                            }
                            b {
                            color: \(colorHex);
                            }
                            </style>
                            """
        var modified = ""
        if isTitle {
            modified = String(format:"\(titleStyle)%@", self)
        } else {
            modified = String(format:"\(subtitleStyle)%@", self)
        }
        
        do {
            guard let data = modified.data(using: .unicode) else {
                return NSAttributedString(string: self)
            }
            let attributed = try NSAttributedString(data: data,
                                                    options: [.documentType: NSAttributedString.DocumentType.html],
                                                    documentAttributes: nil)
            return attributed
        } catch {
            return NSAttributedString(string: self)
        }
    }
}

