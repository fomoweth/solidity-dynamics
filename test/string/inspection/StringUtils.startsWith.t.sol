// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsStartsWithTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_startsWith_basic() public pure {
        assertTrue(StringUtils.startsWith("hello world", "hello"));
        assertFalse(StringUtils.startsWith("hello world", "world"));
        assertFalse(StringUtils.startsWith("hello world", "hellO"));
    }

    function test_startsWith_exactMatch() public pure {
        assertTrue(StringUtils.startsWith("abc", "abc"));
    }

    function test_startsWith_singleChar() public pure {
        assertTrue(StringUtils.startsWith("abc", "a"));
        assertFalse(StringUtils.startsWith("abc", "b"));
    }

    function test_startsWith_emptySubjectAndNeedle() public pure {
        assertTrue(StringUtils.startsWith("", ""));
    }

    function test_startsWith_emptySubject() public pure {
        assertFalse(StringUtils.startsWith("", "a"));
    }

    function test_startsWith_emptyNeedle() public pure {
        assertTrue(StringUtils.startsWith("abc", ""));
    }

    function test_startsWith_needleLongerThanSubject() public pure {
        assertFalse(StringUtils.startsWith("ab", "abc"));
    }

    function test_startsWith_longNeedle() public pure {
        string memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertTrue(StringUtils.startsWith(string.concat(needle, "tail"), needle));
        assertTrue(StringUtils.startsWith(needle, needle));
        assertFalse(StringUtils.startsWith(string.concat("head", needle), needle));
        // 33 bytes: differs from the 32-byte needle only past the first word.
        assertFalse(StringUtils.startsWith(needle, string.concat(needle, "X")));
    }

    function test_startsWith_arbitraryBytes() public pure {
        string memory subject = allBytes();
        assertTrue(StringUtils.startsWith(subject, subject));
        assertTrue(StringUtils.startsWith(subject, singleByte(0x00)));

        for (uint256 i = 1; i < 256; ++i) {
            assertFalse(StringUtils.startsWith(subject, singleByte(i)));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_startsWith_emptyNeedle(string memory subject) public pure {
        assertTrue(StringUtils.startsWith(subject, ""), "empty needle was not recognized as prefix");
    }

    function test_fuzz_startsWith_reflexive(string memory subject) public pure {
        assertTrue(StringUtils.startsWith(subject, subject), "subject was not recognized as its own prefix");
    }

    function test_fuzz_startsWith_sliceIsPrefix(string memory subject, uint256 length) public pure {
        string memory prefix = StringUtils.slice(subject, 0, bound(length, 0, bytes(subject).length));
        assertTrue(StringUtils.startsWith(subject, prefix), "sliced prefix was not recognized");
    }

    function test_fuzz_startsWith_concat(string memory prefix, string memory suffix) public pure {
        string memory subject = string.concat(prefix, suffix);
        assertTrue(StringUtils.startsWith(subject, prefix), "concatenation does not start with prefix");
    }

    function test_fuzz_startsWith_impliesIndexOfZero(string memory subject, string memory needle) public pure {
        if (StringUtils.startsWith(subject, needle)) {
            string memory prefix = StringUtils.slice(subject, 0, bytes(needle).length);
            assertEq(prefix, needle, "recognized prefix does not match leading bytes");
            assertEq(StringUtils.indexOf(subject, needle), 0, "recognized prefix was not found at index zero");
        }
    }

    function test_fuzz_startsWith_needleLongerThanSubject(string memory subject, string memory needle) public pure {
        vm.assume(bytes(needle).length > bytes(subject).length);
        assertFalse(StringUtils.startsWith(subject, needle), "oversized needle was recognized as prefix");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_startsWith_differential(string memory subject, string memory needle) public pure {
        assertEq(
            StringUtils.startsWith(subject, needle),
            referenceStartsWith(subject, needle),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceStartsWith(string memory subject, string memory needle) internal pure returns (bool) {
        bytes memory subjectBytes = bytes(subject);
        bytes memory needleBytes = bytes(needle);

        if (needleBytes.length > subjectBytes.length) return false;

        for (uint256 i = 0; i < needleBytes.length; ++i) {
            if (subjectBytes[i] != needleBytes[i]) return false;
        }
        return true;
    }
}
