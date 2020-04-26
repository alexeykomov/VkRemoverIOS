//
//  BGTaskPerformerTests.swift
//  VkRemoverIOSTests
//
//  Created by Alex K on 4/24/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import XCTest

class BGTaskPerformerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testFormCodeFromOperations() {
        let state = SchedulerState(operations: [OperationType.accountBan:[Operation(name: .accountBan, paramName: .ownerId, user: RequestEntry(userId: 200, photoForList: "some-photo-url", firstName: "Alex", lastName: "Yes"))]])
        let code = formCodeFromOperations(state: state).code
        XCTAssertEqual(code, "var a = API.account.ban({'owner_id': 200});")
    }
    
    func testFormCodeFromOperationsDifferentOperations() {
        let state = SchedulerState(operations: [OperationType.accountBan:[
            Operation(name: .accountBan, paramName: .ownerId, user: RequestEntry(userId: 200, photoForList: "some-photo-url", firstName: "Alex", lastName: "Yes"))],
            OperationType.accountUnban:[Operation(name: .accountUnban, paramName: .ownerId, user: RequestEntry(userId: 200, photoForList: "some-photo-url", firstName: "Alex", lastName: "Yes"))],
            OperationType.friendsDelete:[Operation(name: .friendsDelete, paramName: .userId, user: RequestEntry(userId: 200, photoForList: "some-photo-url", firstName: "Alex", lastName: "Yes"))]
            ])
        let code = formCodeFromOperations(state: state).code
        XCTAssertTrue(code.contains("API.account.ban({'owner_id': 200});"))
        XCTAssertTrue(code.contains("API.account.unban({'owner_id': 200});"))
        XCTAssertTrue(code.contains("API.friends.delete({'user_id': 200});"))
    }
    
    func testFormCodeFromOperationLarge() {
        
        var operations:Array<Operation> = []
        for _ in 0..<100 {
            operations.append(Operation(name: .accountBan, paramName: .ownerId, user: RequestEntry(userId: 200, photoForList: "some-photo-url", firstName: "Alex", lastName: "Yes")))
    
        }
        
        let state = SchedulerState(operations: [OperationType.accountBan:operations])
        let codeWithState = formCodeFromOperations(state: state)
        let code = formCodeFromOperations(state: state).code
        let stateWithoutOperationsThatAreInCode =
            codeWithState.stateWithoutOperationsThatAreInCode
        
        XCTAssertEqual(code,
                        """
                        var a = API.account.ban({'owner_id': 200});
                        var b = API.account.ban({'owner_id': 200});
                        var c = API.account.ban({'owner_id': 200});
                        var d = API.account.ban({'owner_id': 200});
                        var e = API.account.ban({'owner_id': 200});
                        var f = API.account.ban({'owner_id': 200});
                        var g = API.account.ban({'owner_id': 200});
                        var h = API.account.ban({'owner_id': 200});
                        var i = API.account.ban({'owner_id': 200});
                        var j = API.account.ban({'owner_id': 200});
                        var k = API.account.ban({'owner_id': 200});
                        var l = API.account.ban({'owner_id': 200});
                        var m = API.account.ban({'owner_id': 200});
                        var n = API.account.ban({'owner_id': 200});
                        var o = API.account.ban({'owner_id': 200});
                        var p = API.account.ban({'owner_id': 200});
                        var q = API.account.ban({'owner_id': 200});
                        var r = API.account.ban({'owner_id': 200});
                        var s = API.account.ban({'owner_id': 200});
                        var t = API.account.ban({'owner_id': 200});
                        var u = API.account.ban({'owner_id': 200});
                        var v = API.account.ban({'owner_id': 200});
                        var w = API.account.ban({'owner_id': 200});
                        var x = API.account.ban({'owner_id': 200});
                        var y = API.account.ban({'owner_id': 200});
                        """)
    }
    
    func testForCodeFromOperationsReducedState() {
        var operations: Array<Operation> = []
        for _ in 0..<100 {
            operations.append(Operation(name: .accountBan, paramName: .ownerId,
                                        user: RequestEntry(userId: 200, photoForList: "some-photo-url",
                                                           firstName: "Alex", lastName: "Yes")))
        }
        let state = SchedulerState(operations: [OperationType.accountBan:operations])
        let codeWithState = formCodeFromOperations(state: state)
        let stateWithoutOperationsThatAreInCode = codeWithState.stateWithoutOperationsThatAreInCode
        
        XCTAssertEqual((stateWithoutOperationsThatAreInCode.operations[.accountBan] ?? []).count, 75)
    }
}
