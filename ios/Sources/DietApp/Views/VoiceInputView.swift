import SwiftUI
import Speech
import AVFoundation

/// Voice input view for food logging via speech
#if os(iOS)
public struct VoiceInputView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VoiceInputViewModel

    let mealType: FoodLogRecord.MealType
    let onFoodLogged: () -> Void

    // MARK: - Initialization

    public init(
        mealType: FoodLogRecord.MealType,
        foodService: FoodService,
        onFoodLogged: @escaping () -> Void
    ) {
        self.mealType = mealType
        self.onFoodLogged = onFoodLogged
        _viewModel = StateObject(wrappedValue: VoiceInputViewModel(foodService: foodService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Microphone visualization
                microphoneView

                // Transcription text
                transcriptionView

                Spacer()

                // Parsed results
                if !viewModel.parsedItems.isEmpty {
                    parsedItemsView
                }

                // Action buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.stopListening()
                        dismiss()
                    }
                }
            }
            .alert("Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Please enable microphone and speech recognition access in Settings.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Microphone View

    private var microphoneView: some View {
        ZStack {
            // Pulsing circles when listening
            if viewModel.isListening {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i * 40), height: 120 + CGFloat(i * 40))
                        .scaleEffect(viewModel.isListening ? 1.2 : 1.0)
                        .opacity(viewModel.isListening ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.3),
                            value: viewModel.isListening
                        )
                }
            }

            // Main microphone button
            Button {
                if viewModel.isListening {
                    viewModel.stopListening()
                } else {
                    viewModel.startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.isListening ? Color.red : Color.blue)
                        .frame(width: 100, height: 100)

                    Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
            .disabled(viewModel.isParsing)
        }
        .frame(height: 200)
    }

    // MARK: - Transcription View

    private var transcriptionView: some View {
        VStack(spacing: 12) {
            if viewModel.isListening {
                Text("Listening...")
                    .font(.headline)
                    .foregroundStyle(.blue)
            } else if viewModel.isParsing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Analyzing...")
                }
                .font(.headline)
            } else if viewModel.transcribedText.isEmpty {
                Text("Tap the microphone and describe what you ate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.transcribedText.isEmpty {
                Text("\"\(viewModel.transcribedText)\"")
                    .font(.body)
                    .italic()
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Parsed Items View

    private var parsedItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found:")
                .font(.headline)

            ForEach(Array(viewModel.parsedItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                        Text(item.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Quantity controls
                    HStack(spacing: 8) {
                        Button {
                            viewModel.decrementQuantity(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(item.quantity > 0.5 ? .blue : .gray)
                        }
                        .disabled(item.quantity <= 0.5)

                        Text(item.quantity.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(item.quantity))" : String(format: "%.1f", item.quantity))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .frame(minWidth: 30)

                        Button {
                            viewModel.incrementQuantity(at: index)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }

                    Text("\(Int(item.nutrition.calories * item.quantity)) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 50, alignment: .trailing)
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Total
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.totalCalories)) cal")
                    .font(.headline)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.groupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !viewModel.parsedItems.isEmpty {
                Button {
                    Task {
                        await viewModel.logFood(mealType: mealType)
                        onFoodLogged()
                        dismiss()
                    }
                } label: {
                    Text("Add to \(mealType.displayName)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isLogging)

                Button {
                    viewModel.reset()
                } label: {
                    Text("Try Again")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.bottom)
    }
}

// MARK: - View Model

@MainActor
public final class VoiceInputViewModel: ObservableObject {

    @Published public var transcribedText = ""
    @Published public var parsedItems: [AnalyzedFoodItem] = []
    @Published public var isListening = false
    @Published public var isParsing = false
    @Published public var isLogging = false
    @Published public var showPermissionAlert = false
    @Published public var showError = false
    @Published public var errorMessage: String?

    private let foodService: FoodService
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public var totalCalories: Double {
        parsedItems.reduce(0) { $0 + ($1.nutrition.calories * $1.quantity) }
    }

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    public func incrementQuantity(at index: Int) {
        guard index < parsedItems.count else { return }
        parsedItems[index].quantity += 0.5
    }

    public func decrementQuantity(at index: Int) {
        guard index < parsedItems.count, parsedItems[index].quantity > 0.5 else { return }
        parsedItems[index].quantity -= 0.5
    }

    public func startListening() {
        // Check permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard status == .authorized else {
                    self?.showPermissionAlert = true
                    return
                }
                self?.requestMicrophonePermission()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                if granted {
                    self?.beginRecording()
                } else {
                    self?.showPermissionAlert = true
                }
            }
        }
    }

    private func beginRecording() {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showError(message: "Could not configure audio session")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            showError(message: "Speech recognition not available")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isListening = true
        } catch {
            showError(message: "Could not start audio engine")
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.finishRecording()
                }
            }
        }
    }

    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isListening = false

        if !transcribedText.isEmpty {
            parseFood()
        }
    }

    private func finishRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false

        if !transcribedText.isEmpty {
            parseFood()
        }
    }

    private func parseFood() {
        isParsing = true

        Task {
            do {
                let response = try await foodService.parseFood(text: transcribedText)
                parsedItems = response.items
            } catch {
                showError(message: "Could not analyze food description")
            }
            isParsing = false
        }
    }

    public func logFood(mealType: FoodLogRecord.MealType) async {
        guard !parsedItems.isEmpty else { return }

        isLogging = true

        let today = formatDate(Date())
        let items = parsedItems.map { item in
            CreateFoodLogItem(
                quantity: item.quantity,
                servingMultiplier: 1,
                nutrition: CreateItemNutrition(
                    calories: item.nutrition.calories * item.quantity,
                    proteinG: item.nutrition.proteinG * item.quantity,
                    carbsG: item.nutrition.carbsG * item.quantity,
                    fatG: item.nutrition.fatG * item.quantity
                ),
                foodSnapshot: CreateFoodSnapshot(
                    name: item.name,
                    servingDescription: "\(item.quantity) \(item.unit)"
                )
            )
        }

        let request = CreateFoodLogRequest(
            loggedDate: today,
            mealType: mealType.rawValue,
            entryMethod: "voice",
            items: items
        )

        do {
            _ = try await foodService.createFoodLog(request)
        } catch {
            showError(message: error.localizedDescription)
        }

        isLogging = false
    }

    public func reset() {
        transcribedText = ""
        parsedItems = []
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#else
// macOS stub
public struct VoiceInputView: View {
    let mealType: FoodLogRecord.MealType
    let onFoodLogged: () -> Void

    public init(
        mealType: FoodLogRecord.MealType,
        foodService: FoodService,
        onFoodLogged: @escaping () -> Void
    ) {
        self.mealType = mealType
        self.onFoodLogged = onFoodLogged
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Voice input not available on macOS")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
