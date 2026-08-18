// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BytesUtils} from "src/BytesUtils.sol";
import {BytesUtilsTest} from "test/Base.t.sol";

contract BytesUtilsEqTest is BytesUtilsTest {
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
        assertTrue(BytesUtils.eq(x, x), "equality is not reflexive");
    }

    function test_fuzz_eq_transitive(bytes memory x) public pure {
        bytes memory y = x;
        bytes memory z = y;
        assertTrue(BytesUtils.eq(x, y), "first equality does not hold");
        assertTrue(BytesUtils.eq(y, z), "second equality does not hold");
        assertTrue(BytesUtils.eq(x, z), "equality is not transitive");
    }

    function test_fuzz_eq_symmetric(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), BytesUtils.eq(y, x), "equality is not symmetric");
    }

    function test_fuzz_eq_matchesKeccak256(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), keccak256(x) == keccak256(y), "equality differs from keccak256 comparison");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_eq_differential(bytes memory x, bytes memory y) public pure {
        assertEq(BytesUtils.eq(x, y), referenceEq(x, y), "result differs from reference implementation");
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
