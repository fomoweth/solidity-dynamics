// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsJoinTest is StringUtilsTest {
    using StringUtils for string;

    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_join_basic() public pure {
        string[] memory segments = arrayify("a", "b", "c", "d");
        assertEq(StringUtils.join(segments, " "), "a b c d");
        assertEq(StringUtils.join(segments, "-"), "a-b-c-d");
        assertEq(StringUtils.join(segments, "_"), "a_b_c_d");
        assertEq(StringUtils.join(segments, ","), "a,b,c,d");
        assertEq(StringUtils.join(segments, ", "), "a, b, c, d");
    }

    function test_join_emptyArray() public pure {
        string[] memory segments = new string[](0);
        assertEq(StringUtils.join(segments, "-"), "");
    }

    function test_join_singleElement() public pure {
        string[] memory segments = arrayify("solo");
        assertEq(StringUtils.join(segments, "-"), segments[0]);
    }

    function test_join_emptyStrings() public pure {
        string[] memory segments = new string[](4);
        string memory delimiter = "-";

        string memory expected = StringUtils.repeat(delimiter, segments.length - 1);
        string memory result = StringUtils.join(segments, delimiter);

        assertGt(bytes(result).length, 0);
        assertEq(result, expected);
    }

    function test_join_longStrings() public pure {
        string[] memory segments = arrayify(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
        );
        string memory delimiter = "----------------------------------------------------------------";

        uint256 expectedLength = 64 * (segments.length * 2 - 1);
        string memory expected = referenceJoin(segments, delimiter);
        string memory result = StringUtils.join(segments, delimiter);

        assertEq(bytes(result).length, expectedLength);
        assertEq(result, expected);
        assertMemoryInvariants(result);
    }

    function test_join_emptyDelimiter() public pure {
        string[] memory segments = arrayify("a", "b", "c", "d");
        assertEq(StringUtils.join(segments, ""), "abcd");
    }

    function test_join_multiCharDelimiter() public pure {
        string[] memory segments = arrayify("left", "right");
        assertEq(StringUtils.join(segments, " <-> "), "left <-> right");
    }

    function test_join_outputLength() public pure {
        string[] memory segments = arrayify("a", "bb", "ccc", "dddd");
        string memory delimiter = "--";

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += bytes(segments[i]).length;
            if (i != 0) expectedLength += bytes(delimiter).length;
        }

        string memory result = StringUtils.join(segments, delimiter);
        assertEq(bytes(result).length, expectedLength);
    }

    function test_join_delimiterAppearsNMinusOneTimes() public pure {
        string[] memory segments = arrayify("a", "b", "c", "d");
        string memory delimiter = "-";

        string memory result = StringUtils.join(segments, delimiter);
        assertEq(result, "a-b-c-d");

        uint256[] memory indices = StringUtils.indicesOf(result, delimiter);
        assertEq(indices.length, segments.length - 1);
    }

    function test_join_parse_erc7579_accountId() public pure {
        string memory accountId = "fomoweth.vortex.0.0.1-alpha";
        string memory delimiter = ".";

        string[] memory segments = StringUtils.split(accountId, delimiter);
        assertGt(segments.length, 2);

        string memory vendor = segments[0];
        assertEq(vendor, "fomoweth");

        string memory name = segments[1];
        assertEq(name, "vortex");

        uint256 length = segments.length - 2;
        for (uint256 i = 0; i < length; ++i) {
            segments[i] = segments[i + 2];
        }

        assembly ("memory-safe") {
            mstore(segments, length)
        }

        string memory version = StringUtils.join(segments, delimiter);
        assertEq(version, "0.0.1-alpha");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_join_outputLength(string[] memory segments, string memory delimiter) public pure {
        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += bytes(segments[i]).length;
            if (i != 0) expectedLength += bytes(delimiter).length;
        }

        string memory result = StringUtils.join(segments, delimiter);
        assertEq(bytes(result).length, expectedLength, "output length does not account for segments and delimiters");
    }

    function test_fuzz_join_singleElementIsIdentity(string memory segment, string memory delimiter) public pure {
        assertEq(StringUtils.join(arrayify(segment), delimiter), segment, "single-element join changed segment");
    }

    function test_fuzz_join_preservesSegments(string[] memory segments, string memory delimiter) public pure {
        string memory result = StringUtils.join(segments, delimiter);
        uint256 offset = 0;

        for (uint256 i = 0; i < segments.length; ++i) {
            if (i != 0) {
                assertEq(
                    StringUtils.slice(result, offset, bytes(delimiter).length),
                    delimiter,
                    "delimiter is not preserved at expected offset"
                );
                offset += bytes(delimiter).length;
            }

            assertEq(
                StringUtils.slice(result, offset, bytes(segments[i]).length),
                segments[i],
                "segment is not preserved at expected offset"
            );
            offset += bytes(segments[i]).length;
        }

        assertEq(offset, bytes(result).length, "result contains bytes outside joined segments");
        assertMemoryInvariants(result);
    }

    function test_fuzz_join_splitRoundtrip(string memory subject, string memory delimiter) public pure {
        string[] memory segments = StringUtils.split(subject, delimiter);
        string memory result = StringUtils.join(segments, delimiter);

        assertEq(result, subject, "joining split segments did not reconstruct subject");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_join_differential(string[] memory segments, string memory delimiter) public pure {
        string memory expected = referenceJoin(segments, delimiter);
        string memory result = StringUtils.join(segments, delimiter);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceJoin(string[] memory segments, string memory delimiter)
        internal
        pure
        returns (string memory result)
    {
        for (uint256 i = 0; i < segments.length; ++i) {
            if (i != 0) result = string.concat(result, delimiter);
            result = string.concat(result, segments[i]);
        }
    }
}
