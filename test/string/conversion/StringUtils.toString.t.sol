// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsToStringTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit: uint256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toString_uint256_basic() public pure {
        assertEq(StringUtils.toString(uint256(0)), "0");
        assertEq(StringUtils.toString(uint256(1)), "1");
        assertEq(StringUtils.toString(uint256(10)), "10");
        assertEq(StringUtils.toString(uint256(56)), "56");
        assertEq(StringUtils.toString(uint256(130)), "130");
        assertEq(StringUtils.toString(uint256(137)), "137");
        assertEq(StringUtils.toString(uint256(8453)), "8453");
        assertEq(StringUtils.toString(uint256(42161)), "42161");
        assertEq(StringUtils.toString(uint256(43114)), "43114");
    }

    function test_toString_uint256_unsignedIntegerBoundaries() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 maxUint = type(uint256).max >> ((32 - i) << 3);
            assertEq(StringUtils.toString(maxUint), vm.toString(maxUint));
        }
    }

    function test_toString_uint256_powerOfTenBoundaries() public pure {
        for (uint256 i = 0; i < 77; ++i) {
            uint256 power = 10 ** i;
            uint256 previous = power - 1;

            string memory boundary = StringUtils.toString(power);
            string memory belowBoundary = StringUtils.toString(previous);

            assertEq(bytes(boundary).length, i + 1, "power of ten has incorrect digit count");
            assertEq(bytes(belowBoundary).length, i == 0 ? 1 : i, "value below boundary has incorrect digit count");

            assertEq(boundary, vm.toString(power), "boundary differs from reference encoding");
            assertEq(belowBoundary, vm.toString(previous), "value below boundary differs from reference encoding");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz: uint256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_uint256_charset(uint256 value) public pure {
        bytes memory result = bytes(StringUtils.toString(value));
        assertTrue(result.length > 0 && result.length <= 78, "decimal string has invalid length");

        uint256 parsed = 0;
        for (uint256 i = 0; i < result.length; ++i) {
            assertTrue(isNumeric(result[i]), "decimal string contains non-digit character");
            parsed = parsed * 10 + (uint8(result[i]) - 48);
        }

        assertEq(parsed, value, "parsed decimal string differs from value");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toString_uint256_roundtrip(uint256 value) public pure {
        assertEq(vm.parseUint(StringUtils.toString(value)), value, "decimal string does not round-trip");
    }

    function test_fuzz_toString_uint256_agreesWithCheatcode(uint256 value) public pure {
        string memory expected = vm.toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from cheatcode");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential: uint256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_uint256_differential(uint256 value) public pure {
        string memory expected = toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit: int256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toString_int256_basic() public pure {
        assertEq(StringUtils.toString(int256(0)), "0");
        assertEq(StringUtils.toString(int256(1)), "1");
        assertEq(StringUtils.toString(int256(-1)), "-1");
        assertEq(StringUtils.toString(int256(10)), "10");
        assertEq(StringUtils.toString(int256(-10)), "-10");
        assertEq(StringUtils.toString(int256(56)), "56");
        assertEq(StringUtils.toString(int256(-56)), "-56");
        assertEq(StringUtils.toString(int256(100)), "100");
        assertEq(StringUtils.toString(int256(-100)), "-100");
        assertEq(StringUtils.toString(int256(130)), "130");
        assertEq(StringUtils.toString(int256(-130)), "-130");
        assertEq(StringUtils.toString(int256(137)), "137");
        assertEq(StringUtils.toString(int256(-137)), "-137");
        assertEq(StringUtils.toString(int256(8453)), "8453");
        assertEq(StringUtils.toString(int256(-8453)), "-8453");
        assertEq(StringUtils.toString(int256(42161)), "42161");
        assertEq(StringUtils.toString(int256(-42161)), "-42161");
        assertEq(StringUtils.toString(int256(43114)), "43114");
        assertEq(StringUtils.toString(int256(-43114)), "-43114");
    }

    function test_toString_int256_signedIntegerBoundaries() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 bits = i << 3;
            int256 maxInt = int256(1 << (bits - 1) - 1);
            int256 minInt = -maxInt - 1;
            assertEq(StringUtils.toString(maxInt), vm.toString(maxInt));
            assertEq(StringUtils.toString(minInt), vm.toString(minInt));
        }
    }

    function test_toString_int256_powerOfTenBoundaries() public pure {
        for (uint256 i = 0; i < 77; ++i) {
            int256 power = int256(10 ** i);
            int256 previous = power - 1;

            string memory positive = StringUtils.toString(power);
            string memory positiveBelow = StringUtils.toString(previous);

            string memory negative = StringUtils.toString(-power);
            string memory negativeAbove = StringUtils.toString(-previous);

            assertEq(bytes(positive).length, i + 1, "positive boundary has incorrect digit count");
            assertEq(
                bytes(positiveBelow).length, i == 0 ? 1 : i, "value below positive boundary has incorrect digit count"
            );

            assertEq(bytes(negative).length, i + 2, "negative boundary has incorrect length");
            assertEq(
                bytes(negativeAbove).length, i == 0 ? 1 : i + 1, "value above negative boundary has incorrect length"
            );

            assertEq(positive, vm.toString(power), "positive boundary differs from reference encoding");
            assertEq(
                positiveBelow, vm.toString(previous), "value below positive boundary differs from reference encoding"
            );

            assertEq(negative, vm.toString(-power), "negative boundary differs from reference encoding");
            assertEq(
                negativeAbove, vm.toString(-previous), "value above negative boundary differs from reference encoding"
            );

            assertEq(
                vm.parseUint(positive), abs(vm.parseInt(negative)), "positive and negative boundary magnitudes differ"
            );
            assertEq(
                vm.parseUint(positiveBelow),
                abs(vm.parseInt(negativeAbove)),
                "adjacent positive and negative magnitudes differ"
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz: int256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_int256_charset(int256 value) public pure {
        bytes memory result = bytes(StringUtils.toString(value));
        assertTrue(result.length > 0 && result.length <= 78, "decimal string has invalid length");

        if (value < 0) {
            assertEq(result[0], "-", "negative value is missing minus sign");
            assertTrue(result[1] != "0", "negative value has leading zero");
        } else if (result.length > 1) {
            assertTrue(result[0] != "0", "positive value has leading zero");
        }

        uint256 offset = value < 0 ? 1 : 0;
        uint256 parsed = 0;
        for (uint256 i = offset; i < result.length; ++i) {
            assertTrue(isNumeric(result[i]), "decimal string contains non-digit character");
            parsed = parsed * 10 + (uint8(result[i]) - 48);
        }

        assertEq(parsed, abs(value), "parsed magnitude differs from absolute value");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toString_int256_roundtrip(int256 value) public pure {
        assertEq(vm.parseInt(StringUtils.toString(value)), value, "decimal string does not round-trip");
    }

    function test_fuzz_toString_int256_agreesWithCheatcode(int256 value) public pure {
        string memory expected = vm.toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from cheatcode");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential: int256
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_int256_differential(int256 value) public pure {
        string memory expected = toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementations
    // ─────────────────────────────────────────────────────────────────────────────

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 ptr = log10(value) + 1;
            bytes memory buffer = new bytes(ptr);
            while (true) {
                buffer[--ptr] = bytes1(uint8(48 + (value % 10)));
                value /= 10;
                if (value == 0) break;
            }
            return string(buffer);
        }
    }

    function toString(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(abs(value)));
    }
}
