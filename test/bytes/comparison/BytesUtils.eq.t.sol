// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {BytesUtils} from "src/BytesUtils.sol";

contract BytesUtilsEqTest is Test {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_eq_equal() public pure {
        assertTrue(BytesUtils.eq("hello", "hello"));
    }

    function test_eq_notEqual() public pure {
        assertFalse(BytesUtils.eq("hello", "world"));
    }

    function test_eq_emptyString_equal() public pure {
        assertTrue(BytesUtils.eq("", ""));
    }

    function test_eq_emptyString_notEqual() public pure {
        assertFalse(BytesUtils.eq("", "hello"));
        assertFalse(BytesUtils.eq("hello", ""));
    }

    function test_eq_caseSensitive() public pure {
        assertFalse(BytesUtils.eq("Hello", "hello"));
        assertFalse(BytesUtils.eq("HELLO", "hello"));
    }

    function test_eq_differentLengths() public pure {
        assertFalse(BytesUtils.eq("hello", "hello world"));
    }

    function test_eq_char_equal() public pure {
        assertTrue(BytesUtils.eq("a", "a"));
        assertTrue(BytesUtils.eq("A", "A"));
    }

    function test_eq_char_notEqual() public pure {
        assertFalse(BytesUtils.eq("a", "b"));
        assertFalse(BytesUtils.eq("a", "A"));
    }

    function test_eq_differsByFirstByte() public pure {
        assertFalse(BytesUtils.eq("hello", "xello"));
        assertFalse(BytesUtils.eq("hello", " hello"));
    }

    function test_eq_differsByLastByte() public pure {
        assertFalse(BytesUtils.eq("hello", "hellx"));
        assertFalse(BytesUtils.eq("hello", "hello "));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_eq_reflexive(bytes memory x) public pure {
        assertTrue(BytesUtils.eq(x, x));
    }

    function test_fuzz_eq_symmetric(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), BytesUtils.eq(y, x));
    }

    function test_fuzz_eq_transitive(bytes memory x, bytes memory y, bytes memory z) public pure {
        if (BytesUtils.eq(x, y) && BytesUtils.eq(y, z)) assertTrue(BytesUtils.eq(x, z));
    }

    function test_fuzz_eq(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), keccak256(x) == keccak256(y));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_eq_differential(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), referenceEq(x, y));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceEq(bytes memory x, bytes memory y) internal pure returns (bool) {
        if (x.length != y.length) return false;
        for (uint256 i = 0; i < x.length; ++i) {
            if (x[i] != y[i]) return false;
        }
        return true;
    }
}
