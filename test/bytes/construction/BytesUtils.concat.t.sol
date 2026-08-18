// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsConcatTest is BytesUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_concat_basic() public pure {
        assertEq(BytesUtils.concat(arrayify("a", "b", "c", "d")), "abcd");
        assertEq(BytesUtils.concat(arrayify("a ", "b ", "c ", "d ")), "a b c d ");
        assertEq(BytesUtils.concat(arrayify("a-", "b-", "c-", "d-")), "a-b-c-d-");
        assertEq(BytesUtils.concat(arrayify("a_", "b_", "c_", "d_")), "a_b_c_d_");
    }

    function test_concat_emptyArray() public pure {
        bytes[] memory segments = new bytes[](0);
        assertEq(BytesUtils.concat(segments), "");
    }

    function test_concat_singleElement() public pure {
        bytes[] memory segments = arrayify("solo");
        assertEq(BytesUtils.concat(segments), segments[0]);
    }

    function test_concat_emptyStrings() public pure {
        bytes[] memory segments = new bytes[](4);
        assertEq(BytesUtils.concat(segments), "");
    }

    function test_concat_longStrings() public pure {
        bytes[] memory segments = arrayify(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", // 64 chars
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", // 64 chars
            "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc", // 64 chars
            "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" // 64 chars
        );

        uint256 expectedLength = 64 * segments.length;
        bytes memory expected = referenceConcat(segments);
        bytes memory result = BytesUtils.concat(segments);

        assertEq(result.length, expectedLength);
        assertEq(result, expected);
        assertMemoryInvariants(result);
    }

    function test_concat_outputLength() public pure {
        bytes[] memory segments = arrayify("a", "bb", "ccc", "dddd");

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += segments[i].length;
        }

        bytes memory result = BytesUtils.concat(segments);
        assertEq(result.length, expectedLength);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_concat_outputLength(bytes[] memory segments) public pure {
        uint256 expectedLength = 0;
        for (uint256 i = 0; i < segments.length; ++i) {
            expectedLength += segments[i].length;
        }

        bytes memory result = BytesUtils.concat(segments);
        assertEq(result.length, expectedLength, "output length does not equal sum of segment lengths");
    }

    function test_fuzz_concat_singleElementIsIdentity(bytes memory segment) public pure {
        assertEq(BytesUtils.concat(arrayify(segment)), segment, "single-element concatenation changed segment");
    }

    function test_fuzz_concat_preservesSegments(bytes[] memory segments) public pure {
        bytes memory result = BytesUtils.concat(segments);
        uint256 offset = 0;

        for (uint256 i = 0; i < segments.length; ++i) {
            assertEq(
                BytesUtils.slice(result, offset, segments[i].length),
                segments[i],
                "segment is not preserved at expected offset"
            );
            offset += segments[i].length;
        }

        assertEq(offset, result.length, "result contains bytes outside concatenated segments");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_concat_differential(bytes[] memory segments) public pure {
        bytes memory expected = referenceConcat(segments);
        bytes memory result = BytesUtils.concat(segments);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceConcat(bytes[] memory segments) internal pure returns (bytes memory result) {
        for (uint256 i = 0; i < segments.length; ++i) {
            result = bytes.concat(result, segments[i]);
        }
    }
}
