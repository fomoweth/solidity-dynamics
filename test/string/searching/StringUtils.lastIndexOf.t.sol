// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsLastIndexOfTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_lastIndexOf_basic() public pure {
        assertEq(StringUtils.lastIndexOf("abcabc", "abc"), 3);
    }

    function test_lastIndexOf_emptySubject() public pure {
        assertEq(StringUtils.lastIndexOf("", "abc"), NOT_FOUND);
        assertEq(StringUtils.lastIndexOf("", "a"), NOT_FOUND);
    }

    function test_lastIndexOf_emptyNeedle() public pure {
        assertEq(StringUtils.lastIndexOf("abc", ""), 3);
        assertEq(StringUtils.lastIndexOf("a", ""), 1);
    }

    function test_lastIndexOf_emptySubjectAndNeedle() public pure {
        assertEq(StringUtils.lastIndexOf("", ""), 0);
    }

    function test_lastIndexOf_singleChar() public pure {
        assertEq(StringUtils.lastIndexOf("a", "a"), 0);
        assertEq(StringUtils.lastIndexOf("ab", "a"), 0);
        assertEq(StringUtils.lastIndexOf("b", "a"), NOT_FOUND);
    }

    function test_lastIndexOf_needleLongerThanSubject() public pure {
        assertEq(StringUtils.lastIndexOf("ab", "abc"), NOT_FOUND);
    }

    function test_lastIndexOf_noMatch() public pure {
        assertEq(StringUtils.lastIndexOf("hello world", "xyz"), NOT_FOUND);
    }

    function test_lastIndexOf_exactMatch() public pure {
        assertEq(StringUtils.lastIndexOf("abc", "abc"), 0);
    }

    function test_lastIndexOf_picksLastOfMultiple() public pure {
        assertEq(StringUtils.lastIndexOf("abcabc", "ab"), 3);
        assertEq(StringUtils.lastIndexOf("aXbXc", "X"), 3);
        assertEq(StringUtils.lastIndexOf("aaaa", "aa"), 2);
    }

    function test_lastIndexOf_offset() public pure {
        assertEq(StringUtils.lastIndexOf("abcabc", "abc", 5), 3);
        assertEq(StringUtils.lastIndexOf("abcabc", "abc", 2), 0);
        assertEq(StringUtils.lastIndexOf("abcabc", "abc", 0), 0);
        assertEq(StringUtils.lastIndexOf("abc", "", type(uint256).max), 3);
    }

    function test_lastIndexOf_longNeedle() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        string memory subject = string.concat(needle, "zzz", needle);
        assertEq(StringUtils.lastIndexOf(subject, needle), bytes(needle).length + 3);
    }

    function test_lastIndexOf_arbitraryBytes() public pure {
        string memory subject = allBytes();
        for (uint256 i = 0; i < 256; ++i) {
            assertEq(StringUtils.lastIndexOf(subject, singleByte(i)), i);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_lastIndexOf_overloadEquivalence(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.lastIndexOf(subject, needle), StringUtils.lastIndexOf(subject, needle, NOT_FOUND));
    }

    function test_fuzz_lastIndexOf_consistentWithIndexOf_singleMatch(string memory subject) public pure {
        uint256 firstIndex = StringUtils.indexOf(subject, subject);
        uint256 lastIndex = StringUtils.lastIndexOf(subject, subject);
        assertEq(firstIndex, lastIndex, "indexOf and lastIndexOf disagree on a single match");
    }

    function test_fuzz_lastIndexOf_agreesWithIndexOfOnExistence(string memory subject, string memory needle)
        public
        pure
    {
        uint256 firstIndex = StringUtils.indexOf(subject, needle);
        uint256 lastIndex = StringUtils.lastIndexOf(subject, needle);
        assertLe(firstIndex, lastIndex, "lastIndexOf returned an earlier match than indexOf");
    }

    function test_fuzz_lastIndexOf_foundImpliesValidMatch(string memory subject, string memory needle) public pure {
        uint256 index = StringUtils.lastIndexOf(subject, needle);
        assertEq(index != NOT_FOUND, vm.contains(subject, needle), "match existence disagrees with contains");

        if (index != NOT_FOUND) {
            bytes memory subjectBytes = bytes(subject);
            bytes memory needleBytes = bytes(needle);

            uint256 subjectLength = subjectBytes.length;
            uint256 needleLength = needleBytes.length;
            assertTrue(index + needleLength <= subjectLength, "match runs past the subject");

            for (uint256 i = 0; i < needleLength; ++i) {
                assertEq(subjectBytes[index + i], needleBytes[i], "reported index is not a real match");
            }
        }
    }

    function test_fuzz_lastIndexOf_respectsOffset(string memory subject, string memory needle, uint256 offset)
        public
        pure
    {
        uint256 index = StringUtils.lastIndexOf(subject, needle, offset);
        if (index != NOT_FOUND) assertLe(index, offset, "match begins after the requested offset");
    }

    function test_fuzz_lastIndexOf_offsetIsMonotone(string memory subject, string memory needle, uint256 offset)
        public
        pure
    {
        uint256 bounded = StringUtils.lastIndexOf(subject, needle, bound(offset, 0, bytes(subject).length));
        uint256 unbounded = StringUtils.lastIndexOf(subject, needle);

        if (bounded != NOT_FOUND) {
            assertLe(bounded, unbounded, "bounded search returned a later match than unbounded search");
            assertNotEq(unbounded, NOT_FOUND, "unbounded search did not find an existing bounded match");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_lastIndexOf_differential(string memory subject, string memory needle, uint256 offset)
        public
        pure
    {
        assertEq(
            StringUtils.lastIndexOf(subject, needle, offset),
            referenceLastIndexOf(subject, needle, offset),
            "result differs from reference implementation"
        );
    }

    function test_fuzz_lastIndexOf_differential(string memory subject, string memory needle) public pure {
        assertEq(
            StringUtils.lastIndexOf(subject, needle),
            referenceLastIndexOf(subject, needle, NOT_FOUND),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceLastIndexOf(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        offset = min(offset, bytes(subject).length);
        if (bytes(needle).length == 0) return offset;
        if (bytes(needle).length > bytes(subject).length) return NOT_FOUND;

        if (offset + bytes(needle).length > bytes(subject).length) {
            offset = bytes(subject).length - bytes(needle).length;
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
