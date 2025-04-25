// Shared file between iOS and Mac OS
// make sure they stay in sync.

import Foundation
import LocalAuthentication

typealias StorageCallback = (Any?) -> Void
typealias StorageError = (String, String?, Any?) -> Any

struct StorageMethodCall {
  let method: String
  let arguments: Any?
}

class InitOptions {
  init(params: [String: Any]) {
    darwinTouchIDAuthenticationAllowableReuseDuration = params["drawinTouchIDAuthenticationAllowableReuseDurationSeconds"] as? Int
    darwinTouchIDAuthenticationForceReuseContextDuration = params["darwinTouchIDAuthenticationForceReuseContextDurationSeconds"] as? Int
    authenticationRequired = params["authenticationRequired"] as? Bool
    darwinBiometricOnly = params["darwinBiometricOnly"] as? Bool
  }
  let darwinTouchIDAuthenticationAllowableReuseDuration: Int?
  let darwinTouchIDAuthenticationForceReuseContextDuration: Int?
  let authenticationRequired: Bool!
  let darwinBiometricOnly: Bool!
}

class IOSPromptInfo {
  init(params: [String: Any]) {
    saveTitle = params["saveTitle"] as? String
    accessTitle = params["accessTitle"] as? String
  }
  let saveTitle: String!
  let accessTitle: String!
}

private func hpdebug(_ message: String) {
  print(message);
}

class BiometricStorageImpl {
  
  init(storageError: @escaping StorageError, storageMethodNotImplemented: Any) {
    self.storageError = storageError
    self.storageMethodNotImplemented = storageMethodNotImplemented
  }
  
  private var stores: [String: BiometricStorageFile] = [:]
  private let storageError: StorageError
  private let storageMethodNotImplemented: Any

  private func storageError(code: String, message: String?, details: Any?) -> Any {
    return storageError(code, message, details)
  }

  public func handle(_ call: StorageMethodCall, result: @escaping StorageCallback) {
    
    func requiredArg<T>(_ name: String, _ cb: (T) -> Void) {
      guard let args = call.arguments as? Dictionary<String, Any> else {
        result(storageError(code: "InvalidArguments", message: "Invalid arguments \(String(describing: call.arguments))", details: nil))
        return
      }
      guard let value = args[name] else {
        result(storageError(code: "InvalidArguments", message: "Missing argument \(name)", details: nil))
        return
      }
      guard let valueTyped = value as? T else {
        result(storageError(code: "InvalidArguments", message: "Invalid argument for \(name): expected \(T.self) got \(value)", details: nil))
        return
      }
      cb(valueTyped)
      return
    }
    func requireStorage(_ name: String, _ cb: (BiometricStorageFile) -> Void) {
      guard let file = stores[name] else {
        result(storageError(code: "InvalidArguments", message: "Storage was not initialized \(name)", details: nil))
        return
      }
      cb(file)
    }
    
    if ("canAuthenticate" == call.method) {
      canAuthenticate(result: result)
    } else if ("init" == call.method) {
      requiredArg("name") { name in
        requiredArg("options") { options in
          stores[name] = BiometricStorageFile(name: name, initOptions: InitOptions(params: options), storageError: storageError)
        }
      }
      result(true)
    } else if ("dispose" == call.method) {
      // nothing to dispose
      result(true)
    } else if ("read" == call.method) {
      requiredArg("name") { name in
        requiredArg("iosPromptInfo") { promptInfo in
          requireStorage(name) { file in
            file.read(result, IOSPromptInfo(params: promptInfo))
          }
        }
      }
    } else if ("write" == call.method) {
      requiredArg("name") { name in
        requiredArg("content") { content in
          requiredArg("iosPromptInfo") { promptInfo in
            requireStorage(name) { file in
              file.write(content, result, IOSPromptInfo(params: promptInfo))
            }
          }
        }
      }
    } else if ("delete" == call.method) {
      requiredArg("name") { name in
        requiredArg("iosPromptInfo") { promptInfo in
          requireStorage(name) { file in
            file.delete(result, IOSPromptInfo(params: promptInfo))
          }
        }
      }
    } else {
      result(storageMethodNotImplemented)
    }
  }
  

  private func canAuthenticate(result: @escaping StorageCallback) {
    var error: NSError?
    let context = LAContext()
    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
      result("Success")
      return
    }
    guard let err = error else {
      result("ErrorUnknown")
      return
    }
    let laError = LAError(_nsError: err)
    NSLog("LAError: \(laError)");
    switch laError.code {
    case .touchIDNotAvailable:
      result("ErrorHwUnavailable")
      break;
    case .passcodeNotSet:
      result("ErrorPasscodeNotSet")
      break;
    case .touchIDNotEnrolled:
      result("ErrorNoBiometricEnrolled")
      break;
    case .invalidContext: fallthrough
    default:
      result("ErrorUnknown")
      break;
    }
  }
}

typealias StoredContext = (context: LAContext, expireAt: Date)

class BiometricStorageFile {
  private let name: String
  private let initOptions: InitOptions
  private var _context: StoredContext?
  private var context: LAContext {
    get {
      if let context = _context {
        if context.expireAt.timeIntervalSinceNow < 0 {
          // already expired.
          _context = nil
        } else {
          return context.context
        }
      }
      
      let context = LAContext()
      if (initOptions.authenticationRequired) {
        if let duration = initOptions.darwinTouchIDAuthenticationAllowableReuseDuration {
          if #available(OSX 10.12, *) {
            context.touchIDAuthenticationAllowableReuseDuration = Double(duration)
          } else {
            // Fallback on earlier versions
            hpdebug("Pre OSX 10.12 no touchIDAuthenticationAllowableReuseDuration available. ignoring.")
          }
        }
        
        if let duration = initOptions.darwinTouchIDAuthenticationForceReuseContextDuration {
          _context = (context: context, expireAt: Date(timeIntervalSinceNow: Double(duration)))
        }
      }
      return context
    }
  }
  private let storageError: StorageError

  init(name: String, initOptions: InitOptions, storageError: @escaping StorageError) {
    self.name = name
    self.initOptions = initOptions
    self.storageError = storageError
  }
  
  private func baseQuery(_ result: @escaping StorageCallback) -> [String: Any]? {
    var query = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "flutter_biometric_storage",
      kSecAttrAccount as String: name,
    ] as [String : Any]
    if initOptions.authenticationRequired {
      guard let access = accessControl(result) else {
        return nil
      }
      if #available(iOS 13.0, macOS 10.15, *) {
        query[kSecUseDataProtectionKeychain as String] = true
      }
      query[kSecAttrAccessControl as String] = access
    }
    return query
  }
  
  private func accessControl(_ result: @escaping StorageCallback) -> SecAccessControl? {
    let accessControlFlags: SecAccessControlCreateFlags
    
    if initOptions.darwinBiometricOnly {
      if #available(iOS 11.3, *) {
        accessControlFlags =  .biometryCurrentSet
      } else {
        accessControlFlags = .touchIDCurrentSet
      }
    } else {
      accessControlFlags = .userPresence
    }
        
//      access = SecAccessControlCreateWithFlags(nil,
//                                               kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
//                                               accessControlFlags,
//                                               &error)
    var error: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
      nil, // Use the default allocator.
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
      accessControlFlags,
      &error) else {
      hpdebug("Error while creating access control flags. \(String(describing: error))")
      result(storageError("writing data", "error writing data", "\(String(describing: error))"));
      return nil
    }

    return access
  }
  
  func read(_ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo) {

    guard var query = baseQuery(result) else {
      return;
    }
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecUseOperationPrompt as String] = promptInfo.accessTitle
    query[kSecReturnAttributes as String] = true
    query[kSecReturnData as String] = true
    query[kSecUseAuthenticationContext as String] = context
    
    var item: CFTypeRef?
    
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else {
      result(nil)
      return
    }
    guard status == errSecSuccess else {
      handleOSStatusError(status, result, "Error retrieving item. \(status)")
      return
    }
    guard let existingItem = item as? [String : Any],
      let data = existingItem[kSecValueData as String] as? Data,
      let dataString = String(data: data, encoding: String.Encoding.utf8)
      else {
        result(storageError("RetrieveError", "Unexpected data.", nil))
        return
    }
    result(dataString)
  }
  
  func delete(_ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo) {
    guard let query = baseQuery(result) else {
      return;
    }
    //    query[kSecMatchLimit as String] = kSecMatchLimitOne
    //    query[kSecReturnData as String] = true
    let status = SecItemDelete(query as CFDictionary)
    if status == errSecSuccess {
      result(true)
      return
    }
    if status == errSecItemNotFound {
      hpdebug("Item not in keychain. Nothing to delete.")
      result(true)
      return
    }
    handleOSStatusError(status, result, "writing data")
  }
  
  func write(_ content: String, _ result: @escaping StorageCallback, _ promptInfo: IOSPromptInfo) {
    guard var query = baseQuery(result) else {
      return;
    }

    if (initOptions.authenticationRequired) {
      query.merge([
        kSecUseAuthenticationContext as String: context,
      ]) { (_, new) in new }
      if let operationPrompt = promptInfo.saveTitle {
        query[kSecUseOperationPrompt as String] = operationPrompt
      }
    } else {
      hpdebug("No authentication required for \(name)")
    }
    query.merge([
      //      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecValueData as String: content.data(using: String.Encoding.utf8) as Any,
    ]) { (_, new) in new }
    var status = SecItemAdd(query as CFDictionary, nil)
    if (status == errSecDuplicateItem) {
      hpdebug("Value already exists. updating.")
      let update = [kSecValueData as String: query[kSecValueData as String]]
      query.removeValue(forKey: kSecValueData as String)
      status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
    }
    guard status == errSecSuccess else {
      handleOSStatusError(status, result, "writing data")
      return
    }
    result(nil)
  }
  
  private func handleOSStatusError(_ status: OSStatus, _ result: @escaping StorageCallback, _ message: String) {
    var errorMessage: String? = nil
    if #available(iOS 11.3, OSX 10.12, *) {
      errorMessage = SecCopyErrorMessageString(status, nil) as String?
    }
    let code: String
    switch status {
    case errSecUserCanceled:
      code = "AuthError:UserCanceled"
    default:
      code = "SecurityError"
    }
    
    result(storageError(code, "Error while \(message): \(status): \(errorMessage ?? "Unknown")", nil))
  }
  
}
