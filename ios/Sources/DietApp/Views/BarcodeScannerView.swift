import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

/// Barcode scanner view for food product lookup
#if os(iOS)
public struct BarcodeScannerView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = BarcodeScannerModel()

    let onBarcodeScanned: (String) -> Void

    // MARK: - Initialization

    public init(onBarcodeScanned: @escaping (String) -> Void) {
        self.onBarcodeScanned = onBarcodeScanned
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Camera preview
            ScannerPreview(scanner: scanner)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Torch toggle
                    if scanner.isTorchAvailable {
                        Button {
                            scanner.toggleTorch()
                        } label: {
                            Image(systemName: scanner.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundStyle(scanner.isTorchOn ? .yellow : .white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()

                Spacer()

                // Scanning guide
                scanningGuide

                Spacer()

                // Instructions
                VStack(spacing: 8) {
                    if scanner.isScanning {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(scanner.isScanning ? "Processing..." : "Position barcode within the frame")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 60)
            }

            // Permission denied overlay
            if scanner.permissionDenied {
                permissionDeniedView
            }
        }
        .onAppear {
            scanner.checkPermission()
        }
        .onChange(of: scanner.scannedCode) { _, newCode in
            if let code = newCode {
                onBarcodeScanned(code)
                dismiss()
            }
        }
    }

    private var scanningGuide: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.7, 280)
            let height: CGFloat = 160

            ZStack {
                // Dimmed overlay with cutout
                Color.black.opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: width, height: height)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Corner brackets
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: width, height: height)

                // Scanning line animation
                if !scanner.isScanning {
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: width - 20, height: 2)
                        .modifier(ScanningLineAnimator())
                }
            }
        }
        .frame(height: 200)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please allow camera access in Settings to scan barcodes.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

// MARK: - Scanning Line Animator

struct ScanningLineAnimator: ViewModifier {
    @State private var offset: CGFloat = -60

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 60
                }
            }
    }
}

// MARK: - Scanner Model

@MainActor
class BarcodeScannerModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var permissionDenied = false
    @Published var isTorchOn = false
    @Published var isTorchAvailable = false

    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var currentDevice: AVCaptureDevice?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupScanner()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }
    }

    private func setupScanner() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Add video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Add metadata output for barcodes
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .upce,
                .code39,
                .code128,
                .pdf417,
                .qr
            ]
        }

        session.commitConfiguration()

        currentDevice = device
        isTorchAvailable = device.hasTorch

        // Start session on background thread
        Task.detached { [weak self] in
            self?.session.startRunning()
        }
    }

    func toggleTorch() {
        guard let device = currentDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if isTorchOn {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            }
            device.unlockForConfiguration()
            isTorchOn.toggle()
        } catch {
            print("Torch error: \(error)")
        }
    }
}

extension BarcodeScannerModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else {
            return
        }

        Task { @MainActor in
            // Prevent duplicate scans
            guard scannedCode == nil else { return }

            isScanning = true

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Small delay for UX
            try? await Task.sleep(for: .milliseconds(300))

            scannedCode = code
        }
    }
}

// MARK: - Scanner Preview

struct ScannerPreview: UIViewRepresentable {
    let scanner: BarcodeScannerModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: scanner.session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

#else
// macOS stub
public struct BarcodeScannerView: View {
    let onBarcodeScanned: (String) -> Void

    public init(onBarcodeScanned: @escaping (String) -> Void) {
        self.onBarcodeScanned = onBarcodeScanned
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Barcode scanning not available on macOS")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
#endif
