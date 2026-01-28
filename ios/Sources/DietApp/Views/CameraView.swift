import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

/// Camera capture view for food photos
public struct CameraView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraModel()

    let onPhotoCaptured: (Data) -> Void

    // MARK: - Initialization

    public init(onPhotoCaptured: @escaping (Data) -> Void) {
        self.onPhotoCaptured = onPhotoCaptured
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(camera: camera)
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
                            .padding()
                            .background(Circle().fill(.black.opacity(0.5)))
                    }

                    Spacer()

                    if camera.isFlashAvailable {
                        Button {
                            camera.toggleFlash()
                        } label: {
                            Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Circle().fill(.black.opacity(0.5)))
                        }
                    }
                }
                .padding()

                Spacer()

                // Capture hint
                Text("Position your meal in the frame")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.black.opacity(0.5)))

                Spacer()

                // Bottom controls
                HStack {
                    // Photo library button
                    Button {
                        // TODO: Photo picker
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                    }

                    Spacer()

                    // Capture button
                    Button {
                        camera.capturePhoto { data in
                            if let data = data {
                                onPhotoCaptured(data)
                                dismiss()
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 4)
                                .frame(width: 80, height: 80)

                            Circle()
                                .fill(.white)
                                .frame(width: 68, height: 68)
                        }
                    }
                    .disabled(camera.isCapturing)

                    Spacer()

                    // Flip camera button
                    Button {
                        camera.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }

            // Permission denied overlay
            if camera.permissionDenied {
                permissionDeniedView
            }
        }
        .onAppear {
            camera.checkPermission()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please allow camera access in Settings to take food photos.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                #if canImport(UIKit)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

// MARK: - Camera Model

@MainActor
class CameraModel: NSObject, ObservableObject {
    @Published var isCapturing = false
    @Published var permissionDenied = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var isFlashAvailable = false

    let session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var captureCompletion: ((Data?) -> Void)?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupCamera()
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

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Add video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Add photo output
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        currentDevice = device
        isFlashAvailable = device.hasFlash

        // Start session on background thread
        Task.detached { [weak self] in
            self?.session.startRunning()
        }
    }

    func capturePhoto(completion: @escaping (Data?) -> Void) {
        isCapturing = true
        captureCompletion = completion

        let settings = AVCapturePhotoSettings()

        if isFlashAvailable {
            settings.flashMode = flashMode
        }

        output.capturePhoto(with: settings, delegate: self)
    }

    func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
    }

    func flipCamera() {
        session.beginConfiguration()

        // Remove current input
        session.inputs.forEach { session.removeInput($0) }

        // Get new position
        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .back ? .front : .back

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        currentDevice = device
        isFlashAvailable = device.hasFlash && newPosition == .back

        session.commitConfiguration()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            isCapturing = false

            if let error = error {
                print("Photo capture error: \(error)")
                captureCompletion?(nil)
                return
            }

            let data = photo.fileDataRepresentation()
            captureCompletion?(data)
        }
    }
}

// MARK: - Camera Preview

#if canImport(UIKit)
struct CameraPreview: UIViewRepresentable {
    let camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
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
struct CameraPreview: View {
    let camera: CameraModel

    var body: some View {
        Color.black
            .overlay {
                Text("Camera not available on macOS")
                    .foregroundStyle(.secondary)
            }
    }
}
#endif
