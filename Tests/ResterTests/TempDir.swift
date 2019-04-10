//
//  TempDir.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 10/04/2019.
//

import Foundation
import Path


enum TempDirError: Error {
    case invalidPath(String)
}


class TempDir {
    let path: Path

    init() throws {
        let tempDir = NSTemporaryDirectory()
        guard let temp = Path(tempDir) else {
            throw TempDirError.invalidPath(tempDir)
        }
        self.path = try temp.join(UUID().uuidString).mkdir()
    }

    deinit {
        do {
            try path.chmod(0o777).delete()
        } catch {
            print("⚠️ failed to delete temp directory: \(error.legibleLocalizedDescription)")
        }
    }

}


func withTempDir<T>(body: (Path) throws -> T) throws -> T {
    let tmp = try TempDir()
    return try body(tmp.path)
}
