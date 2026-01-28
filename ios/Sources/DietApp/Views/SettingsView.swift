import SwiftUI
import Clerk
#if canImport(UIKit)
import UIKit
#endif

/// Settings view for app configuration and user preferences
public struct SettingsView: View {

    // MARK: - Environment

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.clerk) private var clerk

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                // Account section
                Section {
                    accountRow
                } header: {
                    Text("Account")
                }

                // Preferences section
                Section {
                    NavigationLink {
                        Text("Goals")
                    } label: {
                        settingsRow(
                            icon: "target",
                            title: "Goals",
                            color: .green
                        )
                    }

                    NavigationLink {
                        Text("Units")
                    } label: {
                        settingsRow(
                            icon: "scalemass",
                            title: "Units",
                            color: .blue
                        )
                    }

                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        settingsRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            color: .red
                        )
                    }
                } header: {
                    Text("Preferences")
                }

                // Data section
                Section {
                    NavigationLink {
                        Text("Export Data")
                    } label: {
                        settingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            color: .purple
                        )
                    }

                    NavigationLink {
                        Text("Health App")
                    } label: {
                        settingsRow(
                            icon: "heart.fill",
                            title: "Health App",
                            color: .pink
                        )
                    }
                } header: {
                    Text("Data")
                }

                // About section
                Section {
                    NavigationLink {
                        Text("Privacy Policy")
                    } label: {
                        settingsRow(
                            icon: "hand.raised.fill",
                            title: "Privacy Policy",
                            color: .gray
                        )
                    }

                    NavigationLink {
                        Text("Terms of Service")
                    } label: {
                        settingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            color: .gray
                        )
                    }

                    HStack {
                        settingsRow(
                            icon: "info.circle.fill",
                            title: "Version",
                            color: .gray
                        )

                        Spacer()

                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Sign out section
                Section {
                    Button(role: .destructive) {
                        Task {
                            try? await clerk.session?.revoke()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Account Row

    private var accountRow: some View {
        HStack(spacing: 16) {
            // User avatar
            Circle()
                .fill(Color.avatarBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                if let user = clerk.user {
                    Text(user.firstName ?? user.username ?? "User")
                        .font(.headline)

                    if let email = user.primaryEmailAddress?.emailAddress {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("User")
                        .font(.headline)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Settings Row

    private func settingsRow(
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
        }
    }

    // MARK: - App Version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Color Extensions

extension Color {
    #if canImport(UIKit)
    static let avatarBackground = Color(UIColor.systemGray4)
    #else
    static let avatarBackground = Color(NSColor.systemGray)
    #endif
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.shared)
}
