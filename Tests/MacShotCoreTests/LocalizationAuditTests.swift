import XCTest
@testable import MacShotCore

final class LocalizationAuditTests: XCTestCase {
    func testMissingLanguageReported() {
        let json = #"""
        {"sourceLanguage":"en","strings":{"Hello":{"localizations":{
          "es":{"stringUnit":{"value":"Hola"}},"fr":{"stringUnit":{"value":"Bonjour"}}}}}}
        """#.data(using: .utf8)!
        XCTAssertEqual(LocalizationAudit.missingKeys(catalogJSON: json, required: ["Hello"], languages: ["es", "fr", "de"]), ["Hello"])
    }
    func testCompleteCatalogNoMissing() {
        let json = #"""
        {"sourceLanguage":"en","strings":{"Hello":{"localizations":{
          "es":{"stringUnit":{"value":"Hola"}},"fr":{"stringUnit":{"value":"Bonjour"}},"de":{"stringUnit":{"value":"Hallo"}}}}}}
        """#.data(using: .utf8)!
        XCTAssertEqual(LocalizationAudit.missingKeys(catalogJSON: json, required: ["Hello"], languages: ["es", "fr", "de"]), [])
    }
    func testAbsentKeyReported() {
        let json = #"{"sourceLanguage":"en","strings":{}}"#.data(using: .utf8)!
        XCTAssertEqual(LocalizationAudit.missingKeys(catalogJSON: json, required: ["Missing"], languages: ["es"]), ["Missing"])
    }
    func testEmptyValueCountsAsMissing() {
        let json = #"""
        {"sourceLanguage":"en","strings":{"K":{"localizations":{"es":{"stringUnit":{"value":""}}}}}}
        """#.data(using: .utf8)!
        XCTAssertEqual(LocalizationAudit.missingKeys(catalogJSON: json, required: ["K"], languages: ["es"]), ["K"])
    }
}
