import SwiftUI

struct UninstallerSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.uninstallerEnabled) private var enabled = false

    var body: some View {
        Form {
            Section {
                Toggle(l10n.s.uninstallerEnable, isOn: $enabled)
                Text(l10n.s.uninstallerEnableCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(l10n.s.uninstallerHowTitle) {
                bullet("1", l10n.s.uninstallerStep1)
                bullet("2", l10n.s.uninstallerStep2)
                bullet("3", l10n.s.uninstallerStep3)
            }

            if enabled {
                Section {
                    Button {
                        appDelegate()?.openUninstallerWindow()
                    } label: {
                        Label(l10n.s.uninstallerOpen, systemImage: "trash")
                    }
                }
                if !permissions.fullDiskAccess {
                    Section {
                        Text(l10n.s.uninstallerFDANote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(l10n.s.permissionOpenSettings) {
                            permissions.openFullDiskAccessSettings()
                        }
                        .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func bullet(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
