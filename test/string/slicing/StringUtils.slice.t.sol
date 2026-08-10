// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract StringUtilsSliceTest is BaseTest {
    using StringUtils for string;

    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_slice_basic() public pure {
        assertEq(StringUtils.slice("hello world", 0, 11), "hello world");
        assertEq(StringUtils.slice("hello world", 0, 1), "h");
        assertEq(StringUtils.slice("hello world", 0, 5), "hello");
        assertEq(StringUtils.slice("hello world", 0, 6), "hello ");
        assertEq(StringUtils.slice("hello world", 5, 1), " ");
        assertEq(StringUtils.slice("hello world", 5, 6), " world");
        assertEq(StringUtils.slice("hello world", 6, 5), "world");
        assertEq(StringUtils.slice("hello world", 10, 1), "d");
        assertEq(StringUtils.slice("hello world", 11, 1), "");
    }

    function test_slice_emptySubject() public pure {
        assertEq(StringUtils.slice("", 0, 0), "");
        assertEq(StringUtils.slice("", 0, 5), "");
        assertEq(StringUtils.slice("", 5, 0), "");
        assertEq(StringUtils.slice("", 5, 5), "");
    }

    function test_slice_zeroLength() public pure {
        assertEq(StringUtils.slice("hello world", 0, 0), "");
        assertEq(StringUtils.slice("hello world", 1, 0), "");
        assertEq(StringUtils.slice("hello world", 5, 0), "");
    }

    function test_slice_maxLength() public pure {
        assertEq(StringUtils.slice("hello world", 0, type(uint256).max), "hello world");
        assertEq(StringUtils.slice("hello world", 5, type(uint256).max), " world");
        assertEq(StringUtils.slice("hello world", 6, type(uint256).max), "world");
        assertEq(StringUtils.slice("hello world", 10, type(uint256).max), "d");
        assertEq(StringUtils.slice("hello world", 11, type(uint256).max), "");
    }

    function test_slice_offsetAtLength() public pure {
        assertEq(StringUtils.slice("hello", 5, 1), "");
        assertEq(StringUtils.slice("hello", 5, 5), "");
        assertEq(StringUtils.slice("hello", 5, 10), "");
    }

    function test_slice_offsetBeyondLength() public pure {
        assertEq(StringUtils.slice("hello", 10, 1), "");
        assertEq(StringUtils.slice("hello", 10, 5), "");
        assertEq(StringUtils.slice("hello", 10, 10), "");
    }

    function test_slice_overflowingBounds() public pure {
        assertEq(StringUtils.slice("hello", 1, type(uint256).max), "ello");
        assertEq(StringUtils.slice("hello", type(uint256).max, type(uint256).max), "");
        assertEq(StringUtils.slice("hello", type(uint256).max, 1), "");
        assertEq(StringUtils.slice("hello", 3, type(uint256).max - 2), "lo");
    }

    function test_slice_returnsIndependentCopy() public pure {
        string memory subject = "hello";
        string memory result = StringUtils.slice(subject, 0, 5);

        StringUtils.truncate(result, 1);
        assertEq(result, "h");
        assertEq(subject, "hello");
    }

    function test_slice_parse_erc7579_accountId() public pure {
        string memory accountId = "fomoweth.vortex.0.0.1-alpha";
        string memory delimiter = ".";

        uint256 nameOffset = accountId.indexOf(delimiter);
        assertNotEq(nameOffset, type(uint256).max);

        uint256 versionOffset = accountId.indexOf(delimiter, ++nameOffset);
        assertNotEq(versionOffset, type(uint256).max);

        string memory name = accountId.slice(nameOffset, versionOffset - nameOffset);
        assertEq(name, "vortex");

        name = string.concat(vm.toUppercase(name.slice(0, 1)), name.slice(1));
        assertEq(name, "Vortex");

        string memory version = accountId.slice(++versionOffset);
        assertEq(version, "0.0.1-alpha");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_overloadEquivalence(string memory subject, uint256 offset) public pure {
        assertEq(StringUtils.slice(subject, offset), StringUtils.slice(subject, offset, type(uint256).max));
    }

    function test_fuzz_slice_lengthBound(string memory subject, uint256 offset, uint256 length) public pure {
        string memory result = StringUtils.slice(subject, offset, length);
        assertLe(bytes(result).length, length);
        assertLe(bytes(result).length, saturatingSub(bytes(subject).length, offset));
    }

    function test_fuzz_slice_offsetBeyondLength(string memory subject, uint256 offset) public pure {
        offset = bound(offset, bytes(subject).length, type(uint256).max);
        assertEq(StringUtils.slice(subject, offset), "");
    }

    function test_fuzz_slice_recombination(string memory subject, uint256 offset) public pure {
        bytes memory buffer = bytes(subject);
        offset = bound(offset, 0, buffer.length);

        string memory left = StringUtils.slice(subject, 0, offset);
        string memory right = StringUtils.slice(subject, offset, buffer.length);
        assertEq(string.concat(left, right), subject);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_differential(string memory subject, uint256 offset) public pure {
        string memory expected = referenceSlice(subject, offset, type(uint256).max);
        string memory actual = StringUtils.slice(subject, offset);

        assertLe(bytes(actual).length, bytes(subject).length);
        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_slice_differential(string memory subject, uint256 offset, uint256 length) public pure {
        string memory expected = referenceSlice(subject, offset, length);
        string memory actual = StringUtils.slice(subject, offset, length);

        assertLe(bytes(actual).length, bytes(subject).length);
        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceSlice(string memory subject, uint256 offset, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = bytes(subject);
        offset = min(offset, buffer.length);
        length = min(length, buffer.length - offset);

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; ++i) {
            result[i] = buffer[offset + i];
        }
        return string(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function capitalize(string memory str) internal pure returns (string memory) {
        return string.concat(vm.toUppercase(StringUtils.slice(str, 0, 1)), StringUtils.slice(str, 1));
    }
}
