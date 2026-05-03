import NIO
import NIOSSH

extension SSHClient {
    /// Opens an OpenSSH `direct-streamlocal@openssh.com` channel — a forward to a Unix domain socket
    /// on the server. Equivalent to `ssh -L /local.sock:/remote.sock`. Required for talking to
    /// docker.sock / podman.sock without a docker CLI on the local machine.
    public func createDirectStreamLocalChannel(
        socketPath: String,
        initialize: @escaping (Channel) -> EventLoopFuture<Void>
    ) async throws -> Channel {
        try await eventLoop.flatSubmit { [eventLoop, sshHandler = self.session.sshHandler] in
            let createdChannel = eventLoop.makePromise(of: Channel.self)
            sshHandler.value.createChannel(
                createdChannel,
                channelType: .directStreamLocal(.init(socketPath: socketPath))
            ) { channel, type in
                guard case .directStreamLocal = type else {
                    return channel.eventLoop.makeFailedFuture(SSHClientError.channelCreationFailed)
                }

                do {
                    try channel.pipeline.syncOperations.addHandler(DataToBufferCodec())
                } catch {
                    return channel.eventLoop.makeFailedFuture(error)
                }

                return initialize(channel)
            }

            return createdChannel.futureResult
        }.get()
    }
}
