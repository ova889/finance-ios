//
//  LiquidGlassTabBar.swift
//  Wayne Finance
//
//  Barra de navegación inferior con efecto "Liquid Glass": combina
//  .ultraThinMaterial + tinte de color + borde de luz superior para
//  lograr profundidad sin sacrificar legibilidad ni rendimiento.
//

import SwiftUI
import UIKit

struct WayneTabItem: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let selectedIcon: String
    let title: String
}

struct LiquidGlassTabBar: View {

    let items: [WayneTabItem]
    @Binding var selection: Int

    @Namespace private var indicatorNamespace
    @Environment(\.colorScheme) private var colorScheme

    private let barHeight: CGFloat = 64
    private let horizontalPadding: CGFloat = 18
    private let tintOpacity: Double = 0.14
    private let indicatorCornerRadius: CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                tabButton(for: items[index], index: index)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: barHeight)
        .background(glassBackground)
        .padding(.horizontal, 16)
        .compositingGroup()
    }

    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.accentColor.opacity(tintOpacity))
                .blendMode(.softLight)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.28 : 0.55),
                            .white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 8)
    }

    @ViewBuilder
    private func tabButton(for item: WayneTabItem, index: Int) -> some View {
        let isSelected = selection == index

        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                selection = index
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)

                Text(item.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: indicatorCornerRadius, style: .continuous)
                            .fill(Color.accentColor.opacity(0.16))
                            .matchedGeometryEffect(id: "tabIndicator", in: indicatorNamespace)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}
