import Testing
@testable import WindowPinIPC

@Test
func responseRoundTrip() throws {
    let response = WindowPinResponse(
        success: true,
        message: "Pinned",
        windows: [
            PinnedWindowInfo(
                windowID: 42,
                ownerPID: 100,
                ownerName: "Preview",
                windowTitle: "Reference.pdf"
            ),
        ]
    )

    #expect(try WindowPinIPC.decode(WindowPinIPC.encode(response)) == response)
}
