// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsTruncateTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_truncate_basic() public pure {
        bytes memory subject = "hello world";
        bytes memory result = BytesUtils.truncate(subject, 5);

        uint256 subjectPtr;
        uint256 resultPtr;
        assembly ("memory-safe") {
            subjectPtr := subject
            resultPtr := result
        }

        assertEq(resultPtr, subjectPtr);
        assertEq(subject, "hello");
    }

    function test_truncate_exactLength_noOp() public pure {
        assertEq(BytesUtils.truncate("abc", 3), "abc");
        assertEq(BytesUtils.truncate("hello", 5), "hello");
    }

    function test_truncate_beyondLength_noOp() public pure {
        assertEq(BytesUtils.truncate("abc", 4), "abc");
        assertEq(BytesUtils.truncate("abc", type(uint256).max), "abc");
        assertEq(BytesUtils.truncate("hello", 6), "hello");
        assertEq(BytesUtils.truncate("hello", type(uint256).max), "hello");
    }

    function test_truncate_maxLength_noOp() public pure {
        assertEq(BytesUtils.truncate("abc", type(uint256).max), "abc");
        assertEq(BytesUtils.truncate("hello", type(uint256).max), "hello");
    }

    function test_truncate_zeroLength() public pure {
        assertEq(BytesUtils.truncate("abcd", 0), "");
    }

    function test_truncate_emptySubject_noOp() public pure {
        assertEq(BytesUtils.truncate("", 0), "");
        assertEq(BytesUtils.truncate("", 5), "");
    }

    function test_truncate_singleChar() public pure {
        assertEq(BytesUtils.truncate("abc", 1), "a");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_truncate_idempotent(bytes memory subject, uint256 length) public pure {
        bytes memory once = BytesUtils.truncate(subject, length);
        assertEq(BytesUtils.truncate(once, length), once, "repeated truncation changed result");
    }

    function test_fuzz_truncate_isLeadingSlice(bytes memory subject, uint256 length) public pure {
        bytes memory expected = BytesUtils.slice(subject, 0, length);
        bytes memory result = BytesUtils.truncate(subject, length);
        assertEq(result, expected, "truncated result differs from leading slice");
    }

    function test_fuzz_truncate_lengthBound(bytes memory subject, uint256 length) public pure {
        uint256 expectedLength = min(length, bytes(subject).length);
        bytes memory result = BytesUtils.truncate(subject, length);
        assertEq(result.length, expectedLength, "truncated length is incorrect");
    }

    function test_fuzz_truncate_prefixPreserved(bytes memory subject, uint256 length) public pure {
        length = bound(length, 0, bytes(subject).length);
        bytes memory expected = BytesUtils.slice(subject, 0, length);
        bytes memory result = BytesUtils.truncate(subject, length);
        assertEq(result, expected, "truncation did not preserve leading bytes");
    }

    function test_fuzz_truncate_beyondLength_noOp(bytes memory subject, uint256 length) public pure {
        length = bound(length, bytes(subject).length, type(uint256).max);
        assertEq(BytesUtils.truncate(subject, length), subject, "oversized truncation changed subject");
    }

    function test_fuzz_truncate(bytes calldata subject, uint256 length) public pure {
        uint256 expectedLength = min(length, bytes(subject).length);
        bytes memory result = BytesUtils.truncate(subject, length);

        assertEq(result.length, expectedLength, "truncated length is incorrect");
        assertEq(result, subject[:expectedLength], "truncated content is incorrect");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_truncate_differential(bytes memory subject, uint256 length) public pure {
        bytes memory expected = referenceTruncate(subject, length);
        bytes memory result = BytesUtils.truncate(subject, length);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceTruncate(bytes memory subject, uint256 length) internal pure returns (bytes memory result) {
        if (length >= subject.length) return subject;

        result = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = subject[i];
        }
    }
}
