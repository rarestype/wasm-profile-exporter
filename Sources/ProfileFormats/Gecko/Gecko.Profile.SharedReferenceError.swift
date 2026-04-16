extension Gecko.Profile {
    enum SharedReferenceError: Error {
        case stack(Int, Range<Int>)
        case frame(Int, Range<Int>)
        case function(Int, Range<Int>)
        case string(Int, Range<Int>)
    }
}
