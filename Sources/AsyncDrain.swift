public final class AsyncDrain: DataRepresentable, AsyncStream {
    var buffer: Data = []
    public var closed = false
    
    public var data: Data {
        if !closed {
            return buffer
        }
        return []
    }
    
    public convenience init() {
        self.init(for: [])
    }
    
    public init(for stream: AsyncReceivingStream, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> AsyncDrain) -> Void) {
        var buffer: Data = []
        
        if stream.closed {
            self.closed = true
            completion {
                self
            }
            return
        }
        
        stream.receive(upTo: 1024, timingOut: deadline) { [unowned self] getData in
            do {
                let chunk = try getData()
                buffer.bytes += chunk.bytes
            } catch {
                completion {
                    throw error
                }
            }
            
            if stream.closed {
                self.buffer = buffer
                completion {
                    self
                }
            }
        }
    }
    
    public init(for buffer: Data) {
        self.buffer = buffer
    }
    
    public convenience init(for buffer: DataRepresentable) {
        self.init(for: buffer.data)
    }
    
    public func close() throws {
        guard !closed else {
            throw ClosableError.alreadyClosed
        }
        closed = true
    }
    
    public func receive(upTo byteCount: Int, timingOut deadline: Double = .never, completion: ((Void) throws -> Data) -> Void) {
        if byteCount >= buffer.count {
            completion { [unowned self] in
                try self.close()
                return self.buffer
            }
            return
        }
        
        let data = buffer[0..<byteCount]
        buffer.removeFirst(byteCount)
        
        completion {
            Data(data)
        }
    }
    
    public func send(_ data: Data, timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void) {
        buffer += data.bytes
        completion {}
    }
    
    public func flush(timingOut deadline: Double = .never, completion: ((Void) throws -> Void) -> Void) {
        buffer = []
        completion {}
    }
}
