//
//  Cache.swift
//  CacheDemo
//
//  Created by Nguyen Cong Huy on 7/4/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//
// swiftlint:disable force_unwrapping

import UIKit

class Cache {
  private static let documentDirectoryPrefix = "com.superwall.document.Store"
  private static let cacheDirectoryPrefix = "com.superwall.cache.Store"
  private static let ioQueuePrefix = "com.superwall.queue.Store"
  private static let defaultMaxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7 // a week
  private let cacheUrl: URL
  private let documentUrl: URL
  private let memCache = NSCache<AnyObject, AnyObject>()
  private let ioQueue: DispatchQueue
  private let fileManager: FileManager

  /// Life time of disk cache, in second. Default is a week
  private var maxCachePeriodInSecond = Cache.defaultMaxCachePeriodInSecond

  /// Size is allocated for disk cache, in byte. 0 mean no limit. Default is 0
  private var maxDiskCacheSize: UInt = 0

  /// Specify distinc name param, it represents folder name for disk cache
  init(ioQueue: DispatchQueue = DispatchQueue(label: Cache.ioQueuePrefix)) {
    fileManager = FileManager()
    cacheUrl = fileManager
      .urls(for: .cachesDirectory, in: .userDomainMask)
      .first!
      .appendingPathComponent(Cache.cacheDirectoryPrefix)
    documentUrl = fileManager
      .urls(for: .documentDirectory, in: .userDomainMask)
      .first!
      .appendingPathComponent(Cache.documentDirectoryPrefix)

    self.ioQueue = ioQueue

    #if !os(OSX) && !os(watchOS)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(cleanExpiredDiskCache),
        name: UIApplication.willTerminateNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(cleanExpiredDiskCache),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil
      )
    #endif
  }

  // MARK: - Store data
  
  /// Read data for key
  func read<Key: Storable>(
    _ keyType: Key.Type,
    fromDirectory directory: SearchPathDirectory? = nil
  ) -> Key.Value? where Key.Value: Decodable {
    var data = memCache.object(forKey: keyType.key as AnyObject) as? Data
    let directory = directory ?? keyType.directory
    let path = cachePath(
      forKey: keyType.key,
      directory: directory
    )
    if data == nil,
      let dataFromDisk = fileManager.contents(atPath: path) {
      data = dataFromDisk
      memCache.setObject(dataFromDisk as AnyObject, forKey: keyType.key as AnyObject)
    }
    guard let data = data else {
      return nil
    }

    guard let data = NSKeyedUnarchiver.unarchiveObject(with: data) as? Data else {
      return nil
    }
    do {
      return try JSONDecoder().decode(Key.Value.self, from: data)
    } catch {
      return nil
    }
  }

  /// Read data for key
  func read<Key: Storable>(
    _ keyType: Key.Type,
    fromDirectory directory: SearchPathDirectory? = nil
  ) -> Key.Value? {
    var data = memCache.object(forKey: keyType.key as AnyObject) as? Data
    let directory = directory ?? keyType.directory
    let path = cachePath(
      forKey: keyType.key,
      directory: directory
    )
    if data == nil,
      let dataFromDisk = fileManager.contents(atPath: path) {
      data = dataFromDisk
      memCache.setObject(dataFromDisk as AnyObject, forKey: keyType.key as AnyObject)
    }

    if let data = data {
      return NSKeyedUnarchiver.unarchiveObject(with: data) as? Key.Value
    }
    return nil
  }

  func delete<Key: Storable>(
    _ keyType: Key.Type,
    fromDirectory directory: SearchPathDirectory? = nil
  ) {
    memCache.removeObject(forKey: keyType.key as AnyObject)
    deleteDataFromDisk(
      withKey: keyType.key,
      fromDirectory: directory ?? keyType.directory
    )
  }

  /// Write data for key. This is an async operation.
  ///
  /// - Parameters:
  ///   - value: The data to write.
  ///   - keyType: The `Storable` type that you want to store.
  ///   - directory: The directory that you want to save to. This should only be used when migrating data, for all other instances, leave this as `nil` to fallback to the directory specified by the type.
  func write<Key: Storable>(
    _ value: Key.Value,
    forType keyType: Key.Type,
    inDirectory directory: SearchPathDirectory? = nil
  ) {
    guard let value = value as? NSCoding else {
      return
    }

    let data = NSKeyedArchiver.archivedData(withRootObject: value)
    memCache.setObject(data as AnyObject, forKey: keyType.key as AnyObject)

    writeDataToDisk(
      data: data,
      key: keyType.key,
      toDirectory: directory ?? keyType.directory
    )
  }

  /// Write data for key. This is an async operation.
  /// - Parameters:
  ///   - value: The data to write.
  ///   - keyType: The `Storable` type that you want to store.
  ///   - directory: The directory that you want to save to. This should only be used when migrating data, for all other instances, leave this as `nil` to fallback to the directory specified by the type.
  func write<Key: Storable>(
    _ value: Key.Value,
    forType keyType: Key.Type,
    inDirectory directory: SearchPathDirectory? = nil
  ) where Key.Value: Encodable {
    guard let data = try? JSONEncoder().encode(value) else {
      return
    }

    let archivedData = NSKeyedArchiver.archivedData(withRootObject: data)
    memCache.setObject(archivedData as AnyObject, forKey: keyType.key as AnyObject)

    writeDataToDisk(
      data: archivedData,
      key: keyType.key,
      toDirectory: directory ?? keyType.directory
    )
  }

  private func writeDataToDisk(
    data: Data,
    key: String,
    toDirectory directory: SearchPathDirectory
  ) {
    ioQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      let directoryUrl = self.getDirectoryUrl(from: directory)
      if self.fileManager.fileExists(atPath: directoryUrl.path) == false {
        do {
          try self.fileManager.createDirectory(
            atPath: self.cacheUrl.path,
            withIntermediateDirectories: true,
            attributes: nil
          )
        } catch {
          Logger.debug(
            logLevel: .error,
            scope: .cache,
            message: "Error while creating cache folder: \(error.localizedDescription)"
          )
        }
      }

      let path = self.cachePath(
        forKey: key,
        directory: directory
      )
      self.fileManager.createFile(
        atPath: path,
        contents: data
      )
    }
  }

  private func deleteDataFromDisk(
    withKey key: String,
    fromDirectory directory: SearchPathDirectory
  ) {
    ioQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      do {
        let path = self.cachePath(
          forKey: key,
          directory: directory
        )
        try self.fileManager.removeItem(atPath: path)
      } catch {
        Logger.debug(
          logLevel: .error,
          scope: .cache,
          message: "Error while deleting file: \(error.localizedDescription)"
        )
      }
    }
  }
}

// MARK: - Clean
extension Cache {
  /// Clean all mem cache and disk cache. This is an async operation.
  func cleanAll() {
    cleanMemCache()
    cleanDiskCache()
  }

  private func cleanMemCache() {
    memCache.removeAllObjects()
  }

  private func cleanDiskCache() {
    ioQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      do {
        try self.fileManager.removeItem(atPath: self.cacheUrl.path)
        try self.fileManager.removeItem(atPath: self.documentUrl.path)
      } catch {
        Logger.debug(
          logLevel: .error,
          scope: .cache,
          message: "Error when clean disk: \(error.localizedDescription)"
        )
      }
    }
  }

  // This method is from Kingfisher
  /**
    Clean expired disk cache. This is an async operation.

    - parameter completionHandler: Called after the operation completes.
  */
  @objc private func cleanExpiredDiskCache() {
    // Do things in cocurrent io queue
    ioQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles()

      for fileURL in URLsToDelete {
        do {
          try self.fileManager.removeItem(at: fileURL)
        } catch {
          Logger.debug(
            logLevel: .error,
            scope: .cache,
            message: "Error while removing files \(error.localizedDescription)"
          )
        }
      }

      if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
        let targetSize = self.maxDiskCacheSize / 2

        // Sort files by last modify date. We want to clean from the oldest files.
        let sortedFiles = cachedFiles.keysSortedByValue { resourceValue1, resourceValue2 -> Bool in
          if let date1 = resourceValue1.contentAccessDate,
            let date2 = resourceValue2.contentAccessDate {
            return date1.compare(date2) == .orderedAscending
          }

          // Not valid date information. This should not happen. Just in case.
          return true
        }

        for fileURL in sortedFiles {
          do {
            try self.fileManager.removeItem(at: fileURL)
          } catch {
            Logger.debug(
              logLevel: .error,
              scope: .cache,
              message: "Error while removing files \(error.localizedDescription)"
            )
          }

          URLsToDelete.append(fileURL)

          if let fileSize = cachedFiles[fileURL]?.totalFileAllocatedSize {
            diskCacheSize -= UInt(fileSize)
          }

          if diskCacheSize < targetSize {
            break
          }
        }
      }
    }
  }
}

// MARK: - Helpers
extension Cache {
  // This method is from Kingfisher
  // swiftlint:disable all
  fileprivate func travelCachedFiles() -> (urlsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: URLResourceValues]) {
    let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]
    let expiredDate: Date? = (maxCachePeriodInSecond < 0) ? nil : Date(timeIntervalSinceNow: -maxCachePeriodInSecond)

    var cachedFiles: [URL: URLResourceValues] = [:]
    var urlsToDelete: [URL] = []
    var diskCacheSize: UInt = 0

    func traverse(url: URL) {
      for fileUrl in (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? [] {
          do {
            let resourceValues = try fileUrl.resourceValues(forKeys: resourceKeys)
            // If it is a Directory. Continue to next file URL.
            if resourceValues.isDirectory == true {
                continue
            }

            // If this file is expired, add it to URLsToDelete
            if let expiredDate = expiredDate,
              let lastAccessData = resourceValues.contentAccessDate,
              (lastAccessData as NSDate).laterDate(expiredDate) == expiredDate {
              urlsToDelete.append(fileUrl)
              continue
            }

            if let fileSize = resourceValues.totalFileAllocatedSize {
              diskCacheSize += UInt(fileSize)
              cachedFiles[fileUrl] = resourceValues
            }
        } catch {
          Logger.debug(
            logLevel: .error,
            scope: .cache,
            message: "Error while iterating files \(error.localizedDescription)"
          )
        }
      }
    }

    traverse(url: cacheUrl)
    traverse(url: documentUrl)

    return (urlsToDelete, diskCacheSize, cachedFiles)
  }

  func cachePath(
    forKey key: String,
    directory: SearchPathDirectory
  ) -> String {
    let fileName = key.md5
    let directoryUrl = getDirectoryUrl(from: directory)
    return directoryUrl.appendingPathComponent(fileName).path
  }

  private func getDirectoryUrl(from directory: SearchPathDirectory) -> URL {
    switch directory {
    case .cache:
      return cacheUrl
    case .documents:
      return documentUrl
    }
  }
}
