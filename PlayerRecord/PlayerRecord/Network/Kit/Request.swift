//
//  Request.swift
//  PlayerRecord
//
//  Created by 60156056 on 2023/04/25.
//

import Foundation

public class Request {
    
    public let underlyingQueue: DispatchQueue
    
    @Protected
    fileprivate var mutableState = MutableState()
    
    public var state: State { $mutableState.state }
    public var isInitialized: Bool { state == .initialized }
    public var isResumed: Bool { state == .resumed }
    public var isSuspended: Bool { state == .suspended }
    public var isCancelled: Bool { state == .cancelled }
    public var isFinished: Bool { state == .finished }
    
    public typealias ProgressHandler = (Progress) -> Void
    
    public let downloadProgress = Progress(totalUnitCount: 0)
    
    public var requests: [URLRequest] { $mutableState.requests }
    public var firstRequest: URLRequest? { requests.first }
    public var lastReqeust: URLRequest? { requests.last }
    public var request: URLRequest? { lastReqeust }
    public var performedRequests: [URLRequest] { $mutableState.read { $0.tasks.compactMap(\.currentRequest)} }
    
    public var response: HTTPURLResponse? { lastTask?.response as? HTTPURLResponse }
    
    public var tasks: [URLSessionTask] { $mutableState.tasks }
    public var firstTask: URLSessionTask? { tasks.first }
    public var lastTask: URLSessionTask? { tasks.last }
    public var task: URLSessionTask? { lastTask }
    
    public var retryCount: Int { $mutableState.retryCount }
    
    public fileprivate(set) var error: NetworkError? {
        get { $mutableState.error }
        set { $mutableState.error = newValue }
    }
    
    public enum State {
        case initialized
        case resumed
        case suspended
        case cancelled
        case finished
        
        func canTransitionTo(_ state: State) -> Bool {
            switch (self, state) {
            case (.initialized, _):
                return true
            case (_, .initialized), (.cancelled, _), (.finished, _):
                return false
            case (.resumed, .cancelled), (.suspended, .cancelled), (.resumed, .suspended), (.suspended, .resumed):
                return true
            case (.suspended, .suspended), (.resumed, .resumed):
                return false
            case (_, .finished):
                return true
            }
        }
        
        @discardableResult
        public func cancel() -> Self {
            $mutableState.write { mutableState in
                guard mutableState.state.canTransitionTo(.cancelled) else { return }
                
                mutableState.state = .cancelled
                
                underlyingQueue.async { self.didCancel() }
                
                return self
            }
        }
    }
    
    struct MutableState {
        var state: State = .initialized
        var downloadPrgressHandler: (handler: ProgressHandler, queue: DispatchQueue)?
        var requests: [URLRequest] = []
        var tasks: [URLSessionTask] = []
        var retryCount = 0
        var error: NetworkError?
        var isFinishing = false
        var finishHandlers: [() -> Void] = []
    }
    
    func didResume(){
        
    }
    
    func didResumeTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))
    }
}
