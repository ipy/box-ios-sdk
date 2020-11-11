//
// Created by Sin on 2020/11/13.
// Copyright (c) 2020 box. All rights reserved.
//

import Foundation

/// Token store that uses the Apple keychain
public class MultiUserKeychainTokenStore: TokenStore {
    private let tokenInfoKeychainKeyPrefix = "TokenInfo"
    private var userId: String? = nil
    private var tokenInfoKeychainKey: String {
        userId == nil ? "" : "\(tokenInfoKeychainKeyPrefix).\(userId!)"
    }
    let secureStore = KeychainService(secureStoreQueryable: GenericPasswordQueryable(service: "com.box.SwiftSDK"))

    /// Initializer method
    public init(userId: String?) {
        self.userId = userId
    }

    public func read(completion: @escaping (Result<TokenInfo, Error>) -> Void) {
        do {
            guard tokenInfoKeychainKey != "" else {
                completion(.failure(BoxSDKError(message: .keychainNoValue)))
                return
            }
            guard let tokenInfo: TokenInfo = try? secureStore.getValue(tokenInfoKeychainKey) else {
                completion(.failure(BoxSDKError(message: .keychainNoValue)))
                return
            }
            completion(.success(tokenInfo))
        }
    }

    public func readSync() -> TokenInfo? {
        do {
            guard tokenInfoKeychainKey != "" else {
                return nil
            }
            guard let tokenInfo: TokenInfo = try? secureStore.getValue(tokenInfoKeychainKey) else {
                return nil
            }
            return tokenInfo
        }
    }

    public func writeToken(tokenInfo: TokenInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        guard tokenInfoKeychainKey != "" else {
            completion(.failure(BoxSDKError(message: "invalid userId")))
            return
        }
        do {
            try secureStore.set(tokenInfo, key: tokenInfoKeychainKey)
            completion(.success(()))
        } catch let error as BoxSDKError {
            completion(.failure(error))
        } catch {
            completion(.failure(BoxSDKError(message: .keychainUnhandledError("Cannot write to keychain"))))
        }
    }

    public func write(tokenInfo: TokenInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        if userId == nil {
            let sdk = BoxSDK.getClient(token: tokenInfo.accessToken)
            sdk.users.getCurrent { result in
                switch result {
                case .success(let user):
                    self.userId = user.id
                    self.writeToken(tokenInfo: tokenInfo, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            writeToken(tokenInfo: tokenInfo, completion: completion)
        }
    }

    public func clear(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard tokenInfoKeychainKey != "" else {
                return
            }
            try secureStore.removeValue(for: tokenInfoKeychainKey)
            completion(.success(()))
        } catch let error as BoxSDKError {
            completion(.failure(error))
        } catch {
            completion(.failure(BoxSDKError(message: .keychainUnhandledError("Cannot clear keychain"))))
        }
    }
}
