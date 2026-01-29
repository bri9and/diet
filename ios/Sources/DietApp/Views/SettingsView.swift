import SwiftUI
import Clerk
#if canImport(UIKit)
import UIKit
#endif

/// Settings view for app configuration and preferences
public struct SettingsView: View {

    // MARK: - Environment

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        List {
            // Account section
            Section {
                accountRow

                NavigationLink {
                    EditProfileView()
                } label: {
                    settingsRow(
                        icon: "person.fill",
                        title: "Edit Profile",
                        color: .blue
                    )
                }

                NavigationLink {
                    GoalsSettingsView()
                } label: {
                    settingsRow(
                        icon: "target",
                        title: "Goals",
                        color: .green
                    )
                }
            } header: {
                Text("Account")
            }

            // Privacy section
            Section {
                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    settingsRow(
                        icon: "hand.raised.fill",
                        title: "Privacy",
                        color: .blue
                    )
                }

                NavigationLink {
                    DataSettingsView()
                } label: {
                    settingsRow(
                        icon: "externaldrive.fill",
                        title: "Data & Storage",
                        color: .purple
                    )
                }
            } header: {
                Text("Privacy & Data")
            }

            // Notifications section
            Section {
                NavigationLink {
                    NotificationSettingsView(notificationService: appEnvironment.notificationService)
                } label: {
                    settingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        color: .red
                    )
                }
            } header: {
                Text("Notifications")
            }

            // Legal section
            Section {
                Button {
                    openURL(URL(string: "https://example.com/privacy")!)
                } label: {
                    HStack {
                        settingsRow(
                            icon: "doc.text.fill",
                            title: "Privacy Policy",
                            color: .gray
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    openURL(URL(string: "https://example.com/terms")!)
                } label: {
                    HStack {
                        settingsRow(
                            icon: "doc.plaintext.fill",
                            title: "Terms of Service",
                            color: .gray
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Legal")
            }

            // About section
            Section {
                HStack {
                    settingsRow(
                        icon: "info.circle.fill",
                        title: "Version",
                        color: .gray
                    )

                    Spacer()

                    Text("v\(ContentView.appVersion)")
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Account Row

    private var accountRow: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay {
                    if let user = clerk.user, let initial = (user.firstName ?? user.username ?? "U").first {
                        Text(String(initial).uppercased())
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                if let user = clerk.user {
                    Text(user.firstName ?? user.username ?? "User")
                        .font(.headline)

                    if let email = user.primaryEmailAddress?.emailAddress {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
}

// MARK: - Edit Profile View (Placeholder)

struct EditProfileView: View {
    var body: some View {
        List {
            Section {
                Text("Edit profile coming soon")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Edit Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Goals Settings View (Placeholder)

struct GoalsSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Goals settings coming soon")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Goals")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @State private var shareAnalytics = true
    @State private var shareWithFamily = false

    var body: some View {
        List {
            Section {
                Toggle("Share Analytics", isOn: $shareAnalytics)
                Toggle("Share with Family", isOn: $shareWithFamily)
            } header: {
                Text("Data Sharing")
            } footer: {
                Text("Analytics help us improve the app. Your data is never sold to third parties.")
            }

            Section {
                NavigationLink {
                    Text("Download your data")
                } label: {
                    Text("Download My Data")
                }

                NavigationLink {
                    Text("Delete account")
                } label: {
                    Text("Delete Account")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Your Data")
            }
        }
        .navigationTitle("Privacy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Data Settings View

struct DataSettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    Text("Export data")
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                NavigationLink {
                    Text("Health App integration")
                } label: {
                    Label("Health App", systemImage: "heart.fill")
                }
            } header: {
                Text("Export")
            }

            Section {
                Button(role: .destructive) {
                    // Clear cache
                } label: {
                    Text("Clear Cache")
                }
            } header: {
                Text("Storage")
            }
        }
        .navigationTitle("Data & Storage")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
    NavigationStack {
        SettingsView()
    }
}
