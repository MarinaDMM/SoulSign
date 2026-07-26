//
//  ClaudeServiceTests.swift
//  SoulSignTests
//
//  Integration tests for the HTTP layer of ClaudeService using a mocked
//  URLSession — no real Anthropic API calls.
//
import XCTest
@testable import SoulSign

final class ClaudeServiceTests: XCTestCase {

    private var service: ClaudeService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        service = ClaudeService(session: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.reset()
        service = nil
        super.tearDown()
    }

    private func response(_ code: Int, for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    func testSendBuildsCorrectRequest() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{"content":[{"type":"text","text":"hello"}]}"#.data(using: .utf8)!
            return (self.response(200, for: request), body)
        }

        _ = try await service.send(messages: [ChatMessage(role: "user", content: "hi there")])

        let req = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(req.url?.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let bodyData = try XCTUnwrap(MockURLProtocol.bodyData(from: req))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "claude-opus-4-8")
        let messages = try XCTUnwrap(json["messages"] as? [[String: String]])
        XCTAssertEqual(messages.first?["content"], "hi there")
    }

    func testSendParsesText() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{"content":[{"type":"text","text":"the stars align"}]}"#.data(using: .utf8)!
            return (self.response(200, for: request), body)
        }
        let text = try await service.send(messages: [ChatMessage(role: "user", content: "x")])
        XCTAssertEqual(text, "the stars align")
    }

    func testNon200Throws() async {
        MockURLProtocol.requestHandler = { request in
            (self.response(429, for: request), Data(#"{"error":"rate limited"}"#.utf8))
        }
        do {
            _ = try await service.send(messages: [ChatMessage(role: "user", content: "x")])
            XCTFail("expected an error for HTTP 429")
        } catch {
            XCTAssertEqual((error as NSError).code, 429)
        }
    }

    func testMalformedResponseThrows() async {
        MockURLProtocol.requestHandler = { request in
            (self.response(200, for: request), Data(#"{"unexpected":true}"#.utf8))
        }
        do {
            _ = try await service.send(messages: [ChatMessage(role: "user", content: "x")])
            XCTFail("expected an error for malformed body")
        } catch {
            // expected
        }
    }
}
