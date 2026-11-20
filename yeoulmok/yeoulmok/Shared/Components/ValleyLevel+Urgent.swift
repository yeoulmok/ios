extension ValleyLevel {
    /// 위험 · 대피: the levels that raise the full-screen alarm (#60).
    /// Nothing on screen moves for them: the design has no animation (#71).
    nonisolated var isUrgent: Bool { self == .danger || self == .evacuate }
}
