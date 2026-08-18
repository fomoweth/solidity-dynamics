// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsIndexOfTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_indexOf_basic() public pure {
        assertEq(BytesUtils.indexOf("abcde", "ab"), 0);
        assertEq(BytesUtils.indexOf("abcde", "cd"), 2);
        assertEq(BytesUtils.indexOf("abcde", "e"), 4);
        assertEq(BytesUtils.indexOf("hello world", "world"), 6);
    }

    function test_indexOf_emptySubject() public pure {
        assertEq(BytesUtils.indexOf("", "a"), NOT_FOUND);
        assertEq(BytesUtils.indexOf("", "abc"), NOT_FOUND);
    }

    function test_indexOf_emptyNeedle() public pure {
        assertEq(BytesUtils.indexOf("a", ""), 0);
        assertEq(BytesUtils.indexOf("abc", ""), 0);
    }

    function test_indexOf_emptySubjectAndNeedle() public pure {
        assertEq(BytesUtils.indexOf("", ""), 0);
    }

    function test_indexOf_needleLongerThanSubject() public pure {
        assertEq(BytesUtils.indexOf("ab", "abc"), NOT_FOUND);
    }

    function test_indexOf_noMatch() public pure {
        assertEq(BytesUtils.indexOf("abc", "xyz"), NOT_FOUND);
    }

    function test_indexOf_exactMatch() public pure {
        assertEq(BytesUtils.indexOf("abc", "abc"), 0);
    }

    function test_indexOf_multipleMatches() public pure {
        assertEq(BytesUtils.indexOf("ababab", "ab"), 0);
        assertEq(BytesUtils.indexOf("aXbXc", "X"), 1);
    }

    function test_indexOf_overlapping() public pure {
        assertEq(BytesUtils.indexOf("aaa", "aa"), 0);
    }

    function test_indexOf_matchAtStart() public pure {
        assertEq(BytesUtils.indexOf("abcde", "abc"), 0);
        assertEq(BytesUtils.indexOf("xxabyy", "xx"), 0);
    }

    function test_indexOf_matchAtMiddle() public pure {
        assertEq(BytesUtils.indexOf("abcde", "c"), 2);
        assertEq(BytesUtils.indexOf("xxabyy", "ab"), 2);
    }

    function test_indexOf_matchAtEnd() public pure {
        assertEq(BytesUtils.indexOf("abcde", "e"), 4);
        assertEq(BytesUtils.indexOf("xxxxab", "ab"), 4);
    }

    function test_indexOf_singleChar() public pure {
        assertEq(BytesUtils.indexOf("a", "a"), 0);
        assertEq(BytesUtils.indexOf("ba", "a"), 1);
        assertEq(BytesUtils.indexOf("b", "a"), NOT_FOUND);
    }

    function test_indexOf_offsetAtExactMatch() public pure {
        assertEq(BytesUtils.indexOf("abcabc", "abc", 3), 3);
    }

    function test_indexOf_offsetBeyondLength() public pure {
        assertEq(BytesUtils.indexOf("abcabc", "abc", 10), NOT_FOUND);
    }

    function test_indexOf_offsetSkipsFirstMatch() public pure {
        assertEq(BytesUtils.indexOf("abcabc", "abc", 1), 3);
    }

    function test_indexOf_longNeedle() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        bytes memory subject = bytes.concat("zzz", needle, "zzz");
        assertEq(BytesUtils.indexOf(subject, needle), 3);

        bytes memory needle33 = "0123456789abcdef0123456789abcdefX"; // 33 bytes
        assertEq(BytesUtils.indexOf(bytes.concat("_", needle33), needle33), 1);
        assertEq(BytesUtils.indexOf(subject, needle33), NOT_FOUND);
    }

    function test_indexOf_arbitraryBytes() public pure {
        bytes memory subject = allBytes();
        for (uint256 i = 0; i < 256; ++i) {
            assertEq(BytesUtils.indexOf(subject, singleByte(i)), i);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indexOf_overloadEquivalence(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.indexOf(subject, needle), BytesUtils.indexOf(subject, needle, 0));
    }

    function test_fuzz_indexOf_respectsOffset(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        uint256 index = BytesUtils.indexOf(subject, needle, offset);
        if (index != NOT_FOUND) {
            assertGe(index, min(offset, subject.length), "match begins before the requested offset");
        }
    }

    function test_fuzz_indexOf_isLeftmostMatch(bytes memory subject, bytes memory needle) public pure {
        vm.assume(needle.length != 0);

        uint256 index = BytesUtils.indexOf(subject, needle);
        if (index != NOT_FOUND) {
            assertEq(BytesUtils.slice(subject, index, needle.length), needle, "index is not a real match");
            for (uint256 i = 0; i < index; ++i) {
                assertFalse(matchesAt(subject, needle, i), "an earlier match exists");
            }
        }
    }

    function test_fuzz_indexOf_foundImpliesValidMatch(bytes memory subject, bytes memory needle) public pure {
        uint256 index = BytesUtils.indexOf(subject, needle);
        if (index != NOT_FOUND) {
            assertLe(index + needle.length, subject.length, "match runs past the subject");

            for (uint256 i = 0; i < needle.length; ++i) {
                assertEq(subject[index + i], needle[i], "index is not a real match");
            }
        }
    }

    function test_fuzz_indexOf_notFoundMeansAbsent(bytes memory subject, bytes memory needle) public pure {
        vm.assume(needle.length != 0 && subject.length >= needle.length);

        uint256 index = BytesUtils.indexOf(subject, needle);
        if (index == NOT_FOUND) {
            for (uint256 i = 0; i <= subject.length - needle.length; ++i) {
                assertFalse(matchesAt(subject, needle, i), "a match exists despite `NOT_FOUND`");
            }
        }
    }

    function test_fuzz_indexOf_offsetMonotone(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        uint256 fromZero = BytesUtils.indexOf(subject, needle);
        uint256 fromOffset = BytesUtils.indexOf(subject, needle, bound(offset, 0, subject.length));
        if (fromZero != NOT_FOUND && fromOffset != NOT_FOUND) {
            assertGe(fromOffset, fromZero, "later search offset returned an earlier match");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indexOf_differential(bytes memory subject, bytes memory needle, uint256 offset) public pure {
        assertEq(
            BytesUtils.indexOf(subject, needle, offset),
            referenceIndexOf(subject, needle, offset),
            "result differs from reference implementation"
        );
    }

    function test_fuzz_indexOf_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(
            BytesUtils.indexOf(subject, needle),
            referenceIndexOf(subject, needle, 0),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceIndexOf(bytes memory subject, bytes memory needle, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        offset = min(offset, subject.length);
        if (needle.length == 0) return offset;

        for (uint256 i = offset; i + needle.length <= subject.length; ++i) {
            if (matchesAt(subject, needle, i)) return i;
        }

        return NOT_FOUND;
    }
}
