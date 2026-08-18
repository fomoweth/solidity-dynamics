// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract BytesUtilsLastIndexOfTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_lastIndexOf_basic() public pure {
        assertEq(BytesUtils.lastIndexOf("abcabc", "abc"), 3);
    }

    function test_lastIndexOf_emptySubject() public pure {
        assertEq(BytesUtils.lastIndexOf("", "abc"), NOT_FOUND);
        assertEq(BytesUtils.lastIndexOf("", "a"), NOT_FOUND);
    }

    function test_lastIndexOf_emptyNeedle() public pure {
        assertEq(BytesUtils.lastIndexOf("abc", ""), 3);
        assertEq(BytesUtils.lastIndexOf("a", ""), 1);
    }

    function test_lastIndexOf_emptySubjectAndNeedle() public pure {
        assertEq(BytesUtils.lastIndexOf("", ""), 0);
    }

    function test_lastIndexOf_singleChar() public pure {
        assertEq(BytesUtils.lastIndexOf("a", "a"), 0);
        assertEq(BytesUtils.lastIndexOf("ab", "a"), 0);
        assertEq(BytesUtils.lastIndexOf("b", "a"), NOT_FOUND);
    }

    function test_lastIndexOf_needleLongerThanSubject() public pure {
        assertEq(BytesUtils.lastIndexOf("ab", "abc"), NOT_FOUND);
    }

    function test_lastIndexOf_noMatch() public pure {
        assertEq(BytesUtils.lastIndexOf("hello world", "xyz"), NOT_FOUND);
    }

    function test_lastIndexOf_exactMatch() public pure {
        assertEq(BytesUtils.lastIndexOf("abc", "abc"), 0);
    }

    function test_lastIndexOf_picksLastOfMultiple() public pure {
        assertEq(BytesUtils.lastIndexOf("abcabc", "ab"), 3);
        assertEq(BytesUtils.lastIndexOf("aXbXc", "X"), 3);
        // Overlapping candidates: last start position wins.
        assertEq(BytesUtils.lastIndexOf("aaaa", "aa"), 2);
    }

    function test_lastIndexOf_offset() public pure {
        assertEq(BytesUtils.lastIndexOf("abcabc", "abc", 5), 3);
        assertEq(BytesUtils.lastIndexOf("abcabc", "abc", 2), 0);
        assertEq(BytesUtils.lastIndexOf("abcabc", "abc", 0), 0);
        assertEq(BytesUtils.lastIndexOf("abc", "", type(uint256).max), 3);
    }

    function test_lastIndexOf_longNeedle() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        bytes memory subject = bytes.concat(needle, "zzz", needle);
        assertEq(BytesUtils.lastIndexOf(subject, needle), needle.length + 3);
    }

    function test_lastIndexOf_arbitraryBytes() public pure {
        bytes memory subject = bytes(allBytes());

        for (uint256 i = 0; i < 256; ++i) {
            assertEq(BytesUtils.lastIndexOf(subject, abi.encodePacked(uint8(i))), i);
        }

        assertEq(BytesUtils.lastIndexOf(subject, abi.encodePacked(bytes2(0x0001))), 0);
        assertEq(BytesUtils.lastIndexOf(subject, abi.encodePacked(bytes2(0x8081))), 128);
        assertEq(BytesUtils.lastIndexOf(subject, abi.encodePacked(bytes2(0xfeff))), 254);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_lastIndexOf_overloadEquivalence(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.lastIndexOf(subject, needle), BytesUtils.lastIndexOf(subject, needle, NOT_FOUND));
    }

    function test_fuzz_lastIndexOf_consistentWithIndexOf_singleMatch(bytes memory subject) public pure {
        uint256 firstIndex = BytesUtils.indexOf(subject, subject);
        uint256 lastIndex = BytesUtils.lastIndexOf(subject, subject);
        assertEq(firstIndex, lastIndex, "indexOf and lastIndexOf disagree on a single match");
    }

    function test_fuzz_lastIndexOf_agreesWithIndexOfOnExistence(bytes memory subject, bytes memory needle) public pure {
        uint256 firstIndex = BytesUtils.indexOf(subject, needle);
        uint256 lastIndex = BytesUtils.lastIndexOf(subject, needle);
        assertLe(firstIndex, lastIndex, "lastIndexOf returned an earlier match than indexOf");
    }

    function test_fuzz_lastIndexOf_foundImpliesValidMatch(bytes memory subject, bytes memory needle) public pure {
        uint256 index = BytesUtils.lastIndexOf(subject, needle);
        if (index != NOT_FOUND) {
            assertTrue(index + needle.length <= subject.length, "match runs past the subject");

            for (uint256 i = 0; i < needle.length; ++i) {
                assertEq(subject[index + i], needle[i], "reported index is not a real match");
            }
        }
    }

    function test_fuzz_lastIndexOf_respectsOffset(bytes memory subject, bytes memory needle, uint256 offset)
        public
        pure
    {
        uint256 index = BytesUtils.lastIndexOf(subject, needle, offset);
        if (index != NOT_FOUND) assertLe(index, offset, "match begins after the requested offset");
    }

    function test_fuzz_lastIndexOf_offsetIsMonotone(bytes memory subject, bytes memory needle, uint256 offset)
        public
        pure
    {
        offset = bound(offset, 0, subject.length);
        uint256 bounded = BytesUtils.lastIndexOf(subject, needle, offset);
        uint256 unbounded = BytesUtils.lastIndexOf(subject, needle);

        if (bounded != NOT_FOUND) {
            assertLe(bounded, unbounded, "bounded search returned a later match than unbounded search");
            assertNotEq(unbounded, NOT_FOUND, "unbounded search did not find an existing bounded match");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_lastIndexOf_differential(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        assertEq(BytesUtils.lastIndexOf(subject, needle, offset), referenceLastIndexOf(subject, needle, offset));
    }

    function test_fuzz_lastIndexOf_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.lastIndexOf(subject, needle), referenceLastIndexOf(subject, needle, NOT_FOUND));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceLastIndexOf(bytes memory subject, bytes memory needle, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        offset = min(offset, subject.length);
        if (needle.length == 0) return offset;
        if (needle.length > subject.length) return NOT_FOUND;

        if (offset + needle.length > subject.length) {
            offset = subject.length - needle.length;
        }

        // iterate from start downward
        for (uint256 i = offset;;) {
            if (matchesAt(subject, needle, i)) return i;
            if (i == 0) break;
            i--;
        }

        return NOT_FOUND;
    }
}
