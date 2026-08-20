// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsContainsTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_contains_emptySubject() public pure {
        assertFalse(StringUtils.contains("", "a"));
    }

    function test_contains_emptyNeedle() public pure {
        assertTrue(StringUtils.contains("abc", ""));
    }

    function test_contains_emptySubjectAndNeedle() public pure {
        assertTrue(StringUtils.contains("", ""));
    }

    function test_contains_singleChar() public pure {
        assertTrue(StringUtils.contains("abc", "b"));
        assertFalse(StringUtils.contains("abc", "x"));
    }

    function test_contains_needleLongerThanSubject() public pure {
        assertFalse(StringUtils.contains("ab", "abc"));
    }

    function test_contains_needleEqualsSubject() public pure {
        assertTrue(StringUtils.contains("abc", "abc"));
    }

    function test_contains_startMiddleEnd() public pure {
        assertTrue(StringUtils.contains("hello world", "hello"));
        assertTrue(StringUtils.contains("hello world", "o w"));
        assertTrue(StringUtils.contains("hello world", "world"));
        assertFalse(StringUtils.contains("hello world", "worlds"));
    }

    function test_contains_longNeedle() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        string memory subject = string.concat("prefix", needle);

        assertTrue(StringUtils.contains(subject, needle));
        assertTrue(StringUtils.contains(subject, subject));
        assertFalse(StringUtils.contains(subject, string.concat(needle, "!")));
    }

    function test_contains_offsetAtMatch() public pure {
        assertTrue(StringUtils.contains("abcabc", "abc", 3));
    }

    function test_contains_offsetPastOnlyMatch() public pure {
        assertTrue(StringUtils.contains("xxabc", "abc", 2));
        assertFalse(StringUtils.contains("xxabc", "abc", 3));
    }

    function test_contains_offsetSkipsFirstMatch() public pure {
        assertTrue(StringUtils.contains("abcabc", "abc", 1));
        assertFalse(StringUtils.contains("abcabc", "abc", 4));
    }

    function test_contains_offsetBeyondLength() public pure {
        assertFalse(StringUtils.contains("abc", "a", 4));
        assertFalse(StringUtils.contains("abc", "a", NOT_FOUND));
    }

    function test_contains_emptyNeedle_anyOffset() public pure {
        assertTrue(StringUtils.contains("abc", "", 0));
        assertTrue(StringUtils.contains("abc", "", 3));
        assertTrue(StringUtils.contains("abc", "", 4));
        assertTrue(StringUtils.contains("abc", "", NOT_FOUND));
        assertTrue(StringUtils.contains("", "", NOT_FOUND));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_contains_overloadEquivalence(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.contains(subject, needle), StringUtils.contains(subject, needle, 0));
    }

    function test_fuzz_contains_matchesIndexOf(string memory subject, string memory needle, uint256 offset)
        public
        pure
    {
        uint256 index = StringUtils.indexOf(subject, needle, offset);
        assertEq(StringUtils.contains(subject, needle, offset), index != NOT_FOUND, "contains disagrees with indexOf");
    }

    function test_fuzz_contains_constructedMatch(string memory prefix, string memory needle, string memory suffix)
        public
        pure
    {
        string memory subject = string.concat(prefix, needle, suffix);
        assertTrue(StringUtils.contains(subject, needle), "constructed match was not found");
        assertTrue(StringUtils.contains(subject, needle, 0), "constructed match was not found from offset zero");
    }

    function test_fuzz_contains_offsetIsMonotone(string memory subject, string memory needle, uint256 offset)
        public
        pure
    {
        if (StringUtils.contains(subject, needle, bound(offset, 0, bytes(subject).length))) {
            assertTrue(StringUtils.contains(subject, needle, 0), "match from offset was not found from zero");
        }
    }

    function test_fuzz_contains_agreesWithCheatcode(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.contains(subject, needle), vm.contains(subject, needle), "result differs from cheatcode");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_contains_differential(string memory subject, string memory needle, uint256 offset) public pure {
        assertEq(
            StringUtils.contains(subject, needle, offset),
            referenceContains(subject, needle, offset),
            "result differs from reference implementation"
        );
    }

    function test_fuzz_contains_differential(string memory subject, string memory needle) public pure {
        assertEq(
            StringUtils.contains(subject, needle),
            referenceContains(subject, needle, 0),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceContains(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (bool)
    {
        if (bytes(needle).length == 0) return true;
        for (uint256 i = min(offset, bytes(subject).length); i + bytes(needle).length <= bytes(subject).length; ++i) {
            if (matchesAt(subject, needle, i)) return true;
        }
        return false;
    }
}
