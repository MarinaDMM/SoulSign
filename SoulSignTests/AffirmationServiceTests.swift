//
//  AffirmationServiceTests.swift
//  SoulSignTests
//
import XCTest
@testable import SoulSign

final class AffirmationServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        AffirmationService.session = MockURLProtocol.makeSession()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        AffirmationService.session = .shared
        super.tearDown()
    }

    private func ok(_ request: URLRequest, _ body: String) -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
         Data(body.utf8))
    }

    func testParsesValidResponse() {
        MockURLProtocol.requestHandler = { request in
            // Claude returns a content[].text whose text is itself the JSON payload.
            let inner = #"{\"Finance\":\"f\",\"Love\":\"l\",\"MindSpirit\":\"m\",\"Career\":\"c\",\"Friendship\":\"fr\",\"Health\":\"h\"}"#
            let body = "{\"content\":[{\"type\":\"text\",\"text\":\"\(inner)\"}]}"
            return self.ok(request, body)
        }

        let exp = expectation(description: "affirmations parsed")
        AffirmationService.fetchAffirmations(language: .en) { result in
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.Finance, "f")
            XCTAssertEqual(result?.Health, "h")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    func testMalformedResponseReturnsNil() {
        MockURLProtocol.requestHandler = { request in
            self.ok(request, #"{"content":[{"type":"text","text":"not json"}]}"#)
        }
        let exp = expectation(description: "nil on malformed")
        AffirmationService.fetchAffirmations(language: .en) { result in
            XCTAssertNil(result)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    func testNonEnglishAddsLanguageInstruction() {
        let exp = expectation(description: "request captured")
        MockURLProtocol.requestHandler = { request in
            let inner = #"{\"Finance\":\"f\",\"Love\":\"l\",\"MindSpirit\":\"m\",\"Career\":\"c\",\"Friendship\":\"fr\",\"Health\":\"h\"}"#
            return self.ok(request, "{\"content\":[{\"type\":\"text\",\"text\":\"\(inner)\"}]}")
        }
        AffirmationService.fetchAffirmations(language: .fr) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 5)

        let req = MockURLProtocol.lastRequest!
        let bodyData = MockURLProtocol.bodyData(from: req)!
        let bodyString = String(data: bodyData, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("French"),
                      "non-English requests should instruct Claude to write in that language")
    }
}
