// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsSplitTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_split_basic() public pure {
        assertEq(StringUtils.split("hello world", " "), arrayify("hello", "world"));
        assertEq(StringUtils.split("a,b,c", ","), arrayify("a", "b", "c"));
    }

    function test_split_nonOverlapping() public pure {
        assertEq(StringUtils.split("aaa", "aa"), arrayify("", "a"));
        assertEq(StringUtils.split("aaaa", "aa"), arrayify("", "", ""));
    }

    function test_split_exactMatch() public pure {
        assertEq(StringUtils.split("abc", "abc"), arrayify("", ""));
    }

    function test_split_noMatch() public pure {
        assertEq(StringUtils.split("abc", "x"), arrayify("abc"));
    }

    function test_split_singleByteSubject() public pure {
        assertEq(StringUtils.split("a", "a"), arrayify("", ""));
        assertEq(StringUtils.split("a", "b"), arrayify("a"));
    }

    function test_split_emptySubjectAndDelimiter() public pure {
        assertEq(StringUtils.split("", ""), new string[](0));
    }

    function test_split_emptySubject() public pure {
        assertEq(StringUtils.split("", ","), arrayify(""));
    }

    function test_split_emptyDelimiter() public pure {
        assertEq(StringUtils.split("abc", ""), arrayify("a", "b", "c"));
        assertEq(StringUtils.split("a", ""), arrayify("a"));
    }

    function test_split_delimiterLongerThanSubject() public pure {
        assertEq(StringUtils.split("ab", "abc"), arrayify("ab"));
        assertEq(StringUtils.split("", "abc"), arrayify(""));
    }

    function test_split_leadingDelimiter() public pure {
        assertEq(StringUtils.split(",a", ","), arrayify("", "a"));
    }

    function test_split_trailingDelimiter() public pure {
        assertEq(StringUtils.split("a,", ","), arrayify("a", ""));
    }

    function test_split_adjacentDelimiters() public pure {
        assertEq(StringUtils.split("a,,b", ","), arrayify("a", "", "b"));
        assertEq(StringUtils.split(",,", ","), arrayify("", "", ""));
    }

    function test_split_multiByteDelimiter() public pure {
        assertEq(StringUtils.split("a <-> b <-> c", " <-> "), arrayify("a", "b", "c"));
    }

    function test_split_longDelimiter() public pure {
        string memory delimiter = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertEq(StringUtils.split(delimiter, delimiter), arrayify("", ""));

        string memory subject = string.concat("L", delimiter, "R");
        assertEq(StringUtils.split(subject, delimiter), arrayify("L", "R"));

        string memory delimiter33 = string.concat(delimiter, "X"); // 33 bytes
        assertEq(StringUtils.split(subject, delimiter33), arrayify(subject));
        assertEq(StringUtils.split(string.concat("L", delimiter33, "R"), delimiter33), arrayify("L", "R"));
    }

    function test_split_countIsOccurrencesPlusOne() public pure {
        string memory subject = "a.b.c.d.e";
        assertEq(StringUtils.split(subject, ".").length, StringUtils.indicesOf(subject, ".").length + 1);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_split_partCount(string memory subject, string memory delimiter) public pure {
        vm.assume(bytes(delimiter).length != 0);

        assertEq(
            StringUtils.split(subject, delimiter).length,
            StringUtils.indicesOf(subject, delimiter).length + 1,
            "part count does not equal delimiter count plus one"
        );
    }

    function test_fuzz_split_partsAreDelimiterFree(string memory subject, string memory delimiter) public pure {
        vm.assume(bytes(delimiter).length != 0);

        string[] memory segments = StringUtils.split(subject, delimiter);
        uint256 total = (segments.length - 1) * bytes(delimiter).length;

        for (uint256 i = 0; i < segments.length; ++i) {
            assertFalse(StringUtils.contains(segments[i], delimiter), "split segment still contains delimiter");
            total += bytes(segments[i]).length;
        }
        assertEq(total, bytes(subject).length, "split lengths do not reconstruct subject length");
    }

    function test_fuzz_split_emptyDelimiter(string memory subject) public pure {
        bytes memory buffer = bytes(subject);
        string[] memory segments = StringUtils.split(subject, "");
        assertEq(segments.length, buffer.length, "empty delimiter produced incorrect part count");

        for (uint256 i = 0; i < segments.length; ++i) {
            assertEq(bytes(segments[i]).length, 1, "empty delimiter produced non-single-byte segment");
            assertEq(bytes(segments[i])[0], buffer[i], "single-byte segment differs from subject byte");
        }
    }

    function test_fuzz_split_joinRoundTrip(string memory subject, string memory delimiter) public pure {
        vm.assume(bytes(delimiter).length != 0);

        assertEq(
            StringUtils.join(StringUtils.split(subject, delimiter), delimiter),
            subject,
            "joining split segments did not reconstruct subject"
        );
    }

    function test_fuzz_split_agreesWithCheatcode(string memory subject, string memory delimiter) public pure {
        vm.assume(bytes(subject).length != 0 && bytes(delimiter).length != 0);
        assertEq(StringUtils.split(subject, delimiter), vm.split(subject, delimiter), "result differs from cheatcode");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_split_differential(string memory subject, string memory delimiter) public pure {
        assertEq(
            StringUtils.split(subject, delimiter),
            referenceSplit(subject, delimiter),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceSplit(string memory subject, string memory delimiter)
        internal
        pure
        returns (string[] memory segments)
    {
        bytes memory subjectBytes = bytes(subject);
        bytes memory delimiterBytes = bytes(delimiter);

        uint256 subjectLength = subjectBytes.length;
        uint256 delimiterLength = delimiterBytes.length;

        if (delimiterLength == 0) {
            segments = new string[](subjectLength);

            for (uint256 i = 0; i < subjectLength; ++i) {
                bytes memory segment = new bytes(1);
                segment[0] = subjectBytes[i];
                segments[i] = string(segment);
            }

            return segments;
        }

        uint256 count = 0;
        uint256 cursor = 0;

        // Count non-overlapping occurrences.
        while (cursor + delimiterLength <= subjectLength) {
            if (matchesAt(subjectBytes, delimiterBytes, cursor)) {
                ++count;
                cursor += delimiterLength;
            } else {
                ++cursor;
            }
        }

        segments = new string[](count + 1);

        uint256 previous = 0;
        uint256 index = 0;
        cursor = 0;

        while (cursor + delimiterLength <= subjectLength) {
            if (matchesAt(subjectBytes, delimiterBytes, cursor)) {
                segments[index++] = StringUtils.slice(string(subjectBytes), previous, cursor - previous);
                cursor += delimiterLength;
                previous = cursor;
            } else {
                ++cursor;
            }
        }

        segments[index] = StringUtils.slice(string(subjectBytes), previous, subjectLength - previous);
    }
}
