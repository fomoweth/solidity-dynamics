// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract BytesUtilsStartsWithTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_startsWith_emptySubject() public pure {
        assertFalse(BytesUtils.startsWith("", "a"));
    }

    function test_startsWith_emptyNeedle() public pure {
        assertTrue(BytesUtils.startsWith("abc", ""));
        assertTrue(BytesUtils.startsWith("", ""));
    }

    function test_startsWith_needleLongerThanSubject() public pure {
        assertFalse(BytesUtils.startsWith("ab", "abc"));
    }

    function test_startsWith_needleEqualsSubject() public pure {
        assertTrue(BytesUtils.startsWith("abc", "abc"));
    }

    function test_startsWith_properPrefix() public pure {
        assertTrue(BytesUtils.startsWith("hello world", "hello"));
        assertFalse(BytesUtils.startsWith("hello world", "world"));
        assertFalse(BytesUtils.startsWith("hello world", "hellO"));
    }

    function test_startsWith_singleChar() public pure {
        assertTrue(BytesUtils.startsWith("abc", "a"));
        assertFalse(BytesUtils.startsWith("abc", "b"));
    }

    function test_startsWith_bothEmpty() public pure {
        assertTrue(BytesUtils.startsWith("", ""));
    }

    function test_startsWith_longNeedle() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertTrue(BytesUtils.startsWith(bytes.concat(needle, "tail"), needle));
        assertTrue(BytesUtils.startsWith(needle, needle));
        assertFalse(BytesUtils.startsWith(bytes.concat("head", needle), needle));
        // 33 bytes: differs from the 32-byte needle only past the first word.
        assertFalse(BytesUtils.startsWith(needle, bytes.concat(needle, "X")));
    }

    function test_startsWith_arbitraryBytes() public pure {
        bytes memory subject = bytes(allBytes());
        assertTrue(BytesUtils.startsWith(subject, subject));
        assertTrue(BytesUtils.startsWith(subject, abi.encodePacked(uint8(0x00))));

        for (uint256 i = 1; i < 256; ++i) {
            assertFalse(BytesUtils.startsWith(subject, abi.encodePacked(uint8(i))));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_startsWith_emptyNeedle(bytes memory subject) public pure {
        assertTrue(BytesUtils.startsWith(subject, ""));
    }

    function test_fuzz_startsWith_reflexive(bytes memory subject) public pure {
        assertTrue(BytesUtils.startsWith(subject, subject));
    }

    function test_fuzz_startsWith_sliceIsPrefix(bytes memory subject, uint256 length) public pure {
        bytes memory prefix = BytesUtils.slice(subject, 0, bound(length, 0, bytes(subject).length));
        assertTrue(BytesUtils.startsWith(subject, prefix), "sliced prefix was not recognized");
    }

    function test_fuzz_startsWith_concat(bytes memory prefix, bytes memory suffix) public pure {
        bytes memory subject = bytes.concat(prefix, suffix);
        assertTrue(BytesUtils.startsWith(subject, prefix), "concatenation does not start with prefix");
    }

    function test_fuzz_startsWith_impliesIndexOfZero(bytes memory subject, bytes memory needle) public pure {
        if (BytesUtils.startsWith(subject, needle)) {
            bytes memory prefix = BytesUtils.slice(subject, 0, bytes(needle).length);
            assertEq(prefix, needle, "recognized prefix does not match leading bytes");
            assertEq(BytesUtils.indexOf(subject, needle), 0, "recognized prefix was not found at index zero");
        }
    }

    function test_fuzz_startsWith_needleLongerThanSubject(bytes memory subject, bytes memory needle) public pure {
        vm.assume(bytes(needle).length > bytes(subject).length);
        assertFalse(BytesUtils.startsWith(subject, needle), "oversized needle was recognized as prefix");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_startsWith_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(BytesUtils.startsWith(subject, needle), referenceStartsWith(subject, needle));
    }

    function test_fuzz_startsWith_differential_constructed(bytes memory prefix, bytes memory needle) public pure {
        bytes memory subject = bytes.concat(prefix, needle);
        assertEq(BytesUtils.startsWith(subject, needle), referenceStartsWith(subject, needle));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceStartsWith(bytes memory subject, bytes memory needle) internal pure returns (bool) {
        if (needle.length > subject.length) return false;

        for (uint256 i = 0; i < needle.length; ++i) {
            if (subject[i] != needle[i]) return false;
        }
        return true;
    }
}
