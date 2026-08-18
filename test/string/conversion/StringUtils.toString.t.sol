// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

abstract contract StringUtilsToStringTest is StringUtilsTest {
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

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function abs(int256 x) internal pure returns (uint256 z) {
        unchecked {
            uint256 mask = uint256(x >> 255);
            z = (uint256(x) + mask) ^ mask;
        }
    }

    function log10(uint256 x) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
        }
    }
}

contract StringUtilsToStringUint256Test is StringUtilsToStringTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toString_basic() public pure {
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

    function test_toString_unsignedIntegerBoundaries() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 maxUint = type(uint256).max >> ((32 - i) << 3);
            assertEq(StringUtils.toString(maxUint), vm.toString(maxUint));
        }
    }

    function test_toString_powerOfTenBoundaries() public pure {
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
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_charset(uint256 value) public pure {
        bytes memory result = bytes(StringUtils.toString(value));
        assertTrue(result.length > 0 && result.length <= 78, "decimal string has invalid length");

        uint256 parsed = 0;
        for (uint256 i = 0; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            assertTrue(char >= 0x30 && char <= 0x39, "decimal string contains non-digit character");
            parsed = parsed * 10 + (char - 48);
        }

        assertEq(parsed, value, "parsed decimal string differs from value");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toString_roundtrip(uint256 value) public pure {
        assertEq(vm.parseUint(StringUtils.toString(value)), value, "decimal string does not round-trip");
    }

    function test_fuzz_toString(uint256 value) public pure {
        assertEq(StringUtils.toString(value), vm.toString(value), "result differs from vm.toString");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_differential(uint256 value) public pure {
        string memory expected = toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }
}

contract StringUtilsToStringInt256Test is StringUtilsToStringTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toString_basic() public pure {
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

    function test_toString_signedIntegerBoundaries() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 bits = i << 3;
            int256 maxInt = int256(1 << (bits - 1) - 1);
            int256 minInt = -maxInt - 1;
            assertEq(StringUtils.toString(maxInt), vm.toString(maxInt));
            assertEq(StringUtils.toString(minInt), vm.toString(minInt));
        }
    }

    function test_toString_powerOfTenBoundaries() public pure {
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
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_charset(int256 value) public pure {
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
            uint8 char = uint8(result[i]);
            assertTrue(char >= 0x30 && char <= 0x39, "decimal string contains non-digit character");
            parsed = parsed * 10 + (char - 0x30);
        }

        assertEq(parsed, abs(value), "parsed magnitude differs from absolute value");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toString_roundtrip(int256 value) public pure {
        assertEq(vm.parseInt(StringUtils.toString(value)), value, "decimal string does not round-trip");
    }

    function test_fuzz_toString(int256 value) public pure {
        assertEq(StringUtils.toString(value), vm.toString(value), "result differs from vm.toString");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toString_differential(int256 value) public pure {
        string memory expected = toString(value);
        string memory result = StringUtils.toString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }
}
