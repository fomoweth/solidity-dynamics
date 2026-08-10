// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract BytesUtilsSliceTest is BaseTest {
    using BytesUtils for bytes;

    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_slice_basic() public pure {
        assertEq(BytesUtils.slice("hello world", 0, 11), "hello world");
        assertEq(BytesUtils.slice("hello world", 0, 1), "h");
        assertEq(BytesUtils.slice("hello world", 0, 5), "hello");
        assertEq(BytesUtils.slice("hello world", 0, 6), "hello ");
        assertEq(BytesUtils.slice("hello world", 5, 1), " ");
        assertEq(BytesUtils.slice("hello world", 5, 6), " world");
        assertEq(BytesUtils.slice("hello world", 6, 5), "world");
        assertEq(BytesUtils.slice("hello world", 10, 1), "d");
        assertEq(BytesUtils.slice("hello world", 11, 1), "");
    }

    function test_slice_emptySubject() public pure {
        assertEq(BytesUtils.slice("", 0, 0), "");
        assertEq(BytesUtils.slice("", 0, 5), "");
        assertEq(BytesUtils.slice("", 5, 0), "");
        assertEq(BytesUtils.slice("", 5, 5), "");
    }

    function test_slice_zeroLength() public pure {
        assertEq(BytesUtils.slice("hello world", 0, 0), "");
        assertEq(BytesUtils.slice("hello world", 1, 0), "");
        assertEq(BytesUtils.slice("hello world", 5, 0), "");
    }

    function test_slice_maxLength() public pure {
        assertEq(BytesUtils.slice("hello world", 0, type(uint256).max), "hello world");
        assertEq(BytesUtils.slice("hello world", 5, type(uint256).max), " world");
        assertEq(BytesUtils.slice("hello world", 6, type(uint256).max), "world");
        assertEq(BytesUtils.slice("hello world", 10, type(uint256).max), "d");
        assertEq(BytesUtils.slice("hello world", 11, type(uint256).max), "");
    }

    function test_slice_offsetAtLength() public pure {
        assertEq(BytesUtils.slice("hello", 5, 1), "");
        assertEq(BytesUtils.slice("hello", 5, 5), "");
        assertEq(BytesUtils.slice("hello", 5, 10), "");
    }

    function test_slice_offsetBeyondLength() public pure {
        assertEq(BytesUtils.slice("hello", 10, 1), "");
        assertEq(BytesUtils.slice("hello", 10, 5), "");
        assertEq(BytesUtils.slice("hello", 10, 10), "");
    }

    function test_slice_overflowingBounds() public pure {
        assertEq(BytesUtils.slice("hello", 1, type(uint256).max), "ello");
        assertEq(BytesUtils.slice("hello", type(uint256).max, type(uint256).max), "");
        assertEq(BytesUtils.slice("hello", type(uint256).max, 1), "");
        assertEq(BytesUtils.slice("hello", 3, type(uint256).max - 2), "lo");
    }

    function test_slice_treatsUtf8AsBytes() public pure {
        bytes memory subject = unicode"Aé☕Z";
        assertEq(BytesUtils.slice(subject, 1, 2), unicode"é");
        assertEq(bytes(BytesUtils.slice(subject, 2, 2)), hex"a9e2");
        assertEq(BytesUtils.slice(subject, 3, 3), unicode"☕");
    }

    function test_slice_returnsIndependentCopy() public pure {
        bytes memory subject = "hello";
        bytes memory result = BytesUtils.slice(subject, 0, 5);

        BytesUtils.truncate(result, 1);
        assertEq(result, "h");
        assertEq(subject, "hello");
    }

    function test_slice_parse_erc7579_accountId() public pure {
        bytes memory accountId = "fomoweth.vortex.0.0.1-alpha";
        bytes memory delimiter = ".";

        uint256 nameOffset = accountId.indexOf(delimiter);
        assertNotEq(nameOffset, type(uint256).max);

        uint256 versionOffset = accountId.indexOf(delimiter, ++nameOffset);
        assertNotEq(versionOffset, type(uint256).max);

        bytes memory name = accountId.slice(nameOffset, versionOffset - nameOffset);
        assertEq(name, "vortex");

        bytes memory version = accountId.slice(++versionOffset);
        assertEq(version, "0.0.1-alpha");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_overloadEquivalence(bytes memory subject, uint256 offset) public pure {
        assertEq(BytesUtils.slice(subject, offset), BytesUtils.slice(subject, offset, type(uint256).max));
    }

    function test_fuzz_slice_lengthBound(bytes memory subject, uint256 offset, uint256 length) public pure {
        bytes memory result = BytesUtils.slice(subject, offset, length);
        assertLe(bytes(result).length, length);
        assertLe(bytes(result).length, saturatingSub(bytes(subject).length, offset));
    }

    function test_fuzz_slice_offsetBeyondLength(bytes memory subject, uint256 offset) public pure {
        offset = bound(offset, bytes(subject).length, type(uint256).max);
        assertEq(BytesUtils.slice(subject, offset), "");
    }

    function test_fuzz_slice_recombination(bytes memory subject, uint256 offset) public pure {
        bytes memory buffer = bytes(subject);
        offset = bound(offset, 0, buffer.length);

        bytes memory left = BytesUtils.slice(subject, 0, offset);
        bytes memory right = BytesUtils.slice(subject, offset, buffer.length);
        assertEq(bytes.concat(left, right), subject);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_differential(bytes memory subject, uint256 offset) public pure {
        bytes memory expected = referenceSlice(subject, offset, type(uint256).max);
        bytes memory actual = BytesUtils.slice(subject, offset);

        assertLe(bytes(actual).length, bytes(subject).length);
        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_slice_differential(bytes memory subject, uint256 offset, uint256 length) public pure {
        bytes memory expected = referenceSlice(subject, offset, length);
        bytes memory actual = BytesUtils.slice(subject, offset, length);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceSlice(bytes memory subject, uint256 offset, uint256 length)
        internal
        pure
        returns (bytes memory result)
    {
        offset = min(offset, subject.length);
        length = min(length, subject.length - offset);

        result = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = subject[offset + i];
        }
    }
}
