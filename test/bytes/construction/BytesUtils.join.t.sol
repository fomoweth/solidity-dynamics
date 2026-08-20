// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsJoinTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_join_basic() public pure {
        bytes[] memory segments = arrayify("a", "b", "c", "d");
        assertEq(BytesUtils.join(segments, " "), "a b c d");
        assertEq(BytesUtils.join(segments, "-"), "a-b-c-d");
        assertEq(BytesUtils.join(segments, "_"), "a_b_c_d");
        assertEq(BytesUtils.join(segments, ","), "a,b,c,d");
        assertEq(BytesUtils.join(segments, ", "), "a, b, c, d");
    }

    function test_join_emptyArray() public pure {
        bytes[] memory segments = new bytes[](0);
        assertEq(BytesUtils.join(segments, "-"), "");
    }

    function test_join_singleElement() public pure {
        bytes[] memory segments = arrayify("solo");
        assertEq(BytesUtils.join(segments, "-"), segments[0]);
    }

    function test_join_emptyStrings() public pure {
        bytes[] memory segments = new bytes[](4);
        bytes memory delimiter = "-";

        bytes memory expected = BytesUtils.repeat(delimiter, segments.length - 1);
        bytes memory result = BytesUtils.join(segments, delimiter);

        assertGt(result.length, 0);
        assertEq(result, expected);
    }

    function test_join_longStrings() public pure {
        bytes[] memory segments = arrayify(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
        );
        bytes memory delimiter = "----------------------------------------------------------------";

        uint256 expectedLength = 64 * (segments.length * 2 - 1);
        bytes memory expected = referenceJoin(segments, delimiter);
        bytes memory result = BytesUtils.join(segments, delimiter);

        assertEq(result.length, expectedLength);
        assertEq(result, expected);
        assertMemoryInvariants(result);
    }

    function test_join_emptyDelimiter() public pure {
        bytes[] memory segments = arrayify("a", "b", "c", "d");
        assertEq(BytesUtils.join(segments, ""), "abcd");
    }

    function test_join_multiCharDelimiter() public pure {
        bytes[] memory segments = arrayify("left", "right");
        assertEq(BytesUtils.join(segments, " <-> "), "left <-> right");
    }

    function test_join_outputLength() public pure {
        bytes[] memory segments = arrayify("a", "bb", "ccc", "dddd");
        bytes memory delimiter = "--";

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += segments[i].length;
            if (i != 0) expectedLength += delimiter.length;
        }

        bytes memory result = BytesUtils.join(segments, delimiter);
        assertEq(result.length, expectedLength);
    }

    function test_join_delimiterAppearsNMinusOneTimes() public pure {
        bytes[] memory segments = arrayify("a", "b", "c", "d");
        bytes memory delimiter = "-";

        bytes memory result = BytesUtils.join(segments, delimiter);
        assertEq(result, "a-b-c-d");

        uint256[] memory indices = BytesUtils.indicesOf(result, delimiter);
        assertEq(indices.length, segments.length - 1);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_join_outputLength(bytes[] memory segments, bytes memory delimiter) public pure {
        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += segments[i].length;
            if (i != 0) expectedLength += delimiter.length;
        }

        bytes memory result = BytesUtils.join(segments, delimiter);
        assertEq(result.length, expectedLength, "output length does not account for segments and delimiters");
    }

    function test_fuzz_join_singleElementIsIdentity(bytes memory segment, bytes memory delimiter) public pure {
        assertEq(BytesUtils.join(arrayify(segment), delimiter), segment, "single-element join changed segment");
    }

    function test_fuzz_join_preservesSegments(bytes[] memory segments, bytes memory delimiter) public pure {
        bytes memory result = BytesUtils.join(segments, delimiter);
        uint256 offset = 0;

        for (uint256 i = 0; i < segments.length; ++i) {
            if (i != 0) {
                assertEq(
                    BytesUtils.slice(result, offset, delimiter.length),
                    delimiter,
                    "delimiter is not preserved at expected offset"
                );
                offset += delimiter.length;
            }

            assertEq(
                BytesUtils.slice(result, offset, segments[i].length),
                segments[i],
                "segment is not preserved at expected offset"
            );
            offset += segments[i].length;
        }

        assertEq(offset, result.length, "result contains bytes outside joined segments");
        assertMemoryInvariants(result);
    }

    function test_fuzz_join_splitRoundtrip(bytes memory subject, bytes memory delimiter) public pure {
        bytes[] memory segments = BytesUtils.split(subject, delimiter);
        bytes memory result = BytesUtils.join(segments, delimiter);

        assertEq(result, subject, "joining split segments did not reconstruct subject");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_join_differential(bytes[] memory segments, bytes memory delimiter) public pure {
        bytes memory expected = referenceJoin(segments, delimiter);
        bytes memory result = BytesUtils.join(segments, delimiter);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceJoin(bytes[] memory segments, bytes memory delimiter)
        internal
        pure
        returns (bytes memory result)
    {
        for (uint256 i = 0; i < segments.length; ++i) {
            if (i != 0) result = bytes.concat(result, delimiter);
            result = bytes.concat(result, segments[i]);
        }
    }
}
