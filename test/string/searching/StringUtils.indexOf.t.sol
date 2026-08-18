// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract StringUtilsIndexOfTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_indexOf_basic() public pure {
        assertEq(StringUtils.indexOf("abcde", "ab"), 0);
        assertEq(StringUtils.indexOf("abcde", "cd"), 2);
        assertEq(StringUtils.indexOf("abcde", "e"), 4);
        assertEq(StringUtils.indexOf("hello world", "world"), 6);
    }

    function test_indexOf_emptySubject() public pure {
        assertEq(StringUtils.indexOf("", "a"), NOT_FOUND);
        assertEq(StringUtils.indexOf("", "abc"), NOT_FOUND);
    }

    function test_indexOf_emptyNeedle() public pure {
        assertEq(StringUtils.indexOf("a", ""), 0);
        assertEq(StringUtils.indexOf("abc", ""), 0);
    }

    function test_indexOf_emptySubjectAndNeedle() public pure {
        assertEq(StringUtils.indexOf("", ""), 0);
    }

    function test_indexOf_needleLongerThanSubject() public pure {
        assertEq(StringUtils.indexOf("ab", "abc"), NOT_FOUND);
    }

    function test_indexOf_noMatch() public pure {
        assertEq(StringUtils.indexOf("abc", "xyz"), NOT_FOUND);
    }

    function test_indexOf_exactMatch() public pure {
        assertEq(StringUtils.indexOf("abc", "abc"), 0);
    }

    function test_indexOf_multipleMatches() public pure {
        assertEq(StringUtils.indexOf("ababab", "ab"), 0);
        assertEq(StringUtils.indexOf("aXbXc", "X"), 1);
    }

    function test_indexOf_overlapping() public pure {
        // "aaa", find "aa" from 0 → first match at 0
        assertEq(StringUtils.indexOf("aaa", "aa"), 0);
    }

    function test_indexOf_matchAtStart() public pure {
        assertEq(StringUtils.indexOf("abcde", "abc"), 0);
        assertEq(StringUtils.indexOf("xxabyy", "xx"), 0);
    }

    function test_indexOf_matchAtMiddle() public pure {
        assertEq(StringUtils.indexOf("abcde", "c"), 2);
        assertEq(StringUtils.indexOf("xxabyy", "ab"), 2);
    }

    function test_indexOf_matchAtEnd() public pure {
        assertEq(StringUtils.indexOf("abcde", "e"), 4);
        assertEq(StringUtils.indexOf("xxxxab", "ab"), 4);
    }

    function test_indexOf_singleChar() public pure {
        assertEq(StringUtils.indexOf("a", "a"), 0);
        assertEq(StringUtils.indexOf("ba", "a"), 1);
        assertEq(StringUtils.indexOf("b", "a"), NOT_FOUND);
    }

    function test_indexOf_offsetAtExactMatch() public pure {
        assertEq(StringUtils.indexOf("abcabc", "abc", 3), 3);
    }

    function test_indexOf_offsetBeyondLength() public pure {
        assertEq(StringUtils.indexOf("abcabc", "abc", 10), NOT_FOUND);
    }

    function test_indexOf_offsetSkipsFirstMatch() public pure {
        assertEq(StringUtils.indexOf("abcabc", "abc", 1), 3);
    }

    function test_indexOf_longNeedle() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        string memory subject = string.concat("zzz", needle, "zzz");
        assertEq(StringUtils.indexOf(subject, needle), 3);

        string memory needle33 = "0123456789abcdef0123456789abcdefX"; // 33 bytes
        assertEq(StringUtils.indexOf(string.concat("_", needle33), needle33), 1);
        assertEq(StringUtils.indexOf(subject, needle33), NOT_FOUND);
    }

    function test_indexOf_arbitraryBytes() public pure {
        string memory subject = allBytes();

        for (uint256 i = 0; i < 256; ++i) {
            assertEq(StringUtils.indexOf(subject, singleByte(i)), i);
        }

        assertEq(StringUtils.indexOf(subject, string(abi.encodePacked(bytes2(0x0001)))), 0);
        assertEq(StringUtils.indexOf(subject, string(abi.encodePacked(bytes2(0x8081)))), 128);
        assertEq(StringUtils.indexOf(subject, string(abi.encodePacked(bytes2(0xfeff)))), 254);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indexOf_overloadEquivalence(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.indexOf(subject, needle), StringUtils.indexOf(subject, needle, 0));
    }

    function test_fuzz_indexOf_respectsOffset(string memory subject, string memory needle, uint256 offset) public pure {
        uint256 index = StringUtils.indexOf(subject, needle, offset);
        if (index != NOT_FOUND) {
            assertGe(index, min(offset, bytes(subject).length), "match begins before the requested offset");
        }
    }

    function test_fuzz_indexOf_isLeftmostMatch(string memory subject, string memory needle) public pure {
        vm.assume(bytes(needle).length != 0);

        uint256 index = StringUtils.indexOf(subject, needle);
        if (index != NOT_FOUND) {
            assertEq(StringUtils.slice(subject, index, bytes(needle).length), needle, "index is not a real match");
            for (uint256 i = 0; i < index; ++i) {
                assertFalse(matchesAt(bytes(subject), bytes(needle), i), "an earlier match exists");
            }
        }
    }

    function test_fuzz_indexOf_foundImpliesValidMatch(string memory subject, string memory needle) public pure {
        uint256 index = StringUtils.indexOf(subject, needle);
        if (index != NOT_FOUND) {
            bytes memory subjectBytes = bytes(subject);
            bytes memory needleBytes = bytes(needle);

            uint256 subjectLength = subjectBytes.length;
            uint256 needleLength = needleBytes.length;
            assertLe(index + needleLength, subjectLength, "match runs past the subject");

            for (uint256 i = 0; i < needleLength; ++i) {
                assertEq(subjectBytes[index + i], needleBytes[i], "index is not a real match");
            }
        }
    }

    function test_fuzz_indexOf_notFoundMeansAbsent(string memory subject, string memory needle) public pure {
        bytes memory subjectBytes = bytes(subject);
        bytes memory needleBytes = bytes(needle);

        uint256 subjectLength = subjectBytes.length;
        uint256 needleLength = needleBytes.length;
        vm.assume(needleLength != 0 && subjectLength >= needleLength);

        uint256 index = StringUtils.indexOf(subject, needle);
        assertEq(index != NOT_FOUND, vm.contains(subject, needle), "match existence disagrees with contains");

        if (index == NOT_FOUND) {
            for (uint256 i = 0; i <= subjectLength - needleLength; ++i) {
                assertFalse(matchesAt(bytes(subject), bytes(needle), i), "a match exists despite `NOT_FOUND`");
            }
        }
    }

    function test_fuzz_indexOf_offsetMonotone(string memory subject, string memory needle, uint256 offset) public pure {
        offset = bound(offset, 0, bytes(subject).length);
        uint256 fromZero = StringUtils.indexOf(subject, needle);
        uint256 fromOffset = StringUtils.indexOf(subject, needle, offset);

        // result from offset >= result from 0 (when both found)
        if (fromZero != NOT_FOUND && fromOffset != NOT_FOUND) {
            assertGe(fromOffset, fromZero, "later search offset returned an earlier match");
        }
    }

    function test_fuzz_indexOf(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.indexOf(subject, needle), vm.indexOf(subject, needle));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indexOf_differential(string memory subject, string memory needle, uint256 offset) public pure {
        assertEq(StringUtils.indexOf(subject, needle, offset), referenceIndexOf(subject, needle, offset));
    }

    function test_fuzz_indexOf_differential(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.indexOf(subject, needle), referenceIndexOf(subject, needle, 0));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceIndexOf(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        offset = min(offset, bytes(subject).length);
        if (bytes(needle).length == 0) return offset;

        for (uint256 i = offset; i + bytes(needle).length <= bytes(subject).length; ++i) {
            if (matchesAt(bytes(subject), bytes(needle), i)) return i;
        }

        return NOT_FOUND;
    }
}
