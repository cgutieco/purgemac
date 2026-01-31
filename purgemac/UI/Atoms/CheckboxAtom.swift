//
//  CheckboxAtom.swift
//  PurgeMac
//
//  PurgeMac - Deep Cleaning Uninstaller for macOS
//

import SwiftUI

// MARK: - Checkbox Atom

struct CheckboxAtom: View {
    @Binding var isChecked: Bool
    var label: String? = nil
    var isDisabled: Bool = false
    
    var body: some View {
        Toggle(isOn: $isChecked) {
            if let label {
                Text(label)
                    .font(.body)
            }
        }
        .toggleStyle(.checkbox)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Custom Checkbox Style (Alternative)

struct AnimatedCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isOn ? Color.accentColor : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    }
                
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
            
            configuration.label
        }
    }
}

extension ToggleStyle where Self == AnimatedCheckboxStyle {
    static var animated: AnimatedCheckboxStyle { AnimatedCheckboxStyle() }
}

// MARK: - Preview

#if DEBUG
struct CheckboxPreview: View {
    @State private var isChecked1 = false
    @State private var isChecked2 = true
    @State private var isChecked3 = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Native Checkbox").font(.headline)
            CheckboxAtom(isChecked: $isChecked1, label: "Application Support")
            CheckboxAtom(isChecked: $isChecked2, label: "Caches")
            CheckboxAtom(isChecked: $isChecked3, label: "Disabled", isDisabled: true)
            
            Divider()
            
            Text("Animated Style").font(.headline)
            Toggle("Custom animated", isOn: $isChecked1)
                .toggleStyle(.animated)
        }
        .padding()
        .frame(width: 300, height: 250)
    }
}

#Preview("Checkbox Atom") {
    CheckboxPreview()
}
#endif
