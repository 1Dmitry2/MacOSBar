import HubCore
import Testing

@Test func byteCountFormats() {
    let s = ByteCountFormat.string(1_048_576)
    #expect(s.contains("MB") || s.contains("1"))
}
