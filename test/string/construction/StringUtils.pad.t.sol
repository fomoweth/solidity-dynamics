// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsPadTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit: padStart
    // ─────────────────────────────────────────────────────────────────────────────

    function test_padStart_basic() public pure {
        assertEq(StringUtils.padStart("5", "0", 3), "005");
        assertEq(StringUtils.padStart("abc", ".", 6), "...abc");
    }

    function test_padStart_multiCharFill_cyclicTruncated() public pure {
        // JS semantics: fill repeats from its start and is truncated.
        assertEq(StringUtils.padStart("abc", "xy", 8), "xyxyxabc");
        assertEq(StringUtils.padStart("a", "123", 6), "12312a");
    }

    function test_padStart_lengthAtOrBelowSubject() public pure {
        assertEq(StringUtils.padStart("abc", "0", 3), "abc");
        assertEq(StringUtils.padStart("abc", "0", 2), "abc");
        assertEq(StringUtils.padStart("abc", "0", 0), "abc");
    }

    function test_padStart_emptySubject() public pure {
        assertEq(StringUtils.padStart("", "ab", 3), "aba");
        assertEq(StringUtils.padStart("", "ab", 0), "");
    }

    function test_padStart_emptyFill() public pure {
        assertEq(StringUtils.padStart("abc", "", 10), "abc");
        assertEq(StringUtils.padStart("abc", "", 0), "abc");
    }

    function test_padStart_emptySubjectAndFill() public pure {
        assertEq(StringUtils.padStart("", "", 10), "");
        assertEq(StringUtils.padStart("", "", 0), "");
    }

    function test_padStart_singleCharSubject() public pure {
        assertEq(StringUtils.padStart("i", "--", 3), "--i");
    }

    function test_padStart_lengthExceedsByOne() public pure {
        assertEq(StringUtils.padStart("abc", "0", 4), "0abc");
    }

    function test_padStart_fillLongerThanGap() public pure {
        assertEq(StringUtils.padStart("abc", "xyz", 4), "xabc");
        assertEq(StringUtils.padStart("abc", "xyz", 5), "xyabc");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit: padEnd
    // ─────────────────────────────────────────────────────────────────────────────

    function test_padEnd_basic() public pure {
        assertEq(StringUtils.padEnd("5", "0", 3), "500");
        assertEq(StringUtils.padEnd("abc", ".", 6), "abc...");
    }

    function test_padEnd_multiCharFill_cyclicTruncated() public pure {
        assertEq(StringUtils.padEnd("abc", "xy", 8), "abcxyxyx");
        assertEq(StringUtils.padEnd("a", "123", 6), "a12312");
    }

    function test_padEnd_lengthAtOrBelowSubject() public pure {
        assertEq(StringUtils.padEnd("abc", "0", 3), "abc");
        assertEq(StringUtils.padEnd("abc", "0", 1), "abc");
    }

    function test_padEnd_emptySubject() public pure {
        assertEq(StringUtils.padEnd("", "ab", 3), "aba");
        assertEq(StringUtils.padEnd("", "ab", 0), "");
    }

    function test_padEnd_emptyFill() public pure {
        assertEq(StringUtils.padEnd("abc", "", 10), "abc");
        assertEq(StringUtils.padEnd("abc", "", 0), "abc");
    }

    function test_padEnd_emptySubjectAndFill() public pure {
        assertEq(StringUtils.padEnd("", "", 10), "");
        assertEq(StringUtils.padEnd("", "", 0), "");
    }

    function test_padEnd_singleCharSubject() public pure {
        assertEq(StringUtils.padEnd("i", "-", 3), "i--");
    }

    function test_padEnd_lengthExceedsByOne() public pure {
        assertEq(StringUtils.padEnd("abc", "0", 4), "abc0");
    }

    function test_padEnd_fillLongerThanGap() public pure {
        assertEq(StringUtils.padEnd("abc", "xyz", 4), "abcx");
        assertEq(StringUtils.padEnd("abc", "xyz", 5), "abcxy");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_padStart_emptyFillIsIdentity(string memory subject, uint16 length) public pure {
        assertEq(StringUtils.padStart(subject, "", length), subject, "empty fill changed subject");
    }

    function test_fuzz_padEnd_emptyFillIsIdentity(string memory subject, uint16 length) public pure {
        assertEq(StringUtils.padEnd(subject, "", length), subject, "empty fill changed subject");
    }

    function test_fuzz_padStart_neverShrinks(string memory subject, string memory fill, uint16 length) public pure {
        string memory result = StringUtils.padStart(subject, fill, length);
        assertGe(bytes(result).length, bytes(subject).length, "padStart shortened subject");
    }

    function test_fuzz_padEnd_neverShrinks(string memory subject, string memory fill, uint16 length) public pure {
        string memory result = StringUtils.padEnd(subject, fill, length);
        assertGe(bytes(result).length, bytes(subject).length, "padEnd shortened subject");
    }

    function test_fuzz_padEnd_paddingIsCyclic(string memory subject, string memory fill, uint16 length) public pure {
        bytes memory subjectBytes = bytes(subject);
        bytes memory fillBytes = bytes(fill);
        vm.assume(fillBytes.length != 0);

        bytes memory result = bytes(StringUtils.padEnd(subject, fill, length));

        for (uint256 i = subjectBytes.length; i < result.length; ++i) {
            assertEq(
                result[i],
                fillBytes[(i - subjectBytes.length) % fillBytes.length],
                "padEnd padding does not follow fill cyclically"
            );
        }
    }

    function test_fuzz_pad_resultLengthAndAffixes(string memory subject, string memory fill, uint16 length)
        public
        pure
    {
        vm.assume(bytes(fill).length != 0);

        uint256 expectedLength = max(length, bytes(subject).length);

        string memory result = StringUtils.padStart(subject, fill, length);
        assertEq(bytes(result).length, expectedLength, "padStart produced incorrect length");
        assertTrue(StringUtils.endsWith(result, subject), "padStart does not preserve subject as suffix");

        result = StringUtils.padEnd(subject, fill, length);
        assertEq(bytes(result).length, expectedLength, "padEnd produced incorrect length");
        assertTrue(StringUtils.startsWith(result, subject), "padEnd does not preserve subject as prefix");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_padStart_differential(string memory subject, string memory fill, uint16 length) public pure {
        string memory expected = referencePadString(subject, fill, length, true);
        string memory result = StringUtils.padStart(subject, fill, length);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_padEnd_differential(string memory subject, string memory fill, uint16 length) public pure {
        string memory expected = referencePadString(subject, fill, length, false);
        string memory result = StringUtils.padEnd(subject, fill, length);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referencePadString(string memory subject, string memory fill, uint256 length, bool isStart)
        internal
        pure
        returns (string memory result)
    {
        bytes memory subjectBytes = bytes(subject);
        bytes memory fillBytes = bytes(fill);
        if (length <= subjectBytes.length || fillBytes.length == 0) return subject;

        bytes memory buffer = new bytes(length - subjectBytes.length);
        for (uint256 i = 0; i < buffer.length; ++i) {
            buffer[i] = fillBytes[i % fillBytes.length];
        }
        return isStart ? string(bytes.concat(buffer, subjectBytes)) : string(bytes.concat(subjectBytes, buffer));
    }
}
