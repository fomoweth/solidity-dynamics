// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsReplaceTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_replace_basic() public pure {
        assertEq(StringUtils.replace("hello world", "world", "solidity"), "hello solidity");
        assertEq(StringUtils.replace("foobarfoobar", "foo", "baz"), "bazbarbazbar");
        assertEq(StringUtils.replace("aXbXc", "X", "-"), "a-b-c");
        assertEq(StringUtils.replace("a-b", "-", "___"), "a___b");
    }

    function test_replace_allOccurrences() public pure {
        assertEq(StringUtils.replace("aaa", "a", "b"), "bbb");
        assertEq(StringUtils.replace("a", "a", "bbb"), "bbb");
    }

    function test_replace_nonOverlapping() public pure {
        assertEq(StringUtils.replace("aaa", "aa", "x"), "xa");
        assertEq(StringUtils.replace("aaaa", "aa", "x"), "xx");
        assertEq(StringUtils.replace("banana", "na", ""), "ba");
    }

    function test_replace_exactMatch() public pure {
        assertEq(StringUtils.replace("hello", "hello", "world"), "world");
        assertEq(StringUtils.replace("abc", "abc", "x"), "x");
        assertEq(StringUtils.replace("abc", "abc", ""), "");
    }

    function test_replace_noMatch() public pure {
        assertEq(StringUtils.replace("hello", "world", "solidity"), "hello");
        assertEq(StringUtils.replace("abc", "x", "y"), "abc");
        assertEq(StringUtils.replace("aa", "aaa", "bbb"), "aa");
    }

    function test_replace_emptySubject() public pure {
        assertEq(StringUtils.replace("", "", "a"), "a");
        assertEq(StringUtils.replace("", "a", "b"), "");
        assertEq(StringUtils.replace("", "", ""), "");
    }

    function test_replace_singleCharSubject() public pure {
        assertEq(StringUtils.replace("a", "a", "b"), "b");
        assertEq(StringUtils.replace("a", "a", "bb"), "bb");
        assertEq(StringUtils.replace("a", "aa", "bb"), "a");
    }

    function test_replace_emptyNeedle() public pure {
        assertEq(StringUtils.replace("abc", "", "-"), "-a-b-c-");
        assertEq(StringUtils.replace("abc", "", ""), "abc");
        assertEq(StringUtils.replace("a", "", "x"), "xax");
    }

    function test_replace_emptyNeedle_insertsAtEveryGap() public pure {
        assertEq(StringUtils.replace("abc", "", "X"), "XaXbXcX");
        assertEq(StringUtils.replace("abc", "", ""), "abc");
        assertEq(StringUtils.replace("", "", "X"), "X");
    }

    function test_replace_needleLongerThanSubject() public pure {
        assertEq(StringUtils.replace("hi", "hello", "x"), "hi");
        assertEq(StringUtils.replace("abc", "abcdef", "x"), "abc");
    }

    function test_replace_needleLongerThanWord() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        string memory needle33 = string.concat(needle, "X"); // 33 bytes

        assertEq(StringUtils.replace(string.concat("L", needle, "R"), needle33, "*"), string.concat("L", needle, "R"));
        assertEq(StringUtils.replace(string.concat("L", needle33, "R"), needle33, "*"), "L*R");
    }

    function test_replace_needleAtStartAndEnd() public pure {
        assertEq(StringUtils.replace(",a,b,", ",", "|"), "|a|b|");
    }

    function test_replace_emptyReplacement_deletesMatches() public pure {
        assertEq(StringUtils.replace("hello world", "world", ""), "hello ");
    }

    function test_replace_replacementContainsNeedle() public pure {
        assertEq(StringUtils.replace("abc", "b", "bb"), "abbc");
    }

    function test_replace_arbitraryBytes() public pure {
        string memory subject = allBytes();
        assertEq(bytes(StringUtils.replace(subject, singleByte(0x00), "")).length, 255);
        assertEq(bytes(StringUtils.replace(subject, singleByte(0xff), "ab")).length, 257);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_replace_selfReplacementIsIdentity(string memory subject, string memory needle) public pure {
        assertEq(StringUtils.replace(subject, needle, needle), subject, "self-replacement changed subject");
    }

    function test_fuzz_replace_outputLengthFromIndices(
        string memory subject,
        string memory needle,
        string memory replacement
    ) public pure {
        uint256 matches = StringUtils.indicesOf(subject, needle).length;
        int256 delta = int256(bytes(replacement).length) - int256(bytes(needle).length);
        int256 expectedLength = int256(bytes(subject).length) + int256(matches) * delta;
        string memory result = StringUtils.replace(subject, needle, replacement);
        assertEq(int256(bytes(result).length), expectedLength, "output length does not account for all replacements");
    }

    function test_fuzz_replace_emptyNeedle(string memory subject, string memory replacement) public pure {
        vm.assume(bytes(subject).length != 0);
        vm.assume(bytes(replacement).length != 0);

        string memory needle = "";
        string[] memory segments = StringUtils.split(subject, needle);

        string memory expected = string.concat(replacement, StringUtils.join(segments, replacement), replacement);
        string memory result = StringUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "empty-needle replacement produced incorrect result");
        assertMemoryInvariants(result);
    }

    function test_fuzz_replace_emptyReplacement(string memory subject, string memory needle) public pure {
        vm.assume(bytes(needle).length != 0);

        string memory replacement = "";
        string memory result = StringUtils.replace(subject, needle, replacement);

        assertEq(vm.indexOf(result, needle), NOT_FOUND, "deleted needle remains in result");
        assertFalse(vm.contains(result, needle), "result still contains deleted needle");
    }

    function test_fuzz_replace_emptyReplacement_deletesMatches(string[] memory segments) public pure {
        vm.assume(segments.length > 2);

        string memory needle = "---";
        string memory subject = StringUtils.join(segments, needle);

        assertTrue(vm.contains(subject, needle), "constructed subject does not contain needle");
        assertNotEq(vm.indexOf(subject, needle), NOT_FOUND, "constructed needle was not found");

        string memory replacement = "";
        string memory result = StringUtils.replace(subject, needle, replacement);

        assertEq(vm.indexOf(result, needle), NOT_FOUND, "deleted needle remains in result");
        assertFalse(vm.contains(result, needle), "result still contains deleted needle");
        assertMemoryInvariants(result);
    }

    function test_fuzz_replace_doesNotRescanReplacement(string memory subject, string memory needle) public pure {
        vm.assume(bytes(needle).length != 0);

        string memory replacement = string.concat(needle, needle);
        uint256 matches = StringUtils.indicesOf(subject, needle).length;

        uint256 expectedLength = bytes(subject).length + matches * bytes(needle).length;
        string memory result = StringUtils.replace(subject, needle, replacement);
        assertEq(bytes(result).length, expectedLength, "replacement bytes were rescanned");
    }

    function test_fuzz_replace_noMatchMeansIdentity(string memory subject) public pure {
        // Use a needle that cannot appear in a printable ASCII subject.
        string memory needle = string(abi.encodePacked(bytes1(0x01)));
        string memory replacement = "x";
        vm.assume(!vm.contains(subject, needle));

        string memory result = StringUtils.replace(subject, needle, replacement);
        assertEq(result, subject, "replacement without a match changed subject");
    }

    function test_fuzz_replace_agreesWithCheatcode(
        string memory subject,
        string memory needle,
        string memory replacement
    ) public pure {
        vm.assume(bytes(needle).length != 0);

        string memory expected = vm.replace(subject, needle, replacement);
        string memory result = StringUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "result differs from cheatcode");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_replace_differential(string memory subject, string memory needle, string memory replacement)
        public
        pure
    {
        string memory expected = referenceReplace(subject, needle, replacement);
        string memory result = StringUtils.replace(subject, needle, replacement);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceReplace(string memory subject, string memory needle, string memory replacement)
        internal
        pure
        returns (string memory)
    {
        bytes memory subjectBytes = bytes(subject);
        bytes memory needleBytes = bytes(needle);
        bytes memory replacementBytes = bytes(replacement);
        bytes memory result;

        uint256 subjectLength = subjectBytes.length;
        uint256 needleLength = needleBytes.length;
        uint256 replacementLength = replacementBytes.length;

        if (needleLength == 0) {
            result = new bytes(subjectLength + (subjectLength + 1) * replacementLength);

            uint256 offset = 0;

            for (uint256 i = 0; i < subjectLength; ++i) {
                for (uint256 j = 0; j < replacementLength; ++j) {
                    result[offset++] = replacementBytes[j];
                }
                result[offset++] = subjectBytes[i];
            }

            for (uint256 j = 0; j < replacementLength; ++j) {
                result[offset++] = replacementBytes[j];
            }
        } else {
            // First pass: count non-overlapping occurrences.
            uint256 count = 0;

            for (uint256 i = 0; i + needleLength <= subjectLength;) {
                if (matchesAt(subjectBytes, needleBytes, i)) {
                    i += needleLength;
                    ++count;
                } else {
                    ++i;
                }
            }

            // Second pass: construct the result.
            uint256 length = replacementLength >= needleLength
                ? subjectLength + count * (replacementLength - needleLength)
                : subjectLength - count * (needleLength - replacementLength);

            result = new bytes(length);

            uint256 readOffset = 0;
            uint256 writeOffset = 0;

            while (readOffset < subjectLength) {
                if (readOffset + needleLength <= subjectLength && matchesAt(subjectBytes, needleBytes, readOffset)) {
                    for (uint256 j = 0; j < replacementLength; ++j) {
                        result[writeOffset++] = replacementBytes[j];
                    }
                    readOffset += needleLength;
                } else {
                    result[writeOffset++] = subjectBytes[readOffset++];
                }
            }
        }

        return string(result);
    }
}
