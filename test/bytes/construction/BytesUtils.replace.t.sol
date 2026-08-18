// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsReplaceTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_replace_basic() public pure {
        assertEq(BytesUtils.replace("hello world", "world", "solidity"), "hello solidity");
        assertEq(BytesUtils.replace("foobarfoobar", "foo", "baz"), "bazbarbazbar");
        assertEq(BytesUtils.replace("aXbXc", "X", "-"), "a-b-c");
        assertEq(BytesUtils.replace("a-b", "-", "___"), "a___b");
    }

    function test_replace_allOccurrences() public pure {
        assertEq(BytesUtils.replace("aaa", "a", "b"), "bbb");
        assertEq(BytesUtils.replace("a", "a", "bbb"), "bbb");
    }

    function test_replace_nonOverlapping() public pure {
        assertEq(BytesUtils.replace("aaa", "aa", "x"), "xa");
        assertEq(BytesUtils.replace("aaaa", "aa", "x"), "xx");
        assertEq(BytesUtils.replace("banana", "na", ""), "ba");
    }

    function test_replace_exactMatch() public pure {
        assertEq(BytesUtils.replace("hello", "hello", "world"), "world");
        assertEq(BytesUtils.replace("abc", "abc", "x"), "x");
        assertEq(BytesUtils.replace("abc", "abc", ""), "");
    }

    function test_replace_noMatch() public pure {
        assertEq(BytesUtils.replace("hello", "world", "solidity"), "hello");
        assertEq(BytesUtils.replace("abc", "x", "y"), "abc");
        assertEq(BytesUtils.replace("aa", "aaa", "bbb"), "aa");
    }

    function test_replace_emptySubject() public pure {
        assertEq(BytesUtils.replace("", "", "a"), "a");
        assertEq(BytesUtils.replace("", "a", "b"), "");
        assertEq(BytesUtils.replace("", "", ""), "");
    }

    function test_replace_singleCharSubject() public pure {
        assertEq(BytesUtils.replace("a", "a", "b"), "b");
        assertEq(BytesUtils.replace("a", "a", "bb"), "bb");
        assertEq(BytesUtils.replace("a", "aa", "bb"), "a");
    }

    function test_replace_emptyNeedle() public pure {
        assertEq(BytesUtils.replace("abc", "", "-"), "-a-b-c-");
        assertEq(BytesUtils.replace("abc", "", ""), "abc");
        assertEq(BytesUtils.replace("a", "", "x"), "xax");
    }

    function test_replace_emptyNeedle_insertsAtEveryGap() public pure {
        assertEq(BytesUtils.replace("abc", "", "X"), "XaXbXcX");
        assertEq(BytesUtils.replace("abc", "", ""), "abc");
        assertEq(BytesUtils.replace("", "", "X"), "X");
    }

    function test_replace_needleLongerThanSubject() public pure {
        assertEq(BytesUtils.replace("hi", "hello", "x"), "hi");
        assertEq(BytesUtils.replace("abc", "abcdef", "x"), "abc");
    }

    function test_replace_needleLongerThanWord() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        bytes memory needle33 = bytes.concat(needle, "X"); // 33 bytes

        assertEq(BytesUtils.replace(bytes.concat("L", needle, "R"), needle33, "*"), bytes.concat("L", needle, "R"));
        assertEq(BytesUtils.replace(bytes.concat("L", needle33, "R"), needle33, "*"), "L*R");
    }

    function test_replace_needleAtStartAndEnd() public pure {
        assertEq(BytesUtils.replace(",a,b,", ",", "|"), "|a|b|");
    }

    function test_replace_emptyReplacement_deletesMatches() public pure {
        assertEq(BytesUtils.replace("hello world", "world", ""), "hello ");
    }

    function test_replace_replacementContainsNeedle() public pure {
        assertEq(BytesUtils.replace("abc", "b", "bb"), "abbc");
    }

    function test_replace_arbitraryBytes() public pure {
        bytes memory subject = allBytes();
        assertEq(BytesUtils.replace(subject, singleByte(0x00), "").length, 255);
        assertEq(BytesUtils.replace(subject, singleByte(0xff), "ab").length, 257);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_replace_selfReplacementIsIdentity(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.replace(subject, needle, needle), subject, "self-replacement changed subject");
    }

    function test_fuzz_replace_outputLengthFromIndices(
        bytes memory subject,
        bytes memory needle,
        bytes memory replacement
    ) public pure {
        uint256 matches = BytesUtils.indicesOf(subject, needle).length;
        int256 delta = int256(replacement.length) - int256(needle.length);
        int256 expectedLength = int256(subject.length) + int256(matches) * delta;
        bytes memory result = BytesUtils.replace(subject, needle, replacement);
        assertEq(int256(result.length), expectedLength, "output length does not account for all replacements");
    }

    function test_fuzz_replace_emptyNeedle(bytes memory subject, bytes memory replacement) public pure {
        vm.assume(subject.length != 0);
        vm.assume(replacement.length != 0);

        bytes memory needle = "";
        bytes[] memory segments = BytesUtils.split(subject, needle);

        bytes memory expected = bytes.concat(replacement, BytesUtils.join(segments, replacement), replacement);
        bytes memory result = BytesUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "empty-needle replacement produced incorrect result");
        assertMemoryInvariants(result);
    }

    function test_fuzz_replace_emptyReplacement(bytes memory s, bytes memory n) public pure {
        vm.assume(n.length != 0);

        bytes memory subject = boundAscii(s);
        bytes memory needle = boundAscii(n);
        bytes memory replacement = "";
        bytes memory result = BytesUtils.replace(subject, needle, replacement);

        assertEq(vm.indexOf(string(result), string(needle)), NOT_FOUND, "deleted needle remains in result");
        assertFalse(vm.contains(string(result), string(needle)), "result still contains deleted needle");
    }

    function test_fuzz_replace_emptyReplacement_deletesMatches(bytes[] memory segments) public pure {
        vm.assume(segments.length > 2);

        bytes memory needle = "---";
        bytes memory subject = BytesUtils.join(segments, needle);

        assertTrue(vm.contains(string(subject), string(needle)), "constructed subject does not contain needle");
        assertNotEq(vm.indexOf(string(subject), string(needle)), NOT_FOUND, "constructed needle was not found");

        bytes memory replacement = "";
        bytes memory result = BytesUtils.replace(subject, needle, replacement);

        assertEq(vm.indexOf(string(result), string(needle)), NOT_FOUND, "deleted needle remains in result");
        assertFalse(vm.contains(string(result), string(needle)), "result still contains deleted needle");
        assertMemoryInvariants(result);
    }

    function test_fuzz_replace_doesNotRescanReplacement(bytes memory subject, bytes memory needle) public pure {
        vm.assume(needle.length != 0);

        bytes memory replacement = bytes.concat(needle, needle);
        uint256 matches = BytesUtils.indicesOf(subject, needle).length;

        uint256 expectedLength = subject.length + matches * needle.length;
        bytes memory result = BytesUtils.replace(subject, needle, replacement);
        assertEq(result.length, expectedLength, "replacement bytes were rescanned");
    }

    function test_fuzz_replace_noMatchMeansIdentity(bytes memory subject) public pure {
        // Use a needle that cannot appear in a printable ASCII subject.
        bytes memory needle = abi.encodePacked(bytes1(0x01));
        bytes memory replacement = "x";
        vm.assume(!vm.contains(string(subject), string(needle)));

        bytes memory result = BytesUtils.replace(subject, needle, replacement);
        assertEq(result, subject, "replacement without a match changed subject");
    }

    function test_fuzz_replace(bytes memory subject, bytes memory needle, bytes memory replacement) public pure {
        vm.assume(needle.length != 0);

        subject = boundAscii(subject);
        needle = boundAscii(needle);
        replacement = boundAscii(replacement);

        bytes memory expected = bytes(vm.replace(string(subject), string(needle), string(replacement)));
        bytes memory result = BytesUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "result differs from vm.replace");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_replace_differential(bytes memory subject, bytes memory needle, bytes memory replacement)
        public
        pure
    {
        bytes memory expected = referenceReplace(subject, needle, replacement);
        bytes memory result = BytesUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceReplace(bytes memory subject, bytes memory needle, bytes memory replacement)
        internal
        pure
        returns (bytes memory result)
    {
        if (needle.length == 0) {
            result = new bytes(subject.length + (subject.length + 1) * replacement.length);
            uint256 offset = 0;

            for (uint256 i = 0; i < subject.length; ++i) {
                for (uint256 j = 0; j < replacement.length; ++j) {
                    result[offset++] = replacement[j];
                }
                result[offset++] = subject[i];
            }

            for (uint256 j = 0; j < replacement.length; ++j) {
                result[offset++] = replacement[j];
            }
        } else {
            // First pass: count non-overlapping occurrences.
            uint256 count = 0;

            for (uint256 i = 0; i + needle.length <= subject.length;) {
                if (matchesAt(subject, needle, i)) {
                    i += needle.length;
                    ++count;
                } else {
                    ++i;
                }
            }

            // Second pass: construct the result.
            uint256 length = replacement.length >= needle.length
                ? subject.length + count * (replacement.length - needle.length)
                : subject.length - count * (needle.length - replacement.length);

            result = new bytes(length);

            uint256 readOffset = 0;
            uint256 writeOffset = 0;

            while (readOffset < subject.length) {
                if (readOffset + needle.length <= subject.length && matchesAt(subject, needle, readOffset)) {
                    for (uint256 j = 0; j < replacement.length; ++j) {
                        result[writeOffset++] = replacement[j];
                    }
                    readOffset += needle.length;
                } else {
                    result[writeOffset++] = subject[readOffset++];
                }
            }
        }
    }
}
