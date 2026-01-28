import Foundation

/// HTTP client for API communication
/// Handles authentication, request building, and response parsing
public final class APIClient {

    // MARK: - Properties

    private var baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Auth token provider for authenticated requests
    public var tokenProvider: (() async -> String?)?

    // MARK: - Initialization

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        // Configure decoder
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // Configure encoder
        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Configuration

    /// Update the base URL (e.g., for environment switching)
    public func updateBaseURL(_ url: URL) {
        self.baseURL = url
    }

    // MARK: - Request Methods

    /// Perform a GET request
    public func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try await buildRequest(
            method: .get,
            path: path,
            queryItems: queryItems
        )
        return try await perform(request)
    }

    /// Perform a POST request with a body
    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B
    ) async throws -> T {
        var request = try await buildRequest(method: .post, path: path)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    /// Perform a POST request without a body
    public func post<T: Decodable>(_ path: String) async throws -> T {
        let request = try await buildRequest(method: .post, path: path)
        return try await perform(request)
    }

    /// Perform a PUT request with a body
    public func put<T: Decodable, B: Encodable>(
        _ path: String,
        body: B
    ) async throws -> T {
        var request = try await buildRequest(method: .put, path: path)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    /// Perform a DELETE request
    public func delete<T: Decodable>(_ path: String) async throws -> T {
        let request = try await buildRequest(method: .delete, path: path)
        return try await perform(request)
    }

    /// Perform a DELETE request without expecting a response body
    public func delete(_ path: String) async throws {
        let request = try await buildRequest(method: .delete, path: path)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Private Methods

    private func buildRequest(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> URLRequest {
        // Build URL
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add auth token if available
        if let token = await tokenProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            throw APIError.validationError
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - HTTP Method

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Errors

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case rateLimited
    case serverError(Int)
    case httpError(Int)
    case decodingFailed(Error)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .validationError:
            return "Validation error"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Response Wrapper

/// Standard API response wrapper
public struct APIResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let error: APIErrorResponse?
}

/// API error response structure
public struct APIErrorResponse: Decodable {
    public let code: String
    public let message: String
    public let details: [String: String]?
}
