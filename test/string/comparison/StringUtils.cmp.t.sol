// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract StringUtilsCmpTest is BaseTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_cmp_equal() public pure {
        assertEq(StringUtils.cmp("", ""), int256(0));
        assertEq(StringUtils.cmp("hello", "hello"), int256(0));
        assertEq(StringUtils.cmp("hello world", "hello world"), int256(0));
    }

    function test_cmp_longer() public pure {
        assertEq(StringUtils.cmp("hello", ""), int256(1));
        assertEq(StringUtils.cmp("world", "hello"), int256(1));
        assertEq(StringUtils.cmp("hello", "Hello"), int256(1));
        assertEq(StringUtils.cmp("hello", "HELLO"), int256(1));
        assertEq(StringUtils.cmp("hello world", "hello"), int256(1));
    }

    function test_cmp_shorter() public pure {
        assertEq(StringUtils.cmp("", "hello"), int256(-1));
        assertEq(StringUtils.cmp("hello", "world"), int256(-1));
        assertEq(StringUtils.cmp("Hello", "hello"), int256(-1));
        assertEq(StringUtils.cmp("HELLO", "hello"), int256(-1));
        assertEq(StringUtils.cmp("hello", "hello world"), int256(-1));
    }

    function test_cmp_char_equal() public pure {
        assertEq(StringUtils.cmp("A", "A"), int256(0));
        assertEq(StringUtils.cmp("a", "a"), int256(0));
        assertEq(StringUtils.cmp("B", "B"), int256(0));
        assertEq(StringUtils.cmp("b", "b"), int256(0));
    }

    function test_cmp_char_longer() public pure {
        assertEq(StringUtils.cmp("B", "A"), int256(1));
        assertEq(StringUtils.cmp("b", "a"), int256(1));
        assertEq(StringUtils.cmp("a", "A"), int256(1));
        assertEq(StringUtils.cmp("b", "B"), int256(1));
    }

    function test_cmp_char_shorter() public pure {
        assertEq(StringUtils.cmp("A", "B"), int256(-1));
        assertEq(StringUtils.cmp("a", "b"), int256(-1));
        assertEq(StringUtils.cmp("A", "a"), int256(-1));
        assertEq(StringUtils.cmp("B", "b"), int256(-1));
    }

    function test_cmp_differsByFirstByte() public pure {
        assertEq(StringUtils.cmp("azzzz", "baaaa"), int256(-1));
        assertEq(StringUtils.cmp("baaaa", "azzzz"), int256(1));
    }

    function test_cmp_differsInMiddle() public pure {
        assertEq(StringUtils.cmp("abcde", "abXde"), int256(1)); // 'c' (0x63) > 'X' (0x58)
        assertEq(StringUtils.cmp("abXde", "abcde"), int256(-1));
    }

    function test_cmp_differsByLastByte() public pure {
        assertEq(StringUtils.cmp("abcda", "abcdb"), int256(-1));
        assertEq(StringUtils.cmp("abcdb", "abcda"), int256(1));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_cmp_hasExactDomain(string memory x, string memory y) public pure {
        int256 z = StringUtils.cmp(x, y);
        assertTrue(z == int256(-1) || z == int256(0) || z == int256(1));
        assertEq(z == int256(0), keccak256(bytes(x)) == keccak256(bytes(y)));
    }

    function test_fuzz_cmp_reflexive(string memory x) public pure {
        assertEq(StringUtils.cmp(x, x), int256(0));
    }

    function test_fuzz_cmp_asymmetric(string memory x, string memory y) public pure {
        assertEq(StringUtils.cmp(x, y), -StringUtils.cmp(y, x));
    }

    function test_fuzz_cmp_transitive(string memory x, string memory y, string memory z) public pure {
        int256 xy = StringUtils.cmp(x, y);
        int256 yz = StringUtils.cmp(y, z);
        if (xy == yz && xy != int256(0)) assertEq(StringUtils.cmp(x, z), xy);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_diff_cmp(string memory x, string memory y) public pure {
        assertEq(StringUtils.cmp(x, y), referenceCmp(x, y));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceCmp(string memory x, string memory y) internal pure returns (int256) {
        bytes memory xb = bytes(x);
        bytes memory yb = bytes(y);

        uint256 length = min(xb.length, yb.length);
        for (uint256 i = 0; i < length; ++i) {
            if (xb[i] < yb[i]) return -1;
            if (xb[i] > yb[i]) return 1;
        }

        if (xb.length < yb.length) return -1;
        if (xb.length > yb.length) return 1;
        return 0;
    }
}
