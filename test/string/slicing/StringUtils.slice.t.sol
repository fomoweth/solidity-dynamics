// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsSliceTest is StringUtilsTest {
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

    function test_slice_arbitraryBytes() public pure {
        string memory subject = allBytes();
        assertEq(bytes(StringUtils.slice(subject, 0, 256)).length, 256);

        for (uint256 i = 0; i < 256; ++i) {
            assertEq(StringUtils.slice(subject, i, 1), singleByte(i));
        }
    }

    function test_slice_parse_erc7579_accountId() public pure {
        string memory accountId = "fomoweth.vortex.0.0.1-alpha";
        string memory delimiter = ".";

        uint256 nameOffset = StringUtils.indexOf(accountId, delimiter);
        assertNotEq(nameOffset, type(uint256).max);

        uint256 versionOffset = StringUtils.indexOf(accountId, delimiter, ++nameOffset);
        assertNotEq(versionOffset, type(uint256).max);

        string memory name = StringUtils.slice(accountId, nameOffset, versionOffset - nameOffset);
        assertEq(name, "vortex");

        string memory version = StringUtils.slice(accountId, ++versionOffset);
        assertEq(version, "0.0.1-alpha");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_overloadEquivalence(string memory subject, uint256 offset) public pure {
        assertEq(StringUtils.slice(subject, offset), StringUtils.slice(subject, offset, type(uint256).max));
    }

    function test_fuzz_slice_lengthBound(string memory subject, uint256 offset, uint256 length) public pure {
        bytes memory result = bytes(StringUtils.slice(subject, offset, length));
        assertLe(result.length, length, "slice exceeds requested length");
        assertLe(result.length, saturatingSub(bytes(subject).length, offset), "slice exceeds remaining subject length");
    }

    function test_fuzz_slice_offsetBeyondLength(string memory subject, uint256 offset) public pure {
        offset = bound(offset, bytes(subject).length, type(uint256).max);
        assertEq(StringUtils.slice(subject, offset), "", "out-of-range offset produced non-empty slice");
    }

    function test_fuzz_slice_recombination(string memory subject, uint256 offset) public pure {
        string memory left = StringUtils.slice(subject, 0, offset = bound(offset, 0, bytes(subject).length));
        string memory right = StringUtils.slice(subject, offset, bytes(subject).length);
        assertEq(string.concat(left, right), subject, "recombined slices differ from subject");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_slice_differential(string memory subject, uint256 offset) public pure {
        string memory expected = referenceSlice(subject, offset, type(uint256).max);
        string memory result = StringUtils.slice(subject, offset);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_slice_differential(string memory subject, uint256 offset, uint256 length) public pure {
        string memory expected = referenceSlice(subject, offset, length);
        string memory result = StringUtils.slice(subject, offset, length);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
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
}
