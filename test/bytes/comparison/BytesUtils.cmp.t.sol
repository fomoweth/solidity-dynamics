// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract BytesUtilsCmpTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_cmp_equal() public pure {
        assertEq(BytesUtils.cmp("", ""), int256(0));
        assertEq(BytesUtils.cmp("hello", "hello"), int256(0));
        assertEq(BytesUtils.cmp("hello world", "hello world"), int256(0));
    }

    function test_cmp_longer() public pure {
        assertEq(BytesUtils.cmp("hello", ""), int256(1));
        assertEq(BytesUtils.cmp("world", "hello"), int256(1));
        assertEq(BytesUtils.cmp("hello", "Hello"), int256(1));
        assertEq(BytesUtils.cmp("hello", "HELLO"), int256(1));
        assertEq(BytesUtils.cmp("hello world", "hello"), int256(1));
    }

    function test_cmp_shorter() public pure {
        assertEq(BytesUtils.cmp("", "hello"), int256(-1));
        assertEq(BytesUtils.cmp("hello", "world"), int256(-1));
        assertEq(BytesUtils.cmp("Hello", "hello"), int256(-1));
        assertEq(BytesUtils.cmp("HELLO", "hello"), int256(-1));
        assertEq(BytesUtils.cmp("hello", "hello world"), int256(-1));
    }

    function test_cmp_char_equal() public pure {
        assertEq(BytesUtils.cmp("A", "A"), int256(0));
        assertEq(BytesUtils.cmp("a", "a"), int256(0));
        assertEq(BytesUtils.cmp("B", "B"), int256(0));
        assertEq(BytesUtils.cmp("b", "b"), int256(0));
    }

    function test_cmp_char_longer() public pure {
        assertEq(BytesUtils.cmp("B", "A"), int256(1));
        assertEq(BytesUtils.cmp("b", "a"), int256(1));
        assertEq(BytesUtils.cmp("a", "A"), int256(1));
        assertEq(BytesUtils.cmp("b", "B"), int256(1));
    }

    function test_cmp_char_shorter() public pure {
        assertEq(BytesUtils.cmp("A", "B"), int256(-1));
        assertEq(BytesUtils.cmp("a", "b"), int256(-1));
        assertEq(BytesUtils.cmp("A", "a"), int256(-1));
        assertEq(BytesUtils.cmp("B", "b"), int256(-1));
    }

    function test_cmp_differsByFirstByte() public pure {
        assertEq(BytesUtils.cmp("azzzz", "baaaa"), int256(-1));
        assertEq(BytesUtils.cmp("baaaa", "azzzz"), int256(1));
    }

    function test_cmp_differsInMiddle() public pure {
        assertEq(BytesUtils.cmp("abcde", "abXde"), int256(1)); // 'c' (0x63) > 'X' (0x58)
        assertEq(BytesUtils.cmp("abXde", "abcde"), int256(-1));
    }

    function test_cmp_differsByLastByte() public pure {
        assertEq(BytesUtils.cmp("abcda", "abcdb"), int256(-1));
        assertEq(BytesUtils.cmp("abcdb", "abcda"), int256(1));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_cmp_hasExactDomain(bytes memory x, bytes memory y) public pure {
        int256 z = BytesUtils.cmp(x, y);
        assertTrue(z == int256(-1) || z == int256(0) || z == int256(1));
        assertEq(z == int256(0), keccak256(x) == keccak256(y));
    }

    function test_fuzz_cmp_reflexive(bytes memory x) public pure {
        assertEq(BytesUtils.cmp(x, x), int256(0));
    }

    function test_fuzz_cmp_asymmetric(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.cmp(x, y), -BytesUtils.cmp(y, x));
    }

    function test_fuzz_cmp_transitive(bytes memory x, bytes memory y, bytes memory z) public pure {
        int256 xy = BytesUtils.cmp(x, y);
        int256 yz = BytesUtils.cmp(y, z);
        if (xy == yz && xy != int256(0)) assertEq(BytesUtils.cmp(x, z), xy);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_diff_cmp(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.cmp(x, y), referenceCmp(x, y));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceCmp(bytes memory x, bytes memory y) internal pure returns (int256) {
        uint256 length = min(x.length, y.length);
        for (uint256 i = 0; i < length; ++i) {
            if (x[i] < y[i]) return -1;
            if (x[i] > y[i]) return 1;
        }

        if (x.length < y.length) return -1;
        if (x.length > y.length) return 1;
        return 0;
    }
}
