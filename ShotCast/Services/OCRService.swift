import Foundation
import Vision
import AppKit

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func extractText(from imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                return try? observation.topCandidates(1).first?.string
            }
            
            let extractedText = recognizedStrings.joined(separator: "\n")
            
            if extractedText.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                completion(.success(extractedText))
            }
        }
        
        // Höchste Genauigkeit für bessere OCR-Ergebnisse
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Ungültiges Bildformat"
        case .noTextFound:
            return "Kein Text im Bild gefunden"
        }
    }
}