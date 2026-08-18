// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsTruncateTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_truncate_basic() public pure {
        string memory subject = "hello world";
        string memory result = StringUtils.truncate(subject, 5);

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
        assertEq(StringUtils.truncate("abc", 3), "abc");
        assertEq(StringUtils.truncate("hello", 5), "hello");
    }

    function test_truncate_beyondLength_noOp() public pure {
        assertEq(StringUtils.truncate("abc", 4), "abc");
        assertEq(StringUtils.truncate("abc", type(uint256).max), "abc");
        assertEq(StringUtils.truncate("hello", 6), "hello");
        assertEq(StringUtils.truncate("hello", type(uint256).max), "hello");
    }

    function test_truncate_maxLength_noOp() public pure {
        assertEq(StringUtils.truncate("abc", type(uint256).max), "abc");
        assertEq(StringUtils.truncate("hello", type(uint256).max), "hello");
    }

    function test_truncate_zeroLength() public pure {
        assertEq(StringUtils.truncate("abcd", 0), "");
    }

    function test_truncate_emptySubject_noOp() public pure {
        assertEq(StringUtils.truncate("", 0), "");
        assertEq(StringUtils.truncate("", 5), "");
    }

    function test_truncate_singleChar() public pure {
        assertEq(StringUtils.truncate("abc", 1), "a");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_truncate_idempotent(string memory subject, uint256 length) public pure {
        string memory once = StringUtils.truncate(subject, length);
        assertEq(StringUtils.truncate(once, length), once, "repeated truncation changed result");
    }

    function test_fuzz_truncate_isLeadingSlice(string memory subject, uint256 length) public pure {
        string memory expected = StringUtils.slice(subject, 0, length);
        string memory result = StringUtils.truncate(subject, length);
        assertEq(result, expected, "truncated result differs from leading slice");
    }

    function test_fuzz_truncate_lengthBound(string memory subject, uint256 length) public pure {
        uint256 expectedLength = min(length, bytes(subject).length);
        string memory result = StringUtils.truncate(subject, length);
        assertEq(bytes(result).length, expectedLength, "truncated length is incorrect");
    }

    function test_fuzz_truncate_prefixPreserved(string memory subject, uint256 length) public pure {
        length = bound(length, 0, bytes(subject).length);
        string memory expected = StringUtils.slice(subject, 0, length);
        string memory result = StringUtils.truncate(subject, length);
        assertEq(result, expected, "truncation did not preserve leading bytes");
    }

    function test_fuzz_truncate_beyondLength_noOp(string memory subject, uint256 length) public pure {
        length = bound(length, bytes(subject).length, type(uint256).max);
        assertEq(StringUtils.truncate(subject, length), subject, "oversized truncation changed subject");
    }

    function test_fuzz_truncate(string calldata subject, uint256 length) public pure {
        uint256 expectedLength = min(length, bytes(subject).length);
        string memory result = StringUtils.truncate(subject, length);

        assertEq(bytes(result).length, expectedLength, "truncated length is incorrect");
        assertEq(result, subject[:expectedLength], "truncated content is incorrect");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_truncate_differential(string memory subject, uint256 length) public pure {
        string memory expected = referenceTruncate(subject, length);
        string memory result = StringUtils.truncate(subject, length);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceTruncate(string memory subject, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = bytes(subject);
        if (length >= buffer.length) return subject;

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = buffer[i];
        }
        return string(result);
    }
}
