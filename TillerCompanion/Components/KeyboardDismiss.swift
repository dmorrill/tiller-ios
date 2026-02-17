//
//  KeyboardDismiss.swift
//  TillerCompanion
//
//  Keyboard dismissal utilities
//

import SwiftUI

// MARK: - Scroll Dismiss Modifier
struct ScrollDismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Tap Dismiss Modifier
struct TapDismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}

// MARK: - Toolbar Done Button
struct KeyboardDoneButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
    }
}

extension View {
    /// Dismiss keyboard interactively on scroll
    func dismissKeyboardOnScroll() -> some View {
        modifier(ScrollDismissKeyboardModifier())
    }

    /// Dismiss keyboard on tap outside text fields
    func dismissKeyboardOnTap() -> some View {
        modifier(TapDismissKeyboardModifier())
    }

    /// Add a Done button above the keyboard
    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneButton())
    }
}
