// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsEndsWithTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_endsWith_basic() public pure {
        assertTrue(StringUtils.endsWith("hello world", "world"));
        assertFalse(StringUtils.endsWith("hello world", "hello"));
        assertFalse(StringUtils.endsWith("hello world", "worlD"));
    }

    function test_endsWith_exactMatch() public pure {
        assertTrue(StringUtils.endsWith("abc", "abc"));
    }

    function test_endsWith_noMatch() public pure {
        assertFalse(StringUtils.endsWith("abc", "xyz"));
    }

    function test_endsWith_singleChar() public pure {
        assertTrue(StringUtils.endsWith("abc", "c"));
        assertFalse(StringUtils.endsWith("abc", "b"));
    }

    function test_endsWith_emptySubjectAndNeedle() public pure {
        assertTrue(StringUtils.endsWith("", ""));
    }

    function test_endsWith_emptySubject() public pure {
        assertFalse(StringUtils.endsWith("", "a"));
    }

    function test_endsWith_emptyNeedle() public pure {
        assertTrue(StringUtils.endsWith("abc", ""));
    }

    function test_endsWith_needleLongerThanSubject() public pure {
        assertFalse(StringUtils.endsWith("ab", "abc"));
        assertFalse(StringUtils.endsWith("bc", "abc"));
    }

    function test_endsWith_longNeedle() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertTrue(StringUtils.endsWith(string.concat("head", needle), needle));
        assertTrue(StringUtils.endsWith(needle, needle));
        assertFalse(StringUtils.endsWith(string.concat(needle, "tail"), needle));
        assertFalse(StringUtils.endsWith(needle, string.concat(needle, "X")));
    }

    function test_endsWith_arbitraryBytes() public pure {
        string memory subject = allBytes();
        assertTrue(StringUtils.endsWith(subject, subject));
        assertTrue(StringUtils.endsWith(subject, singleByte(0xff)));

        for (uint256 i = 0; i < 255; ++i) {
            assertFalse(StringUtils.endsWith(subject, singleByte(i)));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_endsWith_emptyNeedle(string memory subject) public pure {
        assertTrue(StringUtils.endsWith(subject, ""), "empty needle was not recognized as suffix");
    }

    function test_fuzz_endsWith_reflexive(string memory subject) public pure {
        assertTrue(StringUtils.endsWith(subject, subject), "subject was not recognized as its own suffix");
    }

    function test_fuzz_endsWith_sliceIsSuffix(string memory subject, uint256 offset) public pure {
        string memory suffix = StringUtils.slice(subject, bound(offset, 0, bytes(subject).length));
        assertTrue(StringUtils.endsWith(subject, suffix), "sliced suffix was not recognized");
    }

    function test_fuzz_endsWith_concat(string memory prefix, string memory suffix) public pure {
        string memory subject = string.concat(prefix, suffix);
        assertTrue(StringUtils.endsWith(subject, suffix), "concatenation does not end with suffix");
    }

    function test_fuzz_endsWith_impliesTrailingSlice(string memory subject, string memory needle) public pure {
        if (StringUtils.endsWith(subject, needle)) {
            uint256 offset = bytes(subject).length - bytes(needle).length;
            string memory suffix = StringUtils.slice(subject, offset);
            assertEq(suffix, needle, "recognized suffix does not match trailing bytes");

            uint256 index = StringUtils.lastIndexOf(subject, needle);
            assertEq(index, offset, "recognized suffix was not found at trailing offset");
        }
    }

    function test_fuzz_endsWith_needleLongerThanSubject(string memory subject, string memory needle) public pure {
        vm.assume(bytes(needle).length > bytes(subject).length);
        assertFalse(StringUtils.endsWith(subject, needle), "oversized needle was recognized as suffix");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_endsWith_differential(string memory subject, string memory needle) public pure {
        assertEq(
            StringUtils.endsWith(subject, needle),
            referenceEndsWith(subject, needle),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceEndsWith(string memory subject, string memory needle) internal pure returns (bool) {
        bytes memory subjectBytes = bytes(subject);
        bytes memory needleBytes = bytes(needle);

        if (needleBytes.length > subjectBytes.length) return false;

        uint256 offset = subjectBytes.length - needleBytes.length;
        for (uint256 i = 0; i < needleBytes.length; ++i) {
            if (subjectBytes[offset + i] != needleBytes[i]) return false;
        }
        return true;
    }
}
