// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsRepeatTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_repeat_basic() public pure {
        assertEq(StringUtils.repeat("abc", 3), "abcabcabc");
        assertEq(StringUtils.repeat("abc", 2), "abcabc");
        assertEq(StringUtils.repeat("abc", 1), "abc");
        assertEq(StringUtils.repeat("abc", 0), "");
    }

    function test_repeat_emptySubject() public pure {
        assertEq(StringUtils.repeat("", 100), "");
        assertEq(StringUtils.repeat("", 10), "");
        assertEq(StringUtils.repeat("", 1), "");
        assertEq(StringUtils.repeat("", 0), "");
    }

    function test_repeat_singleChar() public pure {
        assertEq(StringUtils.repeat("a", 5), "aaaaa");
    }

    function test_repeat_powerOfTwo_doublingPath() public pure {
        assertEq(StringUtils.repeat("ab", 2), "abab");
        assertEq(StringUtils.repeat("ab", 4), "abababab");
        assertEq(StringUtils.repeat("ab", 8), "abababababababab");
    }

    function test_repeat_nonPowerOfTwo_remainder() public pure {
        // count=5: doubling covers 4, remainder=1
        assertEq(StringUtils.repeat("ab", 5), "ababababab");
        // count=6: doubling covers 4, remainder=2
        assertEq(StringUtils.repeat("ab", 6), "abababababab");
        // count=7: doubling covers 4, remainder=3
        assertEq(StringUtils.repeat("ab", 7), "ababababababab");
    }

    function test_repeat_outputLength() public pure {
        string memory result = StringUtils.repeat("abc", 7);
        assertEq(bytes(result).length, 21);
    }

    function test_repeat_longerThanWord() public pure {
        string memory subject = "0123456789abcdef0123456789abcdef"; // 32 bytes
        string memory result = StringUtils.repeat(subject, 3);
        assertEq(result, string.concat(subject, subject, subject));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_repeat_countZeroAlwaysEmpty(string memory subject) public pure {
        assertEq(StringUtils.repeat(subject, 0), "", "zero repetitions produced non-empty result");
    }

    function test_fuzz_repeat_countOneIdentity(string memory subject) public pure {
        assertEq(StringUtils.repeat(subject, 1), subject, "single repetition changed subject");
    }

    function test_fuzz_repeat_outputLengthIsProductCount(string memory subject, uint8 n) public pure {
        uint256 count = bound(n, 0, 32);
        uint256 expectedLength = bytes(subject).length * count;
        string memory result = StringUtils.repeat(subject, count);
        assertEq(bytes(result).length, expectedLength, "output length does not equal subject length times count");
    }

    function test_fuzz_repeat_contentConsistency(string memory subject, uint8 n) public pure {
        uint256 count = bound(n, 1, 32);
        bytes memory buffer = bytes(subject);
        bytes memory result = bytes(StringUtils.repeat(subject, count));

        for (uint256 i = 0; i < count; ++i) {
            for (uint256 j = 0; j < buffer.length; ++j) {
                assertEq(result[i * buffer.length + j], buffer[j], "repeated content differs from subject");
            }
        }
    }

    function test_fuzz_repeat_affixes(string memory subject, uint8 n) public pure {
        uint256 count = bound(n, 1, 32);
        string memory result = StringUtils.repeat(subject, count);

        assertTrue(StringUtils.startsWith(result, subject), "repeated result does not start with subject");
        assertTrue(StringUtils.endsWith(result, subject), "repeated result does not end with subject");
    }

    function test_fuzz_repeat_isAdditive(string memory subject, uint256 m, uint256 n) public pure {
        string memory prefix = StringUtils.repeat(subject, m = bound(m, 0, 32));
        string memory suffix = StringUtils.repeat(subject, n = bound(n, 0, 32));
        string memory expected = string.concat(prefix, suffix);
        string memory result = StringUtils.repeat(subject, m + n);

        assertEq(result, expected, "repetition is not additive");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_repeat_differential(string memory subject, uint8 n) public pure {
        uint256 count = bound(n, 0, 32);
        string memory expected = referenceRepeat(subject, count);
        string memory result = StringUtils.repeat(subject, count);
        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceRepeat(string memory subject, uint256 count) internal pure returns (string memory result) {
        for (uint256 i = 0; i < count; ++i) {
            result = string.concat(result, subject);
        }
    }
}
