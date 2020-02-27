import SwiftUI

struct ArmDragGesture: ViewModifier {
    private static let hourRelationship: Double = 360/12
    private static let minuteRelationsip: Double = 360/60

    @Environment(\.calendar) var calendar
    @Environment(\.clockDate) var date
    let type: ArmType
    @State var dragAngle: Angle = .zero
    @State var isDragging = false

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content.gesture(self.dragGesture(geometry: geometry))
        }
    }

    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged({
                self.isDragging = true
                self.dragAngle = self.angle(dragGestureValue: $0, frame: geometry.frame(in: .global))
            })
            .onEnded({
                self.setAngle(self.angle(dragGestureValue: $0, frame: geometry.frame(in: .global)))
                self.isDragging = false
            })
    }

    private func angle(dragGestureValue: DragGesture.Value, frame: CGRect) -> Angle {
        let radius = min(frame.size.width, frame.size.height)/2
        let location = (
            x: dragGestureValue.location.x - radius - frame.origin.x,
            y: dragGestureValue.location.y - radius - frame.origin.y
        )
        #if os(macOS)
        let arctan = atan2(location.x, location.y)
        #else
        let arctan = atan2(location.x, -location.y)
        #endif
        let positiveRadians = arctan > 0 ? arctan : arctan + 2 * .pi
        return Angle(radians: Double(positiveRadians))
    }

    private func setAngle(_ angle: Angle) {
        let positiveDegrees = angle.degrees > 0 ? angle.degrees : angle.degrees + 360
        switch type {
        case .hour:
            let hour = positiveDegrees/Self.hourRelationship
            let minute = calendar.component(.minute, from: date.wrappedValue)
            date.wrappedValue = .init(hour: Int(hour.rounded()), minute: minute, calendar: calendar)
        case .minute:
            let minute = positiveDegrees/Self.minuteRelationsip
            let hour = calendar.component(.hour, from: date.wrappedValue)
            date.wrappedValue = .init(hour: hour, minute: Int(minute.rounded()), calendar: calendar)
        }
    }
}