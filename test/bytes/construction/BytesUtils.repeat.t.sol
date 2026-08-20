// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsRepeatTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_repeat_basic() public pure {
        assertEq(BytesUtils.repeat("abc", 3), "abcabcabc");
        assertEq(BytesUtils.repeat("abc", 2), "abcabc");
        assertEq(BytesUtils.repeat("abc", 1), "abc");
        assertEq(BytesUtils.repeat("abc", 0), "");
    }

    function test_repeat_emptySubject() public pure {
        assertEq(BytesUtils.repeat("", 100), "");
        assertEq(BytesUtils.repeat("", 10), "");
        assertEq(BytesUtils.repeat("", 1), "");
        assertEq(BytesUtils.repeat("", 0), "");
    }

    function test_repeat_singleChar() public pure {
        assertEq(BytesUtils.repeat("a", 5), "aaaaa");
    }

    function test_repeat_powerOfTwo_doublingPath() public pure {
        assertEq(BytesUtils.repeat("ab", 2), "abab");
        assertEq(BytesUtils.repeat("ab", 4), "abababab");
        assertEq(BytesUtils.repeat("ab", 8), "abababababababab");
    }

    function test_repeat_nonPowerOfTwo_remainder() public pure {
        // count=5: doubling covers 4, remainder=1
        assertEq(BytesUtils.repeat("ab", 5), "ababababab");
        // count=6: doubling covers 4, remainder=2
        assertEq(BytesUtils.repeat("ab", 6), "abababababab");
        // count=7: doubling covers 4, remainder=3
        assertEq(BytesUtils.repeat("ab", 7), "ababababababab");
    }

    function test_repeat_outputLength() public pure {
        assertEq(BytesUtils.repeat("abc", 7).length, 21);
    }

    function test_repeat_longerThanWord() public pure {
        bytes memory subject = "0123456789abcdef0123456789abcdef"; // 32 bytes
        assertEq(BytesUtils.repeat(subject, 3), bytes.concat(subject, subject, subject));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_repeat_countZeroAlwaysEmpty(bytes memory subject) public pure {
        assertEq(BytesUtils.repeat(subject, 0), "", "zero repetitions produced non-empty result");
    }

    function test_fuzz_repeat_countOneIdentity(bytes memory subject) public pure {
        assertEq(BytesUtils.repeat(subject, 1), subject, "single repetition changed subject");
    }

    function test_fuzz_repeat_outputLengthIsProductCount(bytes memory subject, uint8 n) public pure {
        uint256 count = bound(n, 0, 32);
        uint256 expectedLength = bytes(subject).length * count;
        bytes memory result = BytesUtils.repeat(subject, count);
        assertEq(result.length, expectedLength, "output length does not equal subject length times count");
    }

    function test_fuzz_repeat_contentConsistency(bytes memory subject, uint8 n) public pure {
        uint256 count = bound(n, 1, 32);
        bytes memory result = BytesUtils.repeat(subject, count);

        for (uint256 i = 0; i < count; ++i) {
            for (uint256 j = 0; j < subject.length; ++j) {
                assertEq(result[i * subject.length + j], subject[j], "repeated content differs from subject");
            }
        }
    }

    function test_fuzz_repeat_affixes(bytes memory subject, uint8 n) public pure {
        uint256 count = bound(n, 1, 32);
        bytes memory result = BytesUtils.repeat(subject, count);

        assertTrue(BytesUtils.startsWith(result, subject), "repeated result does not start with subject");
        assertTrue(BytesUtils.endsWith(result, subject), "repeated result does not end with subject");
    }

    function test_fuzz_repeat_isAdditive(bytes memory subject, uint256 m, uint256 n) public pure {
        bytes memory prefix = BytesUtils.repeat(subject, m = bound(m, 0, 32));
        bytes memory suffix = BytesUtils.repeat(subject, n = bound(n, 0, 32));
        bytes memory expected = bytes.concat(prefix, suffix);
        bytes memory result = BytesUtils.repeat(subject, m + n);

        assertEq(result, expected, "repetition is not additive");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_repeat_differential(bytes memory subject, uint256 n) public pure {
        uint256 count = bound(n, 0, 32);
        bytes memory expected = referenceRepeat(subject, count);
        bytes memory result = BytesUtils.repeat(subject, count);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceRepeat(bytes memory subject, uint256 count) internal pure returns (bytes memory result) {
        for (uint256 i = 0; i < count; ++i) {
            result = bytes.concat(result, subject);
        }
    }
}
