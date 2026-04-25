import NIOCore
import NIOSSH

extension SSHClient {
    public func sendKeepAlive() async throws {
        let box = self.session.sshHandler
        try await box._eventLoop.flatSubmit {
            let promise = box._eventLoop.makePromise(of: Void.self)
            box.value.sendOpenSSHKeepalive(promise: promise)
            return promise.futureResult
        }.get()
    }
}
