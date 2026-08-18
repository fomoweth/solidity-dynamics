// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsEndsWithTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_endsWith_basic() public pure {
        assertTrue(BytesUtils.endsWith("hello world", "world"));
        assertFalse(BytesUtils.endsWith("hello world", "hello"));
        assertFalse(BytesUtils.endsWith("hello world", "worlD"));
    }

    function test_endsWith_exactMatch() public pure {
        assertTrue(BytesUtils.endsWith("abc", "abc"));
    }

    function test_endsWith_singleChar() public pure {
        assertTrue(BytesUtils.endsWith("abc", "c"));
        assertFalse(BytesUtils.endsWith("abc", "b"));
    }

    function test_endsWith_emptySubjectAndNeedle() public pure {
        assertTrue(BytesUtils.endsWith("", ""));
    }

    function test_endsWith_emptySubject() public pure {
        assertFalse(BytesUtils.endsWith("", "a"));
    }

    function test_endsWith_emptyNeedle() public pure {
        assertTrue(BytesUtils.endsWith("abc", ""));
    }

    function test_endsWith_needleLongerThanSubject() public pure {
        assertFalse(BytesUtils.endsWith("ab", "abc"));
        assertFalse(BytesUtils.endsWith("bc", "abc"));
    }

    function test_endsWith_longNeedle() public pure {
        bytes memory needle = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertTrue(BytesUtils.endsWith(bytes.concat("head", needle), needle));
        assertTrue(BytesUtils.endsWith(needle, needle));
        assertFalse(BytesUtils.endsWith(bytes.concat(needle, "tail"), needle));
        // 33 bytes: cannot fit in the 32-byte subject.
        assertFalse(BytesUtils.endsWith(needle, bytes.concat(needle, "X")));
    }

    function test_endsWith_arbitraryBytes() public pure {
        bytes memory subject = allBytes();
        assertTrue(BytesUtils.endsWith(subject, subject));
        assertTrue(BytesUtils.endsWith(subject, abi.encodePacked(uint8(0xff))));

        for (uint256 i = 0; i < 255; ++i) {
            assertFalse(BytesUtils.endsWith(subject, abi.encodePacked(uint8(i))));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_endsWith_emptyNeedle(bytes memory subject) public pure {
        assertTrue(BytesUtils.endsWith(subject, ""), "empty needle was not recognized as suffix");
    }

    function test_fuzz_endsWith_reflexive(bytes memory subject) public pure {
        assertTrue(BytesUtils.endsWith(subject, subject), "subject was not recognized as its own suffix");
    }

    function test_fuzz_endsWith_sliceIsSuffix(bytes memory subject, uint256 offset) public pure {
        bytes memory suffix = BytesUtils.slice(subject, bound(offset, 0, bytes(subject).length));
        assertTrue(BytesUtils.endsWith(subject, suffix), "sliced suffix was not recognized");
    }

    function test_fuzz_endsWith_concat(bytes memory prefix, bytes memory suffix) public pure {
        bytes memory subject = bytes.concat(prefix, suffix);
        assertTrue(BytesUtils.endsWith(subject, suffix), "concatenation does not end with suffix");
    }

    function test_fuzz_endsWith_impliesTrailingSlice(bytes memory subject, bytes memory needle) public pure {
        if (BytesUtils.endsWith(subject, needle)) {
            uint256 offset = bytes(subject).length - bytes(needle).length;
            bytes memory suffix = BytesUtils.slice(subject, offset);
            assertEq(suffix, needle, "recognized suffix does not match trailing bytes");

            uint256 index = BytesUtils.lastIndexOf(subject, needle);
            assertEq(index, offset, "recognized suffix was not found at trailing offset");
        }
    }

    function test_fuzz_endsWith_needleLongerThanSubject(bytes memory subject, bytes memory needle) public pure {
        vm.assume(bytes(needle).length > bytes(subject).length);
        assertFalse(BytesUtils.endsWith(subject, needle), "oversized needle was recognized as suffix");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_endsWith_differential(bytes memory subject, bytes memory needle) public pure {
        assertEq(
            BytesUtils.endsWith(subject, needle),
            referenceEndsWith(subject, needle),
            "result differs from reference implementation"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceEndsWith(bytes memory subject, bytes memory needle) internal pure returns (bool) {
        if (needle.length > subject.length) return false;

        uint256 offset = subject.length - needle.length;
        for (uint256 i = 0; i < needle.length; ++i) {
            if (subject[offset + i] != needle[i]) return false;
        }
        return true;
    }
}
