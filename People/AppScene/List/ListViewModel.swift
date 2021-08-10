//
//  ListViewModel.swift
//  People
//
//  Created by Tunc Tugcu on 10.08.2021.
//

import Foundation

final class ListViewModel {
    typealias FetchModelResponse = ([ListViewCellModel], FetchError?) -> Void
    
    
    private enum Constant {
        static let maximumRetryNumber = 3
    }
    
    private var next: String?
    private var retryNumber = 0
    
    
    // MARK: - Network Call
    func fetchNext(completion: @escaping FetchModelResponse) {
        DataSource.fetch(next: next) { [weak self] (response, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.retryNumber += 1
                guard self.retryNumber <= Constant.maximumRetryNumber else {
                    completion([], error)
                    return
                }
                
                self.fetchNext(completion: completion)
                return
            }
            
            self.retryNumber = 0
            self.next = response?.next
            completion(response?.people.map(ListViewCellModel.init) ?? [], nil)
        }
    }
    
    func reset() {
        next = nil
        retryNumber = 0
    }
}
