//
//  TestAppGroup.swift
//  Intently
//
//  Test file to verify App Group is working
//

import Foundation

func testAppGroupAccess() {
    let appGroupID = "group.dev.sadakat.intently"

    guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
        print("❌ FAILED: Cannot access App Group '\(appGroupID)'")
        print("   This means the App Group is not registered or not in your entitlements")
        return
    }

    // Try to write test data
    let testKey = "appgroup_test"
    let testValue = "App Group is working! ✅"
    sharedDefaults.set(testValue, forKey: testKey)
    sharedDefaults.synchronize()

    // Try to read it back
    if let readValue = sharedDefaults.string(forKey: testKey), readValue == testValue {
        print("✅ SUCCESS: App Group '\(appGroupID)' is working correctly!")
        print("   Data can be shared between main app and extension")

        // Clean up
        sharedDefaults.removeObject(forKey: testKey)
    } else {
        print("⚠️ WARNING: App Group accessible but data not persisting")
    }
}
