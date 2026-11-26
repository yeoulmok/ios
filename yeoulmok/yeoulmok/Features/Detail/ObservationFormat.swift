import Foundation

/// Turns one `ValleyObservation` into the four lines of its box on the alert detail
/// screen (APP-DTL-03, Figma 04): 관측소 · 관측 시각 · 실측값 · 기준값.
///
/// Numbers use `ValleyFormat`, so they look the same as on the home cards.
/// A missing value is always "-", never "0" (feature spec 3-1).
nonisolated enum ObservationFormat {
    /// `원주 신림(AWS) (강수)`. A kind the app does not know shows the station only.
    static func station(_ observation: ValleyObservation) -> String {
        guard let kind = kindName(observation.kind) else { return observation.station }
        return "\(observation.station) (\(kind))"
    }

    /// `21:50`, or `11/13 21:50` on another day, or `-`.
    static func time(_ observation: ValleyObservation, now: Date = .now) -> String {
        ValleyFormat.observedTime(observation.observedAt, now: now)
    }

    /// `18.0mm / 1시간`, `+0.06m / 30분`. Missing: `-`, or `- (수위 결측)` when
    /// the server says why.
    static func value(_ observation: ValleyObservation) -> String {
        guard let value = observation.value else {
            guard let note = observation.note, !note.isEmpty else { return ValleyFormat.missing }
            return "\(ValleyFormat.missing) (\(note))"
        }
        switch observation.kind {
        case .rainLastHour: return ValleyFormat.rainfall(value) + " / 1시간"
        case .waterRise30Min: return ValleyFormat.waterRise(value) + " / 30분"
        case .estRise3h: return ValleyFormat.waterRise(value) + " / 3시간"
        case .other: return plain(value, unit: observation.unit)
        }
    }

    /// `15.0mm / 1시간`, `0.10m / 30분`, or `-` when the server has none.
    /// The water limit has no sign: it is how much a rise must reach.
    static func threshold(_ observation: ValleyObservation) -> String {
        guard let threshold = observation.threshold else { return ValleyFormat.missing }
        switch observation.kind {
        case .rainLastHour: return ValleyFormat.rainfall(threshold) + " / 1시간"
        case .waterRise30Min: return String(format: "%.2fm", threshold) + " / 30분"
        case .estRise3h: return String(format: "%.2fm", threshold) + " / 3시간"
        case .other: return plain(threshold, unit: observation.unit)
        }
    }

    // MARK: Gauge card (#63)

    /// Card title: `강수 1시간`, `30분 상승`, `3시간 수위 상승`; a kind the app does not know: the station.
    static func title(_ observation: ValleyObservation) -> String {
        switch observation.kind {
        case .rainLastHour: "강수 1시간"
        case .waterRise30Min: "30분 상승"
        case .estRise3h: "3시간 수위 상승"
        case .other: observation.station
        }
    }

    /// The number next to the gauge, without the period: `18.0mm`, `+0.06m`, or `-`.
    static func shortValue(_ observation: ValleyObservation) -> String {
        guard let value = observation.value else { return ValleyFormat.missing }
        return short(value, observation)
    }

    /// The threshold next to the gauge: `15.0mm`, `0.10m`, or `nil` when there is none.
    static func shortThreshold(_ observation: ValleyObservation) -> String? {
        guard let threshold = observation.threshold else { return nil }
        switch observation.kind {
        case .rainLastHour: return ValleyFormat.rainfall(threshold)
        case .waterRise30Min, .estRise3h: return String(format: "%.2fm", threshold)
        case .other: return plain(threshold, unit: observation.unit)
        }
    }

    /// Small line under the gauge: `원주 신림(AWS) · 21:50`, with the reason when the
    /// value is missing (`횡성(갑천) · 수위 결측` when there is no time either). AI estimates say so instead of a station.
    static func footnote(_ observation: ValleyObservation, now: Date = .now) -> String {
        let source = observation.isEstimated ? estimatedSource : observation.station
        var parts = [source]
        // No time at all reads better than "· - ·" next to the reason.
        if observation.observedAt != nil {
            parts.append(time(observation, now: now))
        }
        if observation.value == nil, let note = observation.note, !note.isEmpty {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }

    /// Temporary wording until QA.
    static let estimatedSource = "강수량으로 추정한 값이에요"

    private static func short(_ value: Double, _ observation: ValleyObservation) -> String {
        switch observation.kind {
        // `+` like the water rise (#107); the spoken sentence keeps the plain value.
        case .rainLastHour: ValleyFormat.rainfallSigned(value)
        case .waterRise30Min, .estRise3h: ValleyFormat.waterRise(value)
        case .other: plain(value, unit: observation.unit)
        }
    }

    /// What VoiceOver reads for the whole box.
    static func accessibilityLabel(_ observation: ValleyObservation, now: Date = .now) -> String {
        let parts = [
            kindName(observation.kind),
            observation.station,
            "관측 시각 \(time(observation, now: now))",
            "실측값 \(value(observation))",
            "기준값 \(threshold(observation))",
        ]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }

    private static func kindName(_ kind: ObservationKind) -> String? {
        switch kind {
        case .rainLastHour: "강수"
        case .waterRise30Min: "수위"
        case .estRise3h: "AI 추정 수위"
        case .other: nil
        }
    }

    /// A kind the app does not know: the number as is, with the server's unit.
    private static func plain(_ number: Double, unit: String) -> String {
        String(format: "%g", number) + unit
    }
}
