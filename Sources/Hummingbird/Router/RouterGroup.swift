//===----------------------------------------------------------------------===//
//
// This source file is part of the Hummingbird server framework project
//
// Copyright (c) 2021-2023 the Hummingbird authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See hummingbird/CONTRIBUTORS.txt for the list of Hummingbird authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes
import HummingbirdCore
import NIOCore

/// Used to group together routes under a single path. Additional middleware can be added to the endpoint and each route can add a
/// suffix to the endpoint path
///
/// The code below creates an `HBRouterGroup`with path "todos" and adds GET and PUT routes on "todos" and adds GET, PUT and
/// DELETE routes on "todos/:id" where id is the identifier for the todo
/// ```
/// app.router
/// .group("todos")
/// .get(use: todoController.list)
/// .put(use: todoController.create)
/// .get(":id", use: todoController.get)
/// .put(":id", use: todoController.update)
/// .delete(":id", use: todoController.delete)
/// ```
public struct HBRouterGroup<Context: HBBaseRequestContext>: HBRouterMethods {
    let path: String
    let router: HBRouterBuilder<Context>
    let middlewares: HBMiddlewareGroup<Context>

    init(path: String = "", middlewares: HBMiddlewareGroup<Context> = .init(), router: HBRouterBuilder<Context>) {
        self.path = path
        self.router = router
        self.middlewares = middlewares
    }

    /// Add middleware to RouterEndpoint
    @discardableResult public func add(middleware: any HBMiddleware<Context>) -> HBRouterGroup<Context> {
        self.middlewares.add(middleware)
        return self
    }

    /// Return a group inside the current group
    /// - Parameter path: path prefix to add to routes inside this group
    @discardableResult public func group(_ path: String = "") -> HBRouterGroup<Context> {
        return HBRouterGroup(
            path: self.combinePaths(self.path, path),
            middlewares: .init(middlewares: self.middlewares.middlewares),
            router: self.router
        )
    }

    /// Add path for closure returning type using async/await
    @discardableResult public func on<Output: HBResponseGenerator>(
        _ path: String = "",
        method: HTTPRequest.Method,
        options: HBRouterMethodOptions = [],
        use closure: @Sendable @escaping (HBRequest, Context) async throws -> Output
    ) -> Self {
        let responder = constructResponder(options: options, use: closure)
        let path = self.combinePaths(self.path, path)
        self.router.add(path, method: method, responder: self.middlewares.constructResponder(finalResponder: responder))
        return self
    }

    internal func combinePaths(_ path1: String, _ path2: String) -> String {
        let path1 = path1.dropSuffix("/")
        let path2 = path2.dropPrefix("/")
        return "\(path1)/\(path2)"
    }
}
