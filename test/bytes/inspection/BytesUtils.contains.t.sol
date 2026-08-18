// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsContainsWithTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_contains_emptySubject() public pure {
        assertFalse(BytesUtils.contains("", "a"));
    }

    function test_contains_emptyNeedle() public pure {
        assertTrue(BytesUtils.contains("abc", ""));
    }

    function test_contains_emptySubjectAndNeedle() public pure {
        assertTrue(BytesUtils.contains("", ""));
    }

    function test_contains_singleChar() public pure {
        assertTrue(BytesUtils.contains("abc", "b"));
        assertFalse(BytesUtils.contains("abc", "x"));
    }

    function test_contains_needleLongerThanSubject() public pure {
        assertFalse(BytesUtils.contains("ab", "abc"));
    }

    function test_contains_needleEqualsSubject() public pure {
        assertTrue(BytesUtils.contains("abc", "abc"));
    }

    function test_contains_startMiddleEnd() public pure {
        assertTrue(BytesUtils.contains("hello world", "hello"));
        assertTrue(BytesUtils.contains("hello world", "o w"));
        assertTrue(BytesUtils.contains("hello world", "world"));
        assertFalse(BytesUtils.contains("hello world", "worlds"));
    }

    function test_contains_longNeedle() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        bytes memory subject = bytes.concat("prefix", needle);

        assertTrue(BytesUtils.contains(subject, needle));
        assertTrue(BytesUtils.contains(subject, subject));
        assertFalse(BytesUtils.contains(subject, bytes.concat(needle, "!")));
    }

    function test_contains_offsetAtMatch() public pure {
        assertTrue(BytesUtils.contains("abcabc", "abc", 3));
    }

    function test_contains_offsetPastOnlyMatch() public pure {
        assertTrue(BytesUtils.contains("xxabc", "abc", 2));
        assertFalse(BytesUtils.contains("xxabc", "abc", 3));
    }

    function test_contains_offsetSkipsFirstMatch() public pure {
        assertTrue(BytesUtils.contains("abcabc", "abc", 1));
        assertFalse(BytesUtils.contains("abcabc", "abc", 4));
    }

    function test_contains_offsetBeyondLength() public pure {
        assertFalse(BytesUtils.contains("abc", "a", 4));
        assertFalse(BytesUtils.contains("abc", "a", NOT_FOUND));
    }

    function test_contains_emptyNeedle_anyOffset() public pure {
        assertTrue(BytesUtils.contains("abc", "", 0));
        assertTrue(BytesUtils.contains("abc", "", 3));
        assertTrue(BytesUtils.contains("abc", "", 4));
        assertTrue(BytesUtils.contains("abc", "", NOT_FOUND));
        assertTrue(BytesUtils.contains("", "", NOT_FOUND));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_contains_overloadEquivalence(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.contains(subject, needle), BytesUtils.contains(subject, needle, 0));
    }

    function test_fuzz_contains_matchesIndexOf(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        uint256 index = BytesUtils.indexOf(subject, needle, offset);
        assertEq(BytesUtils.contains(subject, needle, offset), index != NOT_FOUND, "contains disagrees with indexOf");
    }

    function test_fuzz_contains_constructedMatch(bytes memory prefix, bytes memory needle, bytes memory suffix)
        public
        pure
    {
        bytes memory subject = bytes.concat(prefix, needle, suffix);
        assertTrue(BytesUtils.contains(subject, needle), "constructed match was not found");
        assertTrue(BytesUtils.contains(subject, needle, 0), "constructed match was not found from offset zero");
    }

    function test_fuzz_contains_offsetIsMonotone(bytes memory subject, bytes memory needle, uint256 offset)
        public
        pure
    {
        if (BytesUtils.contains(subject, needle, bound(offset, 0, bytes(subject).length))) {
            assertTrue(BytesUtils.contains(subject, needle, 0), "match from offset was not found from zero");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_contains_differential(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        assertEq(
            BytesUtils.contains(subject, needle, offset),
            referenceContains(subject, needle, offset),
            "result differs from reference implementation"
        );
    }

    function test_fuzz_contains_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(
            BytesUtils.contains(subject, needle),
            referenceContains(subject, needle, 0),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceContains(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (bool) {
        if (needle.length == 0) return true;
        for (uint256 i = min(offset, subject.length); i + needle.length <= subject.length; ++i) {
            if (matchesAt(subject, needle, i)) return true;
        }
        return false;
    }
}
