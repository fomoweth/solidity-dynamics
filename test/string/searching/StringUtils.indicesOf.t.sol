// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract StringUtilsIndicesOfTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_indicesOf_basic() public pure {
        uint256[] memory indices = StringUtils.indicesOf("abcabcabc", "abc");
        assertEq(indices.length, 3);
        assertEq(indices[0], 0);
        assertEq(indices[1], 3);
        assertEq(indices[2], 6);

        indices = StringUtils.indicesOf("aXbXc", "X");
        assertEq(indices.length, 2);
        assertEq(indices[0], 1);
        assertEq(indices[1], 3);
    }

    function test_indicesOf_emptySubject() public pure {
        uint256[] memory indices = new uint256[](0);
        assertEq(StringUtils.indicesOf("", "a"), indices);
        assertEq(StringUtils.indicesOf("", "abc"), indices);
    }

    function test_indicesOf_emptyNeedle() public pure {
        uint256[] memory indices = StringUtils.indicesOf("abc", "");
        assertEq(indices.length, 4);
        for (uint256 i = 0; i < indices.length; ++i) {
            assertEq(indices[i], i);
        }
    }

    function test_indicesOf_emptySubjectAndNeedle() public pure {
        uint256[] memory indices = StringUtils.indicesOf("", "");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_needleLongerThanSubject() public pure {
        assertEq(StringUtils.indicesOf("a", "abc"), new uint256[](0));
    }

    function test_indicesOf_noMatch() public pure {
        assertEq(StringUtils.indicesOf("abc", "xyz"), new uint256[](0));
    }

    function test_indicesOf_nonOverlapping() public pure {
        uint256[] memory indices = StringUtils.indicesOf("aaa", "aa");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_exactMatch() public pure {
        uint256[] memory indices = StringUtils.indicesOf("abc", "abc");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_adjacentMatches() public pure {
        uint256[] memory indices = StringUtils.indicesOf("aaaa", "a");
        assertEq(indices.length, 4);
        for (uint256 i = 0; i < 4; ++i) {
            assertEq(indices[i], i);
        }
    }

    function test_indicesOf_matchAtStartAndEnd() public pure {
        uint256[] memory indices = StringUtils.indicesOf("abXab", "ab");
        assertEq(indices.length, 2);
        assertEq(indices[0], 0);
        assertEq(indices[1], 3);
    }

    function test_indicesOf_singleMatch() public pure {
        uint256[] memory indices = StringUtils.indicesOf("hello world", "world");
        assertEq(indices.length, 1);
        assertEq(indices[0], 6);
    }

    function test_indicesOf_singleChar() public pure {
        uint256[] memory indices = StringUtils.indicesOf("a", "a");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_longNeedle() public pure {
        string memory needle = "0123456789ABCDEFabcdef0123456789ABCDEFabcdef";
        string memory subject = string.concat(needle, "z", needle);
        uint256[] memory indices = StringUtils.indicesOf(subject, needle);
        assertEq(indices.length, 2);
        assertEq(indices[0], 0);
        assertEq(indices[1], bytes(needle).length + 1);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indicesOf_indicesAreOrderedAndNonOverlapping(string memory subject, string memory needle)
        public
        pure
    {
        uint256 needleLength = bytes(needle).length;
        uint256[] memory indices = StringUtils.indicesOf(subject, needle);

        for (uint256 i = 0; i < indices.length; ++i) {
            assertLe(indices[i] + needleLength, bytes(subject).length, "match runs past the subject");
            assertEq(StringUtils.slice(subject, indices[i], needleLength), needle, "index is not a real match");

            if (i != 0) {
                assertGt(indices[i], indices[i - 1], "indices are not strictly increasing");
                // Non-empty matches are consumed in full, so they cannot overlap.
                assertGe(indices[i], indices[i - 1] + needleLength, "matches overlap");
            }
        }
    }

    function test_fuzz_indicesOf_agreesWithIndexOf(string memory subject, string memory needle) public pure {
        uint256[] memory indices = StringUtils.indicesOf(subject, needle);

        if (indices.length == 0) {
            assertEq(StringUtils.indexOf(subject, needle), NOT_FOUND, "indexOf found a match when indicesOf found none");
        } else {
            assertEq(indices[0], StringUtils.indexOf(subject, needle), "first indicesOf match differs from indexOf");

            // `lastIndexOf` scans every start position, so it may find an overlapping occurrence
            // that the non-overlapping sweep skipped; it can never find an earlier one.
            assertGe(
                StringUtils.lastIndexOf(subject, needle),
                indices[indices.length - 1],
                "lastIndexOf returned an earlier match than indicesOf"
            );
        }
    }

    function test_fuzz_indicesOf(string memory subject, string memory needle) public pure {
        uint256 offset = coalesce(bytes(needle).length, 1);
        uint256[] memory indices = StringUtils.indicesOf(subject, needle);

        for (uint256 i = 0; i < indices.length; ++i) {
            assertEq(StringUtils.slice(subject, indices[i], bytes(needle).length), needle, "index is not a real match");
            if (i != 0) {
                assertGe(indices[i], indices[i - 1] + offset, "matches overlap or indices are not strictly increasing");
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indicesOf_differential(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.indicesOf(subject, needle), referenceIndicesOf(subject, needle));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceIndicesOf(string memory subject, string memory needle)
        internal
        pure
        returns (uint256[] memory indices)
    {
        uint256 subjectLength = bytes(subject).length;
        uint256 needleLength = bytes(needle).length;
        uint256 length = 0;

        indices = new uint256[](subjectLength + 1);

        for (uint256 i = 0; i + needleLength <= subjectLength;) {
            if (matchesAt(bytes(subject), bytes(needle), i)) {
                indices[length++] = i;
                if (needleLength != 0) {
                    i += needleLength;
                    continue;
                }
            }
            ++i;
        }

        assembly ("memory-safe") {
            mstore(indices, length)
        }
    }
}
