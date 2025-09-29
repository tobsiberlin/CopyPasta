import Foundation
import AppKit
import SwiftUI
import Vision
import NaturalLanguage

class OCRManager: ObservableObject {
    static let shared = OCRManager()
    
    @Published var isProcessing = false
    @Published var lastExtractedText = ""
    @Published var extractionHistory: [OCRResult] = []
    
    private let maxHistoryItems = 100
    private var currentRequest: VNImageRequestHandler?
    
    struct OCRResult: Identifiable, Codable {
        var id = UUID()
        let text: String
        let confidence: Float
        let detectedLanguage: String
        let timestamp: Date
        let imageSize: CGSize
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
    
    enum OCRAccuracy {
        case fast, balanced, accurate
        
        var recognitionLevel: VNRequestTextRecognitionLevel {
            switch self {
            case .fast: return .fast
            case .balanced: return .accurate
            case .accurate: return .accurate
            }
        }
        
        var displayName: String {
            switch self {
            case .fast: return LocalizationManager.shared.localizedString(.ocrFast)
            case .balanced: return LocalizationManager.shared.localizedString(.ocrBalanced)
            case .accurate: return LocalizationManager.shared.localizedString(.ocrAccurate)
            }
        }
    }
    
    private init() {}
    
    /// Performs OCR on image data with professional accuracy and language detection
    func extractText(from imageData: Data, 
                    accuracy: OCRAccuracy = .balanced,
                    completion: @escaping (Result<OCRResult, OCRError>) -> Void) {
        
        guard let nsImage = NSImage(data: imageData) else {
            completion(.failure(.invalidImage))
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
            }
            
            if let error = error {
                completion(.failure(.processingError(error.localizedDescription)))
                return
            }
            
            self?.processVisionResults(request.results, imageSize: nsImage.size, completion: completion)
        }
        
        // Configure OCR settings for maximum accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        
        // Set custom recognition languages based on user preferences
        if let supportedLanguages = try? request.supportedRecognitionLanguages() {
            let preferredLanguages = self.getPreferredOCRLanguages()
            let availableLanguages = supportedLanguages.filter { preferredLanguages.contains($0) }
            if !availableLanguages.isEmpty {
                request.recognitionLanguages = availableLanguages
            }
        }
        
        // Process the image
        let handler = VNImageRequestHandler(data: imageData, options: [:])
        self.currentRequest = handler
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(.failure(.processingError(error.localizedDescription)))
                }
            }
        }
    }
    
    /// Extracts text from specific region of image (Interactive OCR)
    func extractText(from imageData: Data, 
                    region: CGRect,
                    completion: @escaping (Result<OCRResult, OCRError>) -> Void) {
        
        guard let nsImage = NSImage(data: imageData) else {
            completion(.failure(.invalidImage))
            return
        }
        
        // Crop image to specified region
        guard let croppedData = cropImage(nsImage, to: region) else {
            completion(.failure(.processingError("Failed to crop image to specified region")))
            return
        }
        
        extractText(from: croppedData, completion: completion)
    }
    
    /// Batch OCR processing for multiple images
    func extractTextBatch(from imageDatas: [Data],
                         completion: @escaping ([Result<OCRResult, OCRError>]) -> Void) {
        let group = DispatchGroup()
        var results: [Result<OCRResult, OCRError>] = []
        let resultQueue = DispatchQueue(label: "com.shotcast.ocr.batch")
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        for imageData in imageDatas {
            group.enter()
            extractText(from: imageData) { result in
                resultQueue.async {
                    results.append(result)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isProcessing = false
            completion(results)
        }
    }
    
    /// Cancels current OCR operation
    func cancelCurrentOperation() {
        currentRequest = nil
        DispatchQueue.main.async {
            self.isProcessing = false
        }
    }
    
    /// Clears OCR history
    func clearHistory() {
        extractionHistory.removeAll()
        lastExtractedText = ""
    }
    
    /// Searches OCR history
    func searchHistory(query: String) -> [OCRResult] {
        guard !query.isEmpty else { return extractionHistory }
        return extractionHistory.filter { result in
            result.text.localizedCaseInsensitiveContains(query) ||
            result.detectedLanguage.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Returns OCR result as plain unformatted text (primary export)
    func getPlainText(_ result: OCRResult) -> String {
        return result.text
    }
    
    // MARK: - Private Methods
    
    private func processVisionResults(_ results: [Any]?, 
                                    imageSize: CGSize,
                                    completion: @escaping (Result<OCRResult, OCRError>) -> Void) {
        guard let observations = results as? [VNRecognizedTextObservation] else {
            completion(.failure(.noTextFound))
            return
        }
        
        guard !observations.isEmpty else {
            completion(.failure(.noTextFound))
            return
        }
        
        // Extract text with confidence scores
        var allText: [String] = []
        var confidenceScores: [Float] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            allText.append(candidate.string)
            confidenceScores.append(candidate.confidence)
        }
        
        let extractedText = allText.joined(separator: "\n")
        let avgConfidence = confidenceScores.reduce(0, +) / Float(confidenceScores.count)
        
        // Detect language
        let detectedLanguage = detectLanguage(in: extractedText)
        
        // Apply post-processing corrections
        let correctedText = applyTextCorrections(extractedText, language: detectedLanguage)
        
        let result = OCRResult(
            text: correctedText,
            confidence: avgConfidence,
            detectedLanguage: detectedLanguage,
            timestamp: Date(),
            imageSize: imageSize
        )
        
        DispatchQueue.main.async {
            self.lastExtractedText = correctedText
            self.addToHistory(result)
            
            // Copy to clipboard automatically
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(correctedText, forType: .string)
        }
        
        completion(.success(result))
    }
    
    private func detectLanguage(in text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            return Locale.current.localizedString(forLanguageCode: dominantLanguage.rawValue) ?? dominantLanguage.rawValue
        }
        
        return "Unknown"
    }
    
    private func applyTextCorrections(_ text: String, language: String) -> String {
        // Apply basic text cleaning
        var correctedText = text
        
        // Remove excessive whitespace
        correctedText = correctedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Fix common OCR errors
        correctedText = correctedText.replacingOccurrences(of: "\\b0\\b", with: "O", options: .regularExpression)
        correctedText = correctedText.replacingOccurrences(of: "\\bl\\b", with: "I", options: .regularExpression)
        correctedText = correctedText.replacingOccurrences(of: "rn", with: "m")
        
        return correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cropImage(_ image: NSImage, to region: CGRect) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let scaledRegion = CGRect(
            x: region.minX * CGFloat(cgImage.width),
            y: region.minY * CGFloat(cgImage.height),
            width: region.width * CGFloat(cgImage.width),
            height: region.height * CGFloat(cgImage.height)
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledRegion) else {
            return nil
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: scaledRegion.size)
        return croppedImage.tiffRepresentation
    }
    
    private func addToHistory(_ result: OCRResult) {
        extractionHistory.insert(result, at: 0)
        if extractionHistory.count > maxHistoryItems {
            extractionHistory = Array(extractionHistory.prefix(maxHistoryItems))
        }
    }
    
    private func getPreferredOCRLanguages() -> [String] {
        let currentLanguage = LocalizationManager.shared.currentLanguage
        
        switch currentLanguage {
        case .german: return ["de-DE", "en-US"]
        case .english: return ["en-US", "de-DE"]  
        case .spanish: return ["es-ES", "en-US", "de-DE"]
        case .french: return ["fr-FR", "en-US", "de-DE"]
        case .italian: return ["it-IT", "en-US", "de-DE"]
        case .portuguese: return ["pt-BR", "en-US", "de-DE"]
        case .dutch: return ["nl-NL", "en-US", "de-DE"]
        case .russian: return ["ru-RU", "en-US", "de-DE"]
        case .chinese: return ["zh-CN", "zh-TW", "en-US"]
        case .japanese: return ["ja-JP", "en-US"]
        case .korean: return ["ko-KR", "en-US"]
        case .arabic: return ["ar-SA", "en-US"]
        }
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case processingError(String)
    case noTextFound
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return LocalizationManager.shared.localizedString(.ocrInvalidImage)
        case .processingError(let message):
            return LocalizationManager.shared.localizedString(.ocrError) + ": \(message)"
        case .noTextFound:
            return LocalizationManager.shared.localizedString(.ocrNoTextFound)
        case .operationCancelled:
            return LocalizationManager.shared.localizedString(.ocrCancelled)
        }
    }
}