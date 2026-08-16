//
//  AnimatedDoughnutChart.swift
//  Wayne Finance
//
//  Gráfico de anillo (doughnut) minimalista: proporciones de trazo
//  relativas al tamaño disponible, arcos con separación angular sutil,
//  y animación de aparición progresiva vía trim().
//

import SwiftUI

struct DoughnutSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let label: String
}

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false)
        return path
    }
}

struct AnimatedDoughnutChart: View {

    let segments: [DoughnutSegment]
    var centerTitle: String
    var centerValue: String

    @State private var progress: CGFloat = 0
    private let gapDegrees: Double = 3

    private var total: Double { segments.reduce(0) { $0 + $1.value } }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let lineWidth = side * 0.16

            ZStack {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let (start, end) = angles(for: index)

                    ArcShape(startAngle: start, endAngle: end)
                        .trim(from: 0, to: progress)
                        .stroke(
                            segment.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .animation(
                            .easeOut(duration: 0.9).delay(Double(index) * 0.08),
                            value: progress
                        )
                }

                VStack(spacing: 2) {
                    Text(centerValue)
                        .font(.system(size: side * 0.13, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(centerTitle)
                        .font(.system(size: side * 0.055, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: side * 0.62)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            progress = 0
            withAnimation { progress = 1 }
        }
    }

    private func angles(for index: Int) -> (Angle, Angle) {
        guard total > 0 else { return (.degrees(0), .degrees(0)) }

        let precedingSum = segments[..<index].reduce(0) { $0 + $1.value }
        let startFraction = precedingSum / total
        let endFraction = (precedingSum + segments[index].value) / total

        let startDeg = startFraction * 360 + (gapDegrees / 2)
        let endDeg = endFraction * 360 - (gapDegrees / 2)

        return (.degrees(startDeg), .degrees(max(startDeg, endDeg)))
    }
}
