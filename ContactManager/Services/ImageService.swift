//
//  ImageService.swift
//  ContactManager
//

import Foundation

/// Protocol so view models can be injected with a mock in tests (DI / SOLID).
protocol ImageServiceProviding: Sendable {
    /// Returns raw image `Data` only - a `Sendable` value safe to hand back to
    /// a `@MainActor` caller. Never touches SwiftData models or contexts.
    func fetchRandomImage(width: Int, height: Int) async throws -> Data
}

extension ImageServiceProviding {
    func fetchRandomImage() async throws -> Data {
        try await fetchRandomImage(width: 200, height: 300)
    }
}

enum ImageServiceError: LocalizedError {
    case invalidURL
    case badResponse(status: Int)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Could not build the image request URL."
        case .badResponse(let status): return "Image server returned status \(status)."
        case .emptyData: return "The image server returned no data."
        }
    }
}

/// Live implementation backed by the public picsum.photos API.
struct ImageService: ImageServiceProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRandomImage(width: Int, height: Int) async throws -> Data {
        // Cache-buster guarantees a fresh random image on every tap.
        let cacheBuster = UUID().uuidString
        guard let url = URL(string: "https://picsum.photos/\(width)/\(height)?random=\(cacheBuster)") else {
            throw ImageServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ImageServiceError.badResponse(status: http.statusCode)
        }
        guard !data.isEmpty else { throw ImageServiceError.emptyData }
        return data
    }
}
