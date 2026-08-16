//
//  SmartFloatingOverlay.swift
//  Wayne Finance
//
//  Sistema de overlays flotantes (dropdowns / pickers) que calculan su
//  propia posición según el espacio disponible en pantalla.
//

import SwiftUI

private struct FloatingAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let next = nextValue() { value = next }
    }
}

extension View {
    func floatingAnchor() -> some View {
        anchorPreference(key: FloatingAnchorKey.self, value: .bounds) { $0 }
    }
}

struct FloatingPickerItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

private enum PanelDirection { case below, above }

extension View {
    func floatingPickerHost(
        isPresented: Binding<Bool>,
        items: [FloatingPickerItem],
        selectedID: UUID?,
        onSelect: @escaping (FloatingPickerItem) -> Void
    ) -> some View {
        overlayPreferenceValue(FloatingAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if isPresented.wrappedValue, let anchor {
                    FloatingPanel(
                        triggerFrame: proxy[anchor],
                        containerSize: proxy.size,
                        safeAreaInsets: proxy.safeAreaInsets,
                        items: items,
                        selectedID: selectedID,
                        isPresented: isPresented,
                        onSelect: onSelect
                    )
                }
            }
        }
    }
}

private struct FloatingPanel: View {
    let triggerFrame: CGRect
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets
    let items: [FloatingPickerItem]
    let selectedID: UUID?
    @Binding var isPresented: Bool
    let onSelect: (FloatingPickerItem) -> Void

    private let rowHeight: CGFloat = 46
    private let maxVisibleRows: CGFloat = 5.5
    private let panelWidth: CGFloat = 240
    private let verticalGap: CGFloat = 8
    private let edgeMargin: CGFloat = 12

    var body: some View {
        let contentHeight = min(CGFloat(items.count), maxVisibleRows) * rowHeight
        let idealHeight = contentHeight + 16

        let spaceBelow = containerSize.height - triggerFrame.maxY - safeAreaInsets.bottom - edgeMargin
        let spaceAbove = triggerFrame.minY - safeAreaInsets.top - edgeMargin

        let direction: PanelDirection = {
            if spaceBelow >= idealHeight { return .below }
            if spaceAbove >= idealHeight { return .above }
            return spaceBelow >= spaceAbove ? .below : .above
        }()

        let panelHeight = min(idealHeight, max(spaceBelow, spaceAbove, rowHeight))

        let originY: CGFloat = direction == .below
            ? triggerFrame.maxY + verticalGap
            : triggerFrame.minY - verticalGap - panelHeight

        let rawX = triggerFrame.minX
        let clampedX = min(max(rawX, edgeMargin), containerSize.width - panelWidth - edgeMargin)

        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.001)
                .frame(width: containerSize.width, height: containerSize.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.18)) { isPresented = false }
                }

            panelBody(height: panelHeight)
                .position(x: clampedX + panelWidth / 2, y: originY + panelHeight / 2)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.92, anchor: direction == .below ? .top : .bottom)
                            .combined(with: .opacity),
                        removal: .opacity
                    )
                )
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isPresented)
    }

    @ViewBuilder
    private func panelBody(height: CGFloat) -> some View {
        ScrollView(showsIndicators: items.count > Int(maxVisibleRows)) {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    row(for: item)
                }
            }
        }
        .frame(width: panelWidth, height: height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }

    @ViewBuilder
    private func row(for item: FloatingPickerItem) -> some View {
        let isSelected = item.id == selectedID

        Button {
            onSelect(item)
            withAnimation(.easeOut(duration: 0.18)) { isPresented = false }
        } label: {
            HStack(spacing: 10) {
                if let icon = item.systemImage {
                    Image(systemName: icon)
                        .frame(width: 18)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if item.id != items.last?.id {
            Divider().padding(.leading, 14).opacity(0.15)
        }
    }
}
