//
//  MigratorTests.swift
//  Migrator
//
//  Created by 酒井篤 on 2015/09/13.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import Migrator

// Mocking
class MigratorMock : Migrator  {
    override func currentVersion() -> String {
        return "1.0.0"
    }
}

class MigratorTests: XCTestCase, MigratorProtocol {
    
    let migrator: Migrator = Migrator()

    override func setUp() {
        super.setUp()
        migrator.reset()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testLastMigratedVersionIsEmpty() {
        let lastVer = migrator.lastMigratedVersion()
        XCTAssertTrue(lastVer == "")
    }
    
    func testLastMigratedVersionIsSaved() {
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject("1.0.0", forKey: "com.radioboo.migratorLastVersionKey")
        defaults.synchronize()
        
        XCTAssertTrue(migrator.lastMigratedVersion() == "1.0.0")
    }
    
    func testInitialVersionIsSaved() {
        migrator.setInitialVersion("2.0.0")
        XCTAssertTrue(migrator.lastMigratedVersion() == "2.0.0")

        migrator.setInitialVersion("4.0.0")
        XCTAssertTrue(migrator.lastMigratedVersion() == "2.0.0")
    }
    
    func testShouldMigrateIsFalseBecauseEqual() {
        let migratorMock: MigratorMock = MigratorMock()
        migratorMock.setInitialVersion("0.0.9")
        XCTAssertFalse(migratorMock.shouldMigrate() == true)
    }

    func testShouldMigrateIsFalseBecauseLess() {
        let migratorMock: MigratorMock = MigratorMock()
        migratorMock.setInitialVersion("1.0.0")
        XCTAssertFalse(migratorMock.shouldMigrate() == true)
    }
    func testShouldMigrate() {
        let migratorMock: MigratorMock = MigratorMock()
        migratorMock.setInitialVersion("1.0.1")
        XCTAssertTrue(migratorMock.shouldMigrate() == true)
    }
    
    // MARK: Migrate Tests

    func testSuccessedMigrate() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("0.9.0")
        
        var migrated: Bool = false;
        migratorMock.registerHandler("1.0.0", migration: { () -> () in migrated = true })
        migratorMock.migrate()
        XCTAssertTrue(migrated == true)
        XCTAssertTrue(migratorMock.lastMigratedVersion() == "1.0.0")
    }

    func testFailedMigrateReasonThatLastMigratedVersionEqualToTargerVerion() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("1.0.0")
        
        var migrated: Bool = false;
        migratorMock.registerHandler("1.0.0", migration: { () -> () in migrated = true })
        migratorMock.migrate()
        XCTAssertTrue(migrated == false)
        XCTAssertTrue(migratorMock.lastMigratedVersion() == "1.0.0")
    }

    func testFailedMigratedReasonThatTargetVersionIsLessThanLastMigrated() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("0.9.0")
        
        var migrated: Bool = false;
        migratorMock.registerHandler("0.8.0", migration: { () -> () in migrated = true })
        migratorMock.migrate()
        XCTAssertTrue(migrated == false)
        XCTAssertTrue(migratorMock.lastMigratedVersion() == "0.9.0")
    }

    func testFailedMigratedReasonThatTargetVersionIsGreaterThanCurrentVersion() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("1.0.0")

        var migrated: Bool = false;
        migratorMock.registerHandler("1.0.1", migration: { () -> () in migrated = true })
        migratorMock.migrate()
        XCTAssertTrue(migrated == false)

        XCTAssertTrue(migratorMock.lastMigratedVersion() == "1.0.0")
    }

    // MARK: Multiple Migrate

    func testMultipleMigration() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("0.8.0")

        var migrated_0_8_1: Bool = false;
        var migrated_0_9_0: Bool = false;
        var migrated_1_0_0: Bool = false;
        var migrated_1_0_1: Bool = false;

        migratorMock.registerHandler("0.8.1", migration: { () -> () in migrated_0_8_1 = true })
        migratorMock.registerHandler("0.9.0", migration: { () -> () in migrated_0_9_0 = true })
        migratorMock.registerHandler("1.0.0", migration: { () -> () in migrated_1_0_0 = true })
        migratorMock.registerHandler("1.0.1", migration: { () -> () in migrated_1_0_1 = true })

        migratorMock.migrate()

        XCTAssertTrue(migrated_0_8_1 == true)
        XCTAssertTrue(migrated_0_9_0 == true)
        XCTAssertTrue(migrated_1_0_0 == true)
        XCTAssertFalse(migrated_1_0_1 == true)

        XCTAssertTrue(migratorMock.lastMigratedVersion() == "1.0.0")
    }

    // MARK: Delegate

    func testSuccessedMigrateDelegate() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("0.9.0")

        var migrated: Bool = false;
        migratorMock.registerHandler("1.0.0", migration: { () -> () in migrated = true })
        migratorMock.delegate = self
        migratorMock.migrate()
        XCTAssertTrue(migrated == true)
        XCTAssertTrue(migratorMock.lastMigratedVersion() == "1.0.0")
    }

    enum TestError: ErrorType {
        case UnexpectedError
    }

    func testFailedMigrateDelegate() {
        let migratorMock: MigratorMock = MigratorMock()

        migratorMock.setInitialVersion("0.9.0")
        migratorMock.registerHandler("1.0.0", migration: { () throws -> () in throw TestError.UnexpectedError })
        migratorMock.delegate = self
        migratorMock.migrate()
    }


    func didSucceededMigration(migratedVersion: String) {
        XCTAssertTrue(migratedVersion == "1.0.0")
    }
    
    func didFailedMigration(migratedVersion: String, error: ErrorType) {
        XCTAssertTrue(error is TestError)
        XCTAssertTrue(migratedVersion == "1.0.0")
    }
    
    func didCompletedAllMigration() {
    }
}
