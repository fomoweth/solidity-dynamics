// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract BytesUtilsIndicesOfTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_indicesOf_basic() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("abcabcabc", "abc");
        assertEq(indices.length, 3);
        assertEq(indices[0], 0);
        assertEq(indices[1], 3);
        assertEq(indices[2], 6);

        indices = BytesUtils.indicesOf("aXbXc", "X");
        assertEq(indices.length, 2);
        assertEq(indices[0], 1);
        assertEq(indices[1], 3);
    }

    function test_indicesOf_emptySubject() public pure {
        uint256[] memory indices = new uint256[](0);
        assertEq(BytesUtils.indicesOf("", "a"), indices);
        assertEq(BytesUtils.indicesOf("", "abc"), indices);
    }

    function test_indicesOf_emptyNeedle() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("abc", "");
        assertEq(indices.length, 4);
        for (uint256 i = 0; i < indices.length; ++i) {
            assertEq(indices[i], i);
        }
    }

    function test_indicesOf_emptySubjectAndNeedle() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("", "");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_needleLongerThanSubject() public pure {
        assertEq(BytesUtils.indicesOf("a", "abc"), new uint256[](0));
    }

    function test_indicesOf_noMatch() public pure {
        assertEq(BytesUtils.indicesOf("abc", "xyz"), new uint256[](0));
    }

    function test_indicesOf_nonOverlapping() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("aaa", "aa");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_exactMatch() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("abc", "abc");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_adjacentMatches() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("aaaa", "a");
        assertEq(indices.length, 4);
        for (uint256 i = 0; i < 4; ++i) {
            assertEq(indices[i], i);
        }
    }

    function test_indicesOf_matchAtStartAndEnd() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("abXab", "ab");
        assertEq(indices.length, 2);
        assertEq(indices[0], 0);
        assertEq(indices[1], 3);
    }

    function test_indicesOf_singleMatch() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("hello world", "world");
        assertEq(indices.length, 1);
        assertEq(indices[0], 6);
    }

    function test_indicesOf_singleChar() public pure {
        uint256[] memory indices = BytesUtils.indicesOf("a", "a");
        assertEq(indices.length, 1);
        assertEq(indices[0], 0);
    }

    function test_indicesOf_longNeedle() public pure {
        bytes memory needle = "0123456789ABCDEFabcdef0123456789ABCDEFabcdef";
        bytes memory subject = bytes.concat(needle, "z", needle);
        uint256[] memory indices = BytesUtils.indicesOf(subject, needle);
        assertEq(indices.length, 2);
        assertEq(indices[0], 0);
        assertEq(indices[1], needle.length + 1);
    }

    function test_indicesOf_arbitraryBytes() public pure {
        bytes memory subject = bytes(allBytes());
        uint256[] memory indices;

        for (uint256 i = 0; i < 256; ++i) {
            indices = BytesUtils.indicesOf(subject, abi.encodePacked(uint8(i)));
            assertEq(indices.length, 1);
            assertEq(indices[0], i);
        }

        indices = BytesUtils.indicesOf(subject, abi.encodePacked(bytes2(0xfeff)));
        assertEq(indices.length, 1);
        assertEq(indices[0], 254);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indicesOf_indicesAreOrderedAndNonOverlapping(bytes memory subject, bytes memory needle)
        public
        pure
    {
        uint256[] memory indices = BytesUtils.indicesOf(subject, needle);

        for (uint256 i = 0; i < indices.length; ++i) {
            assertLe(indices[i] + needle.length, subject.length, "match runs past the subject");
            assertEq(BytesUtils.slice(subject, indices[i], needle.length), needle, "index is not a real match");

            if (i != 0) {
                assertGt(indices[i], indices[i - 1], "indices are not strictly increasing");
                // Non-empty matches are consumed in full, so they cannot overlap.
                assertGe(indices[i], indices[i - 1] + needle.length, "matches overlap");
            }
        }
    }

    function test_fuzz_indicesOf_agreesWithIndexOf(bytes memory subject, bytes memory needle) public pure {
        uint256[] memory indices = BytesUtils.indicesOf(subject, needle);

        if (indices.length == 0) {
            assertEq(BytesUtils.indexOf(subject, needle), NOT_FOUND, "indexOf found a match when indicesOf found none");
        } else {
            assertEq(indices[0], BytesUtils.indexOf(subject, needle), "first indicesOf match differs from indexOf");

            // `lastIndexOf` scans every start position, so it may find an overlapping occurrence
            // that the non-overlapping sweep skipped; it can never find an earlier one.
            assertGe(
                BytesUtils.lastIndexOf(subject, needle),
                indices[indices.length - 1],
                "lastIndexOf returned an earlier match than indicesOf"
            );
        }
    }

    function test_fuzz_indicesOf(bytes memory subject, bytes memory needle) public pure {
        uint256 offset = coalesce(needle.length, 1);
        uint256[] memory indices = BytesUtils.indicesOf(subject, needle);

        for (uint256 i = 0; i < indices.length; ++i) {
            assertEq(BytesUtils.slice(subject, indices[i], needle.length), needle, "index is not a real match");
            if (i != 0) {
                assertGe(indices[i], indices[i - 1] + offset, "matches overlap or indices are not strictly increasing");
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_indicesOf_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.indicesOf(subject, needle), referenceIndicesOf(subject, needle));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceIndicesOf(bytes memory subject, bytes memory needle)
        internal
        pure
        returns (uint256[] memory indices)
    {
        indices = new uint256[](subject.length + 1);
        uint256 length = 0;

        for (uint256 i = 0; i + needle.length <= subject.length;) {
            if (matchesAt(subject, needle, i)) {
                indices[length++] = i;
                if (needle.length != 0) {
                    i += needle.length;
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
