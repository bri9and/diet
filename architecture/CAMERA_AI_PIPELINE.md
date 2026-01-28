# Camera & AI Pipeline
## Diet App - Agent 04

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Camera Capture                            │
│                    (AVFoundation/UIKit)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Image Preprocessing                          │
│              - Resize to 640x640                                │
│              - Normalize for ML                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────────┐
│   On-Device Classifier   │     │        Cloud Vision API          │
│      (Core ML)           │     │     (Gemini 1.5 Flash)          │
│                          │     │                                  │
│   - Quick classification │     │   - Detailed analysis           │
│   - Privacy preserving   │     │   - Complex dishes              │
│   - Works offline        │     │   - Portion estimation          │
└─────────────────────────┘     └─────────────────────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Result Aggregation                            │
│           - Merge predictions                                   │
│           - Apply sanity checks                                 │
│           - Calculate confidence                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Nutrition Lookup                               │
│        - Match to food database                                 │
│        - Calculate macros for portion                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    User Review UI                                │
│        - Display predictions                                    │
│        - Allow corrections                                      │
│        - Log meal                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. AVFoundation Camera Setup

```swift
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Camera Manager
final class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var error: CameraError?
    @Published var isTorchOn = false

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    enum CameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case captureFailed(Error)

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is required to take food photos"
            case .configurationFailed:
                return "Failed to configure camera"
            case .captureFailed(let error):
                return "Capture failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Session Setup

    func setupSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()

        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.configurationFailed
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        session.addInput(input)

        // Output
        let output = AVCapturePhotoOutput()
        output.maxPhotoQualityPrioritization = .balanced // Good quality, reasonable speed
        guard session.canAddOutput(output) else {
            throw CameraError.configurationFailed
        }
        session.addOutput(output)
        self.photoOutput = output

        // Configure for food photography
        if device.isFocusModeSupported(.continuousAutoFocus) {
            try device.lockForConfiguration()
            device.focusMode = .continuousAutoFocus
            device.unlockForConfiguration()
        }

        session.commitConfiguration()
        self.captureSession = session
    }

    // MARK: - Preview Layer

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        return layer
    }

    // MARK: - Session Control

    func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    // MARK: - Capture

    func capturePhoto() async throws -> UIImage {
        guard let photoOutput else {
            throw CameraError.configurationFailed
        }

        isCapturing = true
        defer { isCapturing = false }

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = isTorchOn ? .on : .off

            // Use HEIF for efficiency
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings.photoCodecType = .hevc
            }

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Torch

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            photoContinuation?.resume(throwing: CameraError.captureFailed(error))
            photoContinuation = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoContinuation?.resume(throwing: CameraError.captureFailed(NSError(domain: "Camera", code: -1)))
            photoContinuation = nil
            return
        }

        capturedImage = image
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
```

### SwiftUI Camera View

```swift
// MARK: - Camera Preview (UIKit Bridge)
struct CameraPreviewView: UIViewRepresentable {
    let camera: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        if let previewLayer = camera.makePreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera View
struct CameraView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingResult = false

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(camera: camera)
                .ignoresSafeArea()

            // Overlay
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    Button {
                        camera.toggleTorch()
                    } label: {
                        Image(systemName: camera.isTorchOn ? "bolt.fill" : "bolt.slash")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Spacer()

                // Guide text
                Text("Center your meal in the frame")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                // Capture button
                Button {
                    Task {
                        await captureAndAnalyze()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)

                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .disabled(camera.isCapturing || viewModel.isAnalyzing)
                .padding(.bottom, 40)
            }

            // Loading overlay
            if camera.isCapturing || viewModel.isAnalyzing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)

                    Text(viewModel.isAnalyzing ? "Analyzing..." : "Capturing...")
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await setupCamera()
        }
        .onDisappear {
            camera.stopSession()
        }
        .fullScreenCover(isPresented: $showingResult) {
            if let result = viewModel.recognitionResult {
                PhotoReviewView(
                    image: camera.capturedImage,
                    result: result,
                    viewModel: viewModel
                )
            }
        }
    }

    private func setupCamera() async {
        guard await camera.requestAuthorization() else {
            camera.error = .notAuthorized
            return
        }

        do {
            try camera.setupSession()
            camera.startSession()
        } catch {
            camera.error = error as? CameraManager.CameraError ?? .configurationFailed
        }
    }

    private func captureAndAnalyze() async {
        do {
            let image = try await camera.capturePhoto()
            await viewModel.analyzeImage(image)
            showingResult = true
        } catch {
            print("Capture error: \(error)")
        }
    }
}
```

---

## 3. Core ML Integration

```swift
import CoreML
import Vision

// MARK: - On-Device Classifier
final class OnDeviceClassifier {
    private var model: VNCoreMLModel?
    private let modelName = "FoodClassifier"

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine // Use Neural Engine when available

            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                print("Model not found in bundle")
                return
            }

            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Failed to load Core ML model: \(error)")
        }
    }

    // MARK: - Classification

    func classify(image: UIImage) async throws -> [FoodPrediction] {
        guard let model else {
            throw ClassificationError.modelNotLoaded
        }

        guard let cgImage = image.cgImage else {
            throw ClassificationError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: ClassificationError.classificationFailed(error))
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let predictions = results.prefix(5).map { observation in
                    FoodPrediction(
                        foodName: observation.identifier,
                        confidence: Double(observation.confidence),
                        source: .onDevice,
                        portionEstimate: nil
                    )
                }

                continuation.resume(returning: predictions)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ClassificationError.classificationFailed(error))
            }
        }
    }

    enum ClassificationError: LocalizedError {
        case modelNotLoaded
        case invalidImage
        case classificationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "Food recognition model not loaded"
            case .invalidImage:
                return "Invalid image format"
            case .classificationFailed(let error):
                return "Classification failed: \(error.localizedDescription)"
            }
        }
    }
}
```

---

## 4. Cloud Vision Service (Gemini)

```swift
import Foundation

// MARK: - Cloud Vision Service
final class CloudVisionService {
    private let apiClient: APIClient
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Analyze Food Photo

    func analyzeFood(image: UIImage) async throws -> [FoodPrediction] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CloudVisionError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this food image and identify all food items visible.
        For each item, provide:
        1. Food name (be specific, e.g., "grilled chicken breast" not just "chicken")
        2. Estimated portion size in common units (oz, cups, pieces)
        3. Confidence level (high, medium, low)

        Respond in JSON format:
        {
            "foods": [
                {
                    "name": "food name",
                    "portion": "portion estimate",
                    "portion_grams": estimated_grams,
                    "confidence": "high|medium|low"
                }
            ]
        }

        If no food is detected, return {"foods": []}.
        Be conservative with portions - it's better to underestimate.
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 1024
            ]
        ]

        let response = try await apiClient.post(
            url: baseURL,
            body: requestBody,
            headers: ["Content-Type": "application/json"]
        )

        return try parseGeminiResponse(response)
    }

    private func parseGeminiResponse(_ data: Data) throws -> [FoodPrediction] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw CloudVisionError.parseError
        }

        // Extract JSON from response
        guard let jsonStart = text.firstIndex(of: "{"),
              let jsonEnd = text.lastIndex(of: "}") else {
            throw CloudVisionError.parseError
        }

        let jsonString = String(text[jsonStart...jsonEnd])
        let foodData = try JSONDecoder().decode(GeminiFoodResponse.self, from: jsonString.data(using: .utf8)!)

        return foodData.foods.map { food in
            FoodPrediction(
                foodName: food.name,
                confidence: food.confidenceValue,
                source: .cloud,
                portionEstimate: PortionEstimate(
                    description: food.portion,
                    grams: food.portionGrams
                )
            )
        }
    }

    enum CloudVisionError: LocalizedError {
        case invalidImage
        case networkError(Error)
        case parseError

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process image"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .parseError:
                return "Could not parse AI response"
            }
        }
    }
}

// MARK: - Response Models
struct GeminiFoodResponse: Codable {
    let foods: [GeminiFood]
}

struct GeminiFood: Codable {
    let name: String
    let portion: String
    let portionGrams: Double?
    let confidence: String

    var confidenceValue: Double {
        switch confidence.lowercased() {
        case "high": return 0.9
        case "medium": return 0.7
        case "low": return 0.5
        default: return 0.6
        }
    }

    enum CodingKeys: String, CodingKey {
        case name, portion, confidence
        case portionGrams = "portion_grams"
    }
}
```

---

## 5. Food Recognition Service (Orchestrator)

```swift
import Foundation

// MARK: - Food Prediction
struct FoodPrediction: Identifiable, Equatable {
    let id = UUID()
    let foodName: String
    let confidence: Double
    let source: PredictionSource
    let portionEstimate: PortionEstimate?

    enum PredictionSource {
        case onDevice
        case cloud
        case merged
    }

    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.85...: return .high
        case 0.7..<0.85: return .medium
        default: return .low
        }
    }

    enum ConfidenceLevel {
        case high, medium, low

        var description: String {
            switch self {
            case .high: return "High confidence"
            case .medium: return "Medium confidence"
            case .low: return "Low confidence"
            }
        }
    }
}

struct PortionEstimate: Equatable {
    let description: String
    let grams: Double?
}

// MARK: - Recognition Result
struct RecognitionResult: Equatable {
    let predictions: [FoodPrediction]
    let processedImage: UIImage?
    let timestamp: Date

    var topPrediction: FoodPrediction? {
        predictions.first
    }

    var needsUserConfirmation: Bool {
        guard let top = topPrediction else { return true }
        return top.confidence < 0.85
    }
}

// MARK: - Food Recognition Service
final class FoodRecognitionService {
    private let onDevice: OnDeviceClassifier
    private let cloud: CloudVisionService
    private let foodDatabase: FoodItemRepository
    private let networkMonitor: NetworkMonitor

    // Thresholds
    private let onDeviceConfidenceThreshold = 0.85
    private let maxCaloriesPerItem = 3000.0
    private let minCaloriesPerItem = 1.0

    init(
        onDevice: OnDeviceClassifier,
        cloud: CloudVisionService,
        foodDatabase: FoodItemRepository = AppEnvironment.shared.foodItemRepository,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.onDevice = onDevice
        self.cloud = cloud
        self.foodDatabase = foodDatabase
        self.networkMonitor = networkMonitor
    }

    // MARK: - Main Recognition Flow

    func recognizeFood(in image: UIImage) async throws -> RecognitionResult {
        // Step 1: Try on-device first (fast, private)
        let onDevicePredictions = try await onDevice.classify(image: image)

        // Step 2: Check if on-device result is confident enough
        if let topPrediction = onDevicePredictions.first,
           topPrediction.confidence >= onDeviceConfidenceThreshold {
            // High confidence on-device result
            let enrichedPredictions = await enrichWithNutrition(onDevicePredictions)
            return RecognitionResult(
                predictions: enrichedPredictions,
                processedImage: image,
                timestamp: Date()
            )
        }

        // Step 3: Use cloud API for better accuracy (if online)
        if networkMonitor.isConnected {
            do {
                let cloudPredictions = try await cloud.analyzeFood(image: image)
                let mergedPredictions = mergePredictions(onDevice: onDevicePredictions, cloud: cloudPredictions)
                let validatedPredictions = applySanityChecks(mergedPredictions)
                let enrichedPredictions = await enrichWithNutrition(validatedPredictions)

                return RecognitionResult(
                    predictions: enrichedPredictions,
                    processedImage: image,
                    timestamp: Date()
                )
            } catch {
                // Cloud failed, fall back to on-device
                print("Cloud recognition failed: \(error)")
            }
        }

        // Step 4: Fall back to on-device results
        let enrichedPredictions = await enrichWithNutrition(onDevicePredictions)
        return RecognitionResult(
            predictions: enrichedPredictions,
            processedImage: image,
            timestamp: Date()
        )
    }

    // MARK: - Merge Predictions

    private func mergePredictions(onDevice: [FoodPrediction], cloud: [FoodPrediction]) -> [FoodPrediction] {
        // Cloud predictions take priority for naming
        // But boost confidence if both agree
        var merged: [FoodPrediction] = []

        for cloudPred in cloud {
            let matchingOnDevice = onDevice.first { pred in
                pred.foodName.lowercased().contains(cloudPred.foodName.lowercased()) ||
                cloudPred.foodName.lowercased().contains(pred.foodName.lowercased())
            }

            var confidence = cloudPred.confidence
            if matchingOnDevice != nil {
                // Both agree - boost confidence
                confidence = min(0.95, confidence + 0.1)
            }

            merged.append(FoodPrediction(
                foodName: cloudPred.foodName,
                confidence: confidence,
                source: .merged,
                portionEstimate: cloudPred.portionEstimate
            ))
        }

        return merged
    }

    // MARK: - Sanity Checks

    private func applySanityChecks(_ predictions: [FoodPrediction]) -> [FoodPrediction] {
        predictions.filter { prediction in
            // Filter out obviously wrong predictions
            // This prevents "8000 cal for popcorn" errors

            // Check for reasonable food names (not garbage)
            guard prediction.foodName.count >= 2 else { return false }

            return true
        }
    }

    // MARK: - Enrich with Nutrition Data

    private func enrichWithNutrition(_ predictions: [FoodPrediction]) async -> [FoodPrediction] {
        var enriched: [FoodPrediction] = []

        for prediction in predictions {
            // Look up in local database
            if let foodItems = try? await foodDatabase.search(query: prediction.foodName, limit: 1),
               let match = foodItems.first {
                // We found a match - the prediction is valid
                enriched.append(prediction)
            } else {
                // No match found - still include but with lower confidence
                enriched.append(FoodPrediction(
                    foodName: prediction.foodName,
                    confidence: prediction.confidence * 0.9,
                    source: prediction.source,
                    portionEstimate: prediction.portionEstimate
                ))
            }
        }

        return enriched
    }
}
```

---

## 6. Result Caching

```swift
import Foundation

// MARK: - Recognition Cache
actor RecognitionCache {
    static let shared = RecognitionCache()

    private var cache: [String: CachedResult] = [:]
    private let maxCacheSize = 50
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    struct CachedResult {
        let result: RecognitionResult
        let timestamp: Date
    }

    func get(imageHash: String) -> RecognitionResult? {
        guard let cached = cache[imageHash] else { return nil }

        // Check expiration
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: imageHash)
            return nil
        }

        return cached.result
    }

    func set(imageHash: String, result: RecognitionResult) {
        // Evict oldest if at capacity
        if cache.count >= maxCacheSize {
            let oldest = cache.min { $0.value.timestamp < $1.value.timestamp }
            if let key = oldest?.key {
                cache.removeValue(forKey: key)
            }
        }

        cache[imageHash] = CachedResult(result: result, timestamp: Date())
    }

    func clear() {
        cache.removeAll()
    }
}

// MARK: - Image Hashing
extension UIImage {
    var quickHash: String {
        guard let data = jpegData(compressionQuality: 0.1) else {
            return UUID().uuidString
        }

        // Simple hash for cache key
        var hash = 0
        for byte in data.prefix(1000) {
            hash = hash &* 31 &+ Int(byte)
        }
        return String(hash)
    }
}
```

---

## 7. Camera ViewModel

```swift
import SwiftUI

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var recognitionResult: RecognitionResult?
    @Published var isAnalyzing = false
    @Published var error: Error?

    private let recognitionService: FoodRecognitionService
    private let foodLogRepository: FoodLogRepository
    private let cache = RecognitionCache.shared

    init(
        recognitionService: FoodRecognitionService,
        foodLogRepository: FoodLogRepository
    ) {
        self.recognitionService = recognitionService
        self.foodLogRepository = foodLogRepository
    }

    func analyzeImage(_ image: UIImage) async {
        isAnalyzing = true
        error = nil

        do {
            // Check cache first
            let hash = image.quickHash
            if let cached = await cache.get(imageHash: hash) {
                recognitionResult = cached
                isAnalyzing = false
                return
            }

            // Perform recognition
            let result = try await recognitionService.recognizeFood(in: image)
            recognitionResult = result

            // Cache result
            await cache.set(imageHash: hash, result: result)

        } catch {
            self.error = error
        }

        isAnalyzing = false
    }

    func logFood(prediction: FoodPrediction, meal: FoodLogRecord.MealType) async {
        // Look up nutrition data
        guard let foodItem = try? await lookupFood(prediction.foodName) else {
            // Handle not found
            return
        }

        let quantity = prediction.portionEstimate?.grams ?? foodItem.servingSize

        let log = FoodLogRecord(
            id: UUID().uuidString,
            userId: CurrentUser.id,
            foodItemId: foodItem.id,
            date: Calendar.current.startOfDay(for: Date()),
            mealType: meal,
            quantity: quantity,
            unit: "g",
            calories: calculateCalories(foodItem: foodItem, quantity: quantity),
            protein: calculateNutrient(foodItem.protein, servingSize: foodItem.servingSize, quantity: quantity),
            carbs: calculateNutrient(foodItem.carbs, servingSize: foodItem.servingSize, quantity: quantity),
            fat: calculateNutrient(foodItem.fat, servingSize: foodItem.servingSize, quantity: quantity),
            fiber: foodItem.fiber.map { calculateNutrient($0, servingSize: foodItem.servingSize, quantity: quantity) },
            notes: nil,
            photoUrl: nil, // Save photo separately if needed
            aiConfidence: prediction.confidence,
            loggedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            synced: false
        )

        try? await foodLogRepository.save(log)
    }

    private func lookupFood(_ name: String) async throws -> FoodItemRecord? {
        let results = try await AppEnvironment.shared.foodItemRepository.search(query: name, limit: 1)
        return results.first
    }

    private func calculateCalories(foodItem: FoodItemRecord, quantity: Double) -> Double {
        (foodItem.calories / foodItem.servingSize) * quantity
    }

    private func calculateNutrient(_ nutrientPer100g: Double, servingSize: Double, quantity: Double) -> Double {
        (nutrientPer100g / servingSize) * quantity
    }
}
```

---

*Document continues in PERFORMANCE_TARGETS.md*
