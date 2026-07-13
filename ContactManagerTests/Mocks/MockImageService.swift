//
//  MockImageService.swift
//  ContactManagerTests
//
//  Mock used to test image-generation logic without hitting the network (DI).
//

import Foundation
@testable import ContactManager

struct MockImageService: ImageServiceProviding {
    var dataToReturn: Data
    var shouldThrow: Bool = false

    init(dataToReturn: Data = Data([0x01, 0x02, 0x03]), shouldThrow: Bool = false) {
        self.dataToReturn = dataToReturn
        self.shouldThrow = shouldThrow
    }

    func fetchRandomImage(width: Int, height: Int) async throws -> Data {
        if shouldThrow {
            throw ImageServiceError.emptyData
        }
        return dataToReturn
    }
}
