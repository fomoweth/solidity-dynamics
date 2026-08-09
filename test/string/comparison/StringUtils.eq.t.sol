// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StringUtils} from "src/StringUtils.sol";

contract StringUtilsEqTest is Test {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_eq_equal() public pure {
        assertTrue(StringUtils.eq("hello", "hello"));
    }

    function test_eq_notEqual() public pure {
        assertFalse(StringUtils.eq("hello", "world"));
    }

    function test_eq_emptyString_equal() public pure {
        assertTrue(StringUtils.eq("", ""));
    }

    function test_eq_emptyString_notEqual() public pure {
        assertFalse(StringUtils.eq("", "hello"));
        assertFalse(StringUtils.eq("hello", ""));
    }

    function test_eq_caseSensitive() public pure {
        assertFalse(StringUtils.eq("Hello", "hello"));
        assertFalse(StringUtils.eq("HELLO", "hello"));
    }

    function test_eq_differentLengths() public pure {
        assertFalse(StringUtils.eq("hello", "hello world"));
    }

    function test_eq_char_equal() public pure {
        assertTrue(StringUtils.eq("a", "a"));
        assertTrue(StringUtils.eq("A", "A"));
    }

    function test_eq_char_notEqual() public pure {
        assertFalse(StringUtils.eq("a", "b"));
        assertFalse(StringUtils.eq("a", "A"));
    }

    function test_eq_differsByFirstByte() public pure {
        assertFalse(StringUtils.eq("hello", "xello"));
        assertFalse(StringUtils.eq("hello", " hello"));
    }

    function test_eq_differsByLastByte() public pure {
        assertFalse(StringUtils.eq("hello", "hellx"));
        assertFalse(StringUtils.eq("hello", "hello "));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_eq_reflexive(string memory x) public pure {
        assertTrue(StringUtils.eq(x, x));
    }

    function test_fuzz_eq_symmetric(string memory x, string memory y) public pure {
        assertEq(StringUtils.eq(x, y), StringUtils.eq(y, x));
    }

    function test_fuzz_eq_transitive(string memory x, string memory y, string memory z) public pure {
        if (StringUtils.eq(x, y) && StringUtils.eq(y, z)) assertTrue(StringUtils.eq(x, z));
    }

    function test_fuzz_eq(string memory x, string memory y) public pure {
        assertEq(StringUtils.eq(x, y), keccak256(bytes(x)) == keccak256(bytes(y)));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_diff_eq(string memory x, string memory y) public pure {
        assertEq(StringUtils.eq(x, y), referenceEq(x, y));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceEq(string memory x, string memory y) internal pure returns (bool) {
        bytes memory xb = bytes(x);
        bytes memory yb = bytes(y);
        if (xb.length != yb.length) return false;
        for (uint256 i = 0; i < xb.length; ++i) {
            if (xb[i] != yb[i]) return false;
        }
        return true;
    }
}
