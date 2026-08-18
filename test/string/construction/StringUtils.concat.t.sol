// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsConcatTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_concat_basic() public pure {
        assertEq(StringUtils.concat(arrayify("a", "b", "c", "d")), "abcd");
        assertEq(StringUtils.concat(arrayify("a ", "b ", "c ", "d ")), "a b c d ");
        assertEq(StringUtils.concat(arrayify("a-", "b-", "c-", "d-")), "a-b-c-d-");
        assertEq(StringUtils.concat(arrayify("a_", "b_", "c_", "d_")), "a_b_c_d_");
    }

    function test_concat_emptyArray() public pure {
        string[] memory segments = new string[](0);
        assertEq(StringUtils.concat(segments), "");
    }

    function test_concat_singleElement() public pure {
        string[] memory segments = arrayify("solo");
        assertEq(StringUtils.concat(segments), segments[0]);
    }

    function test_concat_emptyStrings() public pure {
        string[] memory segments = new string[](4);
        assertEq(StringUtils.concat(segments), "");
    }

    function test_concat_longStrings() public pure {
        string[] memory segments = arrayify(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
        );

        uint256 expectedLength = 64 * segments.length;
        string memory expected = referenceConcat(segments);
        string memory result = StringUtils.concat(segments);

        assertEq(bytes(result).length, expectedLength);
        assertEq(result, expected);
        assertMemoryInvariants(result);
    }

    function test_concat_outputLength() public pure {
        string[] memory segments = arrayify("a", "bb", "ccc", "dddd");

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += bytes(segments[i]).length;
        }

        string memory result = StringUtils.concat(segments);
        assertEq(bytes(result).length, expectedLength);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_concat_outputLength(string[] memory segments) public pure {
        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += bytes(segments[i]).length;
        }

        string memory result = StringUtils.concat(segments);
        assertEq(bytes(result).length, expectedLength, "output length does not equal sum of segment lengths");
    }

    function test_fuzz_concat_singleElementIsIdentity(string memory segment) public pure {
        assertEq(StringUtils.concat(arrayify(segment)), segment, "single-element concatenation changed segment");
    }

    function test_fuzz_concat_preservesSegments(string[] memory segments) public pure {
        string memory result = StringUtils.concat(segments);
        uint256 offset = 0;

        for (uint256 i = 0; i < segments.length; ++i) {
            assertEq(
                StringUtils.slice(result, offset, bytes(segments[i]).length),
                segments[i],
                "segment is not preserved at expected offset"
            );
            offset += bytes(segments[i]).length;
        }

        assertEq(offset, bytes(result).length, "result contains bytes outside concatenated segments");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_concat_differential(string[] memory segments) public pure {
        string memory expected = referenceConcat(segments);
        string memory result = StringUtils.concat(segments);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceConcat(string[] memory segments) internal pure returns (string memory result) {
        for (uint256 i = 0; i < segments.length; ++i) {
            result = string.concat(result, segments[i]);
        }
    }
}
