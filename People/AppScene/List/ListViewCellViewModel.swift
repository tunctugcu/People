//
//  ListViewCellViewModel.swift
//  People
//
//  Created by Tunc Tugcu on 10.08.2021.
//

import Foundation

struct ListViewCellModel {
    private let person: Person
    
    init(person: Person) {
        self.person = person
    }
}

extension ListViewCellModel: Hashable {
    static func == (lhs: ListViewCellModel, rhs: ListViewCellModel) -> Bool {
        return lhs.person.id == rhs.person.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(person.id)
    }
}

extension ListViewCellModel {
    var text: String {
        return "\(person.fullName) (\(person.id))"
    }
}
