import SwiftUI

struct IconoW: View {
    var body: some View {
        Canvas { contexto, size in
            let s = min(size.width, size.height) / 24
            var path = Path()
            path.move(to: CGPoint(x: 8 * s, y: 4 * s))
            path.addLine(to: CGPoint(x: 18 * s, y: 4 * s))
            path.move(to: CGPoint(x: 8 * s, y: 4 * s))
            path.addLine(to: CGPoint(x: 8 * s, y: 20 * s))
            path.move(to: CGPoint(x: 8 * s, y: 12 * s))
            path.addLine(to: CGPoint(x: 15 * s, y: 12 * s))
            contexto.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 1.8 * s, lineCap: .round, lineJoin: .round))
        }
    }
}


struct IconoGrid: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var path = Path()
        for (x, y) in [(3.0, 3.0), (14.0, 3.0), (3.0, 14.0), (14.0, 14.0)] {
            path.addRoundedRect(in: CGRect(x: x * s, y: y * s, width: 7 * s, height: 7 * s), cornerSize: CGSize(width: 1 * s, height: 1 * s))
        }
        return path
    }
}

struct IconoReloj: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var path = Path()
        path.addEllipse(in: CGRect(x: 2 * s, y: 2 * s, width: 20 * s, height: 20 * s))
        path.move(to: CGPoint(x: 12 * s, y: 6 * s))
        path.addLine(to: CGPoint(x: 12 * s, y: 12 * s))
        path.addLine(to: CGPoint(x: 16 * s, y: 14 * s))
        return path
    }
}

struct IconoMas: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var path = Path()
        path.move(to: CGPoint(x: 12 * s, y: 5 * s))
        path.addLine(to: CGPoint(x: 12 * s, y: 19 * s))
        path.move(to: CGPoint(x: 5 * s, y: 12 * s))
        path.addLine(to: CGPoint(x: 19 * s, y: 12 * s))
        return path
    }
}

struct IconoEngranaje: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        let c = CGPoint(x: 12 * s, y: 12 * s)
        var path = Path()

        let rad = Double.pi / 180
        let rT = 10.78
        let rA = 1.65

        for k in 0..<8 {
            let a = (24.9 + Double(k) * 45) * rad
            let cx = c.x + CGFloat(rT * cos(a)) * s
            let cy = c.y + CGFloat(rT * sin(a)) * s
            let cc = CGPoint(x: cx, y: cy)
            let e1 = CGPoint(x: cx + CGFloat(rA * cos(a - 34.2 * rad)) * s, y: cy + CGFloat(rA * sin(a - 34.2 * rad)) * s)
            let e2 = CGPoint(x: cx + CGFloat(rA * cos(a + 34.2 * rad)) * s, y: cy + CGFloat(rA * sin(a + 34.2 * rad)) * s)
            path.move(to: e1)
            path.addArc(
                center: cc,
                radius: CGFloat(rA) * s,
                startAngle: .radians(Double(atan2(e1.y - cc.y, e1.x - cc.x))),
                endAngle: .radians(Double(atan2(e2.y - cc.y, e2.x - cc.x))),
                clockwise: true
            )
        }

        path.addEllipse(in: CGRect(x: 9 * s, y: 9 * s, width: 6 * s, height: 6 * s))
        return path
    }
}

struct IconoBasura: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var path = Path()
        path.move(to: CGPoint(x: 3 * s, y: 6 * s))
        path.addLine(to: CGPoint(x: 21 * s, y: 6 * s))

        path.move(to: CGPoint(x: 19 * s, y: 6 * s))
        path.addLine(to: CGPoint(x: 19 * s, y: 20 * s))
        path.addArc(center: CGPoint(x: 17 * s, y: 20 * s), radius: 2 * s, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: 7 * s, y: 22 * s))
        path.addArc(center: CGPoint(x: 7 * s, y: 20 * s), radius: 2 * s, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: true)
        path.addLine(to: CGPoint(x: 5 * s, y: 6 * s))

        path.move(to: CGPoint(x: 8 * s, y: 6 * s))
        path.addLine(to: CGPoint(x: 8 * s, y: 4 * s))
        path.addArc(center: CGPoint(x: 10 * s, y: 4 * s), radius: 2 * s, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: true)
        path.addLine(to: CGPoint(x: 14 * s, y: 2 * s))
        path.addArc(center: CGPoint(x: 14 * s, y: 4 * s), radius: 2 * s, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: true)
        path.addLine(to: CGPoint(x: 16 * s, y: 6 * s))

        path.move(to: CGPoint(x: 10 * s, y: 11 * s))
        path.addLine(to: CGPoint(x: 10 * s, y: 17 * s))
        path.move(to: CGPoint(x: 14 * s, y: 11 * s))
        path.addLine(to: CGPoint(x: 14 * s, y: 17 * s))
        return path
    }
}

