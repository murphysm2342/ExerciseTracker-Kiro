import Foundation
import CoreNFC

enum NFCScanError: Error, LocalizedError {
    case notAvailable
    case cancelled
    case readFailed(String)
    case noPayload

    var errorDescription: String? {
        switch self {
        case .notAvailable:    return "NFC scanning is not available on this device."
        case .cancelled:       return nil
        case .readFailed(let msg): return "Failed to read tag: \(msg)"
        case .noPayload:       return "No data found on the tag."
        }
    }
}

@Observable
final class NFCService: NSObject {
    var isScanning = false

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return NFCNDEFReaderSession.readingAvailable
        #endif
    }

    private var session: NFCNDEFReaderSession?
    private var continuation: CheckedContinuation<String, Error>?

    func scan() async throws -> String {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCScanError.notAvailable
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            self.isScanning = true
            let readerSession = NFCNDEFReaderSession(
                delegate: self,
                queue: .main,
                invalidateAfterFirstRead: true
            )
            readerSession.alertMessage = "Hold your iPhone near the machine's NFC tag."
            self.session = readerSession
            readerSession.begin()
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var identifier = ""

        for message in messages {
            for record in message.records {
                if record.typeNameFormat == .nfcWellKnown {
                    if let (text, _) = Optional(record.wellKnownTypeTextPayload()), let text, !text.isEmpty {
                        identifier = text
                        break
                    }
                    if let url = record.wellKnownTypeURIPayload() {
                        identifier = url.absoluteString
                        break
                    }
                }
                if identifier.isEmpty {
                    let payloadData = record.payload
                    if !payloadData.isEmpty {
                        identifier = payloadData.map { String(format: "%02x", $0) }.joined()
                    }
                }
            }
            if !identifier.isEmpty { break }
        }

        isScanning = false
        if identifier.isEmpty {
            continuation?.resume(throwing: NFCScanError.noPayload)
        } else {
            session.alertMessage = "Machine identified!"
            continuation?.resume(returning: identifier)
        }
        continuation = nil
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        isScanning = false

        guard let nfcError = error as? NFCReaderError else {
            continuation?.resume(throwing: NFCScanError.readFailed(error.localizedDescription))
            continuation = nil
            return
        }

        switch nfcError.code {
        case .readerSessionInvalidationErrorFirstNDEFTagRead:
            break
        case .readerSessionInvalidationErrorUserCanceled:
            continuation?.resume(throwing: NFCScanError.cancelled)
            continuation = nil
        default:
            continuation?.resume(throwing: NFCScanError.readFailed(nfcError.localizedDescription))
            continuation = nil
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}
}

// MARK: - NFC Tag Mapping Storage

struct NFCTagMapping: Codable {
    enum MachineKind: String, Codable {
        case strength
        case cardio
    }
    let kind: MachineKind
    let strengthMachineId: UUID?
    let cardioMachineType: CardioMachineType?
}

enum NFCTagStore {
    private static let key = "nfc_tag_mappings"

    static func mapping(for tagId: String) -> NFCTagMapping? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: NFCTagMapping].self, from: data)
        else { return nil }
        return dict[tagId]
    }

    static func save(tagId: String, mapping: NFCTagMapping) {
        var dict = allMappings()
        dict[tagId] = mapping
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func allMappings() -> [String: NFCTagMapping] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: NFCTagMapping].self, from: data)
        else { return [:] }
        return dict
    }
}
