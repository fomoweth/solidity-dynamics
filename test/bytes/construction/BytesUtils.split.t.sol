// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsSplitTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_split_basic() public pure {
        assertEq(BytesUtils.split("hello world", " "), arrayify("hello", "world"));
        assertEq(BytesUtils.split("a,b,c", ","), arrayify("a", "b", "c"));
    }

    function test_split_nonOverlapping() public pure {
        assertEq(BytesUtils.split("aaa", "aa"), arrayify("", "a"));
        assertEq(BytesUtils.split("aaaa", "aa"), arrayify("", "", ""));
    }

    function test_split_exactMatch() public pure {
        assertEq(BytesUtils.split("abc", "abc"), arrayify("", ""));
    }

    function test_split_noMatch() public pure {
        assertEq(BytesUtils.split("abc", "x"), arrayify("abc"));
    }

    function test_split_singleByteSubject() public pure {
        assertEq(BytesUtils.split("a", "a"), arrayify("", ""));
        assertEq(BytesUtils.split("a", "b"), arrayify("a"));
    }

    function test_split_emptySubjectAndDelimiter() public pure {
        assertEq(BytesUtils.split("", ""), new bytes[](0));
    }

    function test_split_emptySubject() public pure {
        assertEq(BytesUtils.split("", ","), arrayify(""));
        assertEq(BytesUtils.split("", "abc"), arrayify(""));
    }

    function test_split_emptyDelimiter() public pure {
        assertEq(BytesUtils.split("abc", ""), arrayify("a", "b", "c"));
        assertEq(BytesUtils.split("a", ""), arrayify("a"));
    }

    function test_split_delimiterLongerThanSubject() public pure {
        assertEq(BytesUtils.split("ab", "abc"), arrayify("ab"));
        assertEq(BytesUtils.split("", "abc"), arrayify(""));
    }

    function test_split_leadingDelimiter() public pure {
        assertEq(BytesUtils.split(",a", ","), arrayify("", "a"));
    }

    function test_split_trailingDelimiter() public pure {
        assertEq(BytesUtils.split("a,", ","), arrayify("a", ""));
    }

    function test_split_adjacentDelimiters() public pure {
        assertEq(BytesUtils.split("a,,b", ","), arrayify("a", "", "b"));
        assertEq(BytesUtils.split(",,", ","), arrayify("", "", ""));
    }

    function test_split_multiByteDelimiter() public pure {
        assertEq(BytesUtils.split("a <-> b <-> c", " <-> "), arrayify("a", "b", "c"));
    }

    function test_split_longDelimiter() public pure {
        bytes memory delimiter = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertEq(BytesUtils.split(delimiter, delimiter), arrayify("", ""));

        bytes memory subject = bytes.concat("L", delimiter, "R");
        assertEq(BytesUtils.split(subject, delimiter), arrayify("L", "R"));

        bytes memory delimiter33 = bytes.concat(delimiter, "X"); // 33 bytes
        assertEq(BytesUtils.split(subject, delimiter33), arrayify(subject));
        assertEq(BytesUtils.split(bytes.concat("L", delimiter33, "R"), delimiter33), arrayify("L", "R"));
    }

    function test_split_countIsOccurrencesPlusOne() public pure {
        bytes memory subject = "a.b.c.d.e";
        assertEq(BytesUtils.split(subject, ".").length, BytesUtils.indicesOf(subject, ".").length + 1);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_split_partCount(bytes memory subject, bytes memory delimiter) public pure {
        vm.assume(delimiter.length != 0);

        assertEq(
            BytesUtils.split(subject, delimiter).length,
            BytesUtils.indicesOf(subject, delimiter).length + 1,
            "part count does not equal delimiter count plus one"
        );
    }

    function test_fuzz_split_partsAreDelimiterFree(bytes memory subject, bytes memory delimiter) public pure {
        vm.assume(delimiter.length != 0);

        bytes[] memory segments = BytesUtils.split(subject, delimiter);
        uint256 total = (segments.length - 1) * delimiter.length;

        for (uint256 i = 0; i < segments.length; ++i) {
            assertFalse(BytesUtils.contains(segments[i], delimiter), "split segment still contains delimiter");
            total += segments[i].length;
        }
        assertEq(total, subject.length, "split lengths do not reconstruct subject length");
    }

    function test_fuzz_split_emptyDelimiter(bytes memory subject) public pure {
        bytes[] memory segments = BytesUtils.split(subject, "");
        assertEq(segments.length, subject.length, "empty delimiter produced incorrect part count");

        for (uint256 i = 0; i < segments.length; ++i) {
            assertEq(segments[i].length, 1, "empty delimiter produced non-single-byte segment");
            assertEq(segments[i][0], subject[i], "single-byte segment differs from subject byte");
        }
    }

    function test_fuzz_split_joinRoundTrip(bytes memory subject, bytes memory delimiter) public pure {
        vm.assume(delimiter.length != 0);

        assertEq(
            BytesUtils.join(BytesUtils.split(subject, delimiter), delimiter),
            subject,
            "joining split segments did not reconstruct subject"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_split_differential(bytes memory subject, bytes memory delimiter) public pure {
        assertEq(
            BytesUtils.split(subject, delimiter),
            referenceSplit(subject, delimiter),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceSplit(bytes memory subject, bytes memory delimiter)
        internal
        pure
        returns (bytes[] memory segments)
    {
        if (delimiter.length == 0) {
            segments = new bytes[](subject.length);

            for (uint256 i = 0; i < subject.length; ++i) {
                bytes memory segment = new bytes(1);
                segment[0] = subject[i];
                segments[i] = segment;
            }
        } else {
            uint256 count = 0;
            uint256 cursor = 0;

            // Count non-overlapping occurrences.
            while (cursor + delimiter.length <= subject.length) {
                if (matchesAt(subject, delimiter, cursor)) {
                    ++count;
                    cursor += delimiter.length;
                } else {
                    ++cursor;
                }
            }

            segments = new bytes[](count + 1);

            uint256 previous = 0;
            uint256 index = 0;
            cursor = 0;

            while (cursor + delimiter.length <= subject.length) {
                if (matchesAt(subject, delimiter, cursor)) {
                    segments[index++] = BytesUtils.slice(subject, previous, cursor - previous);
                    cursor += delimiter.length;
                    previous = cursor;
                } else {
                    ++cursor;
                }
            }

            segments[index] = BytesUtils.slice(subject, previous, subject.length - previous);
        }
    }
}
