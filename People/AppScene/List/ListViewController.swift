//
//  ListViewController.swift
//  People
//
//  Created by Tunc Tugcu on 10.08.2021.
//

import UIKit

final class ListViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!
    
    private let viewModel = ListViewModel()
    private let refreshControl = UIRefreshControl()
    
    private enum Section {
        case people
    }
    
    private var dataSource: UITableViewDiffableDataSource<Section, ListViewCellModel>?
    private var isLoading = false {
        didSet {
            isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        }
    }
    
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private enum Constant {
        static let reuseId = "cell"
        static let loadThreshold = 10
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup loading indicator
        loadingIndicator.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
        // Setup refresh control
        refreshControl.addTarget(self, action: #selector(resetAndFetch), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.delegate = self
        
        updateViews()
        
        // Setup data source
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, model) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: Constant.reuseId, for: indexPath)
            cell.textLabel?.text = model.text
            
            return cell
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchNext()
    }
    
    private func fetchNext() {
        guard !isLoading else {
            print("Already loading...")
            return
        }
        
        self.isLoading = true
        guard var snapshot = dataSource?.snapshot() else {
            fatalError("Unable to take snapshot!!!")
        }
        
        viewModel.fetchNext { [weak self] (models, error) in
            guard let self = self else { return }
            defer {
                self.refreshControl.endRefreshing()
            }
            
            if let error = error {
                self.isLoading = false
                self.updateViews()
                self.showError(error)
                
                return
            }
            
            if snapshot.indexOfSection(.people) == nil {
                snapshot.appendSections([.people])
            }
            
            snapshot.appendItems(models, toSection: .people)
            self.dataSource?.apply(snapshot, animatingDifferences: false) {
                self.updateViews()
                self.isLoading = false
                
                // Check last row
                if let lastIndexPath = self.tableView.indexPathsForVisibleRows?.sorted(by: >).first,
                   self.checkFetchNeeded(for: lastIndexPath) {
                    self.fetchNext()
                }
                
            }
        }
    }
    
    @objc private func resetAndFetch() {
        guard !isLoading else {
            refreshControl.endRefreshing()
            return
        }
        
        guard refreshControl.isRefreshing, var snapshot = dataSource?.snapshot() else { return }
        
        snapshot.deleteAllItems()
        dataSource?.apply(snapshot, animatingDifferences: false)
        viewModel.reset()
        fetchNext()
    }
    
    private func checkFetchNeeded(for indexPath: IndexPath) -> Bool {
        let numberOrRows = tableView.numberOfRows(inSection: 0)
        
        return indexPath.row + Constant.loadThreshold > numberOrRows - 1
    }
    
    private func updateViews() {
        let emptyLabelIsHidden = tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0
        
        emptyLabel.isHidden = emptyLabelIsHidden
        tableView.separatorStyle = emptyLabelIsHidden ? .singleLine : .none
    }
    
    private func showError(_ error: FetchError) {
        let controller = UIAlertController(title: "Error", message: error.errorDescription, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.fetchNext()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        controller.addAction(retryAction)
        controller.addAction(cancelAction)
        
        present(controller, animated: true, completion: nil)
    }
}

extension ListViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !emptyLabel.isHidden else {
            return
        }
        
        emptyLabel.transform = CGAffineTransform(translationX: 0, y: -scrollView.contentOffset.y)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if checkFetchNeeded(for: indexPath) {
            fetchNext()
        }
    }
}
