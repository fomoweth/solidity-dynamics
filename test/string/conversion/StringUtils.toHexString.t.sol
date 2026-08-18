// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

abstract contract StringUtilsToHexStringTest is StringUtilsTest {
    bytes16 internal constant HEX_DIGITS = "0123456789abcdef";

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementations
    // ─────────────────────────────────────────────────────────────────────────────

    function toHexString(uint256 value, uint256 length, bool prefixed) internal pure returns (string memory) {
        uint256 prefixLength = prefixed ? 2 : 0;
        bytes memory buffer = new bytes(2 * length + prefixLength);

        if (prefixed) {
            buffer[0] = "0";
            buffer[1] = "x";
        }

        for (uint256 i = buffer.length; i > prefixLength;) {
            unchecked {
                buffer[--i] = HEX_DIGITS[value & 0x0f];
                buffer[--i] = HEX_DIGITS[(value >> 4) & 0x0f];
            }
            value >>= 8;
        }

        if (value != 0) revert StringUtils.InsufficientHexStringLength();
        return string(buffer);
    }

    function toHexString(uint256 value, bool prefixed) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, log256(value) + 1, prefixed);
        }
    }

    function toHexString(address value, bool prefixed, bool checksummed) internal pure returns (string memory) {
        bytes memory buffer = bytes(toHexString(uint256(uint160(value)), 20, prefixed));

        if (checksummed) {
            uint256 offset = prefixed ? 2 : 0;
            uint256 hashValue;
            assembly ("memory-safe") {
                hashValue := shr(0x60, keccak256(add(add(buffer, 0x20), offset), 0x28))
            }

            for (uint256 i = 40; i > 0; --i) {
                uint256 index = offset + i - 1;
                if ((hashValue & 0xf) > 7 && uint8(buffer[index]) > 0x60) {
                    buffer[index] ^= 0x20;
                }
                hashValue >>= 4;
            }
        }

        return string(buffer);
    }

    function toHexString(bytes memory input, bool prefixed) internal pure returns (string memory) {
        uint256 offset = prefixed ? 2 : 0;
        bytes memory buffer = new bytes(2 * input.length + offset);

        if (prefixed) {
            buffer[0] = "0";
            buffer[1] = "x";
        }

        for (uint256 i = 0; i < input.length; ++i) {
            uint8 v = uint8(input[i]);
            buffer[offset + 2 * i] = HEX_DIGITS[v >> 4];
            buffer[offset + 2 * i + 1] = HEX_DIGITS[v & 0x0f];
        }
        return string(buffer);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function log256(uint256 x) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := shl(7, gt(x, 0xffffffffffffffffffffffffffffffff))
            r := or(r, shl(6, gt(shr(r, x), 0xffffffffffffffff)))
            r := or(r, shl(5, gt(shr(r, x), 0xffffffff)))
            r := or(r, shl(4, gt(shr(r, x), 0xffff)))
            r := or(shr(3, r), gt(shr(r, x), 0xff))
        }
    }
}

contract StringUtilsToHexStringAddressTest is StringUtilsToHexStringTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toHexString_zero() public pure {
        assertEq(
            StringUtils.toHexString(0x0000000000000000000000000000000000000000),
            "0x0000000000000000000000000000000000000000"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0x0000000000000000000000000000000000000000),
            "0x0000000000000000000000000000000000000000"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0x0000000000000000000000000000000000000000),
            "0000000000000000000000000000000000000000"
        );
    }

    function test_toHexString_eip55Vectors() public pure {
        // Normal
        assertEq(
            StringUtils.toHexString(0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed),
            "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"
        );
        assertEq(
            StringUtils.toHexString(0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359),
            "0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"
        );
        assertEq(
            StringUtils.toHexString(0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB),
            "0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb"
        );
        assertEq(
            StringUtils.toHexString(0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb),
            "0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb"
        );

        // All Caps
        assertEq(
            StringUtils.toHexString(0x52908400098527886E0F7030069857D2E4169EE7),
            "0x52908400098527886e0f7030069857d2e4169ee7"
        );
        assertEq(
            StringUtils.toHexString(0x8617E340B3D01FA5F11F306F4090FD50E238070D),
            "0x8617e340b3d01fa5f11f306f4090fd50e238070d"
        );

        // All Lower
        assertEq(
            StringUtils.toHexString(0xde709f2102306220921060314715629080e2fb77),
            "0xde709f2102306220921060314715629080e2fb77"
        );
        assertEq(
            StringUtils.toHexString(0x27b1fdb04752bbc536007a920d24acb045561c26),
            "0x27b1fdb04752bbc536007a920d24acb045561c26"
        );
    }

    function test_toHexStringChecksummed_eip55Vectors() public pure {
        // Normal
        assertEq(
            StringUtils.toHexStringChecksummed(0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed),
            "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359),
            "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB),
            "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb),
            "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"
        );

        // All Caps
        assertEq(
            StringUtils.toHexStringChecksummed(0x52908400098527886E0F7030069857D2E4169EE7),
            "0x52908400098527886E0F7030069857D2E4169EE7"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0x8617E340B3D01FA5F11F306F4090FD50E238070D),
            "0x8617E340B3D01FA5F11F306F4090FD50E238070D"
        );

        // All Lower
        assertEq(
            StringUtils.toHexStringChecksummed(0xde709f2102306220921060314715629080e2fb77),
            "0xde709f2102306220921060314715629080e2fb77"
        );
        assertEq(
            StringUtils.toHexStringChecksummed(0x27b1fdb04752bbc536007a920d24acb045561c26),
            "0x27b1fdb04752bbc536007a920d24acb045561c26"
        );
    }

    function test_toHexStringNoPrefix_eip55Vectors() public pure {
        // Normal
        assertEq(
            StringUtils.toHexStringNoPrefix(0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed),
            "5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359),
            "fb6916095ca1df60bb79ce92ce3ea74c37c5d359"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB),
            "dbf03b407c01e7cd3cbea99509d93f8dddc8c6fb"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb),
            "d1220a0cf47c7b9be7a2e6ba89f429762e7b9adb"
        );

        // All Caps
        assertEq(
            StringUtils.toHexStringNoPrefix(0x52908400098527886E0F7030069857D2E4169EE7),
            "52908400098527886e0f7030069857d2e4169ee7"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0x8617E340B3D01FA5F11F306F4090FD50E238070D),
            "8617e340b3d01fa5f11f306f4090fd50e238070d"
        );

        // All Lower
        assertEq(
            StringUtils.toHexStringNoPrefix(0xde709f2102306220921060314715629080e2fb77),
            "de709f2102306220921060314715629080e2fb77"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix(0x27b1fdb04752bbc536007a920d24acb045561c26),
            "27b1fdb04752bbc536007a920d24acb045561c26"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_overloadEquivalence(address v) public pure {
        assertEq(StringUtils.toHexString(v), StringUtils.toHexString(v, true, false));
        assertEq(StringUtils.toHexStringNoPrefix(v), StringUtils.toHexString(v, false, false));
        assertEq(StringUtils.toHexStringChecksummed(v), StringUtils.toHexString(v, true, true));
        assertEq(StringUtils.toHexStringChecksummed(v), string.concat("0x", StringUtils.toHexString(v, false, true)));
    }

    function test_fuzz_toHexString_charset(address value) public pure {
        bytes memory result = bytes(StringUtils.toHexString(value));
        assertEq(result.length, 42, "hex address has incorrect length");
        assertEq(result[0], "0", "hex address is missing leading zero");
        assertEq(result[1], "x", "hex address is missing x prefix");

        for (uint256 i = 2; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            bool isDigit = char >= 0x30 && char <= 0x39;
            bool isLowercase = char >= 0x61 && char <= 0x66;
            assertTrue(isDigit || isLowercase, "hex address contains invalid lowercase hex character");
        }

        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringChecksummed_charset(address value) public pure {
        bytes memory result = bytes(StringUtils.toHexStringChecksummed(value));
        assertEq(result.length, 42, "checksummed address has incorrect length");
        assertEq(result[0], "0", "checksummed address is missing leading zero");
        assertEq(result[1], "x", "checksummed address is missing x prefix");

        for (uint256 i = 2; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            bool isDigit = char >= 0x30 && char <= 0x39;
            bool isUppercase = char >= 0x41 && char <= 0x46;
            bool isLowercase = char >= 0x61 && char <= 0x66;
            assertTrue(isDigit || isUppercase || isLowercase, "checksummed address contains invalid hex character");
        }

        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_roundtrip(address value) public pure {
        assertEq(vm.parseAddress(StringUtils.toHexString(value)), value, "hex address does not round-trip");
    }

    function test_fuzz_toHexStringChecksummed_roundtrip(address value) public pure {
        assertEq(
            vm.parseAddress(StringUtils.toHexStringChecksummed(value)), value, "checksummed address does not round-trip"
        );
    }

    function test_fuzz_toHexStringNoPrefix_roundtrip(address value) public pure {
        assertEq(
            vm.parseAddress(string.concat("0x", StringUtils.toHexStringNoPrefix(value))),
            value,
            "unprefixed hex address does not round-trip"
        );
    }

    function test_fuzz_toHexString(address value) public pure {
        assertEq(
            StringUtils.toHexString(value),
            vm.toLowercase(vm.toString(value)),
            "result differs from lowercase reference encoding"
        );
    }

    function test_fuzz_toHexStringChecksummed(address value) public pure {
        assertEq(
            StringUtils.toHexStringChecksummed(value),
            vm.toString(value),
            "result differs from checksummed reference encoding"
        );
    }

    function test_fuzz_toHexStringNoPrefix(address value) public pure {
        assertEq(
            StringUtils.toHexStringNoPrefix(value),
            vm.replace(vm.toLowercase(vm.toString(value)), "0x", ""),
            "result differs from unprefixed reference encoding"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_differential(address value, bool prefixed, bool checksummed) public pure {
        string memory expected = toHexString(value, prefixed, checksummed);
        string memory result = StringUtils.toHexString(value, prefixed, checksummed);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_differential(address value) public pure {
        string memory expected = toHexString(value, true, false);
        string memory result = StringUtils.toHexString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringChecksummed_differential(address value) public pure {
        string memory expected = toHexString(value, true, true);
        string memory result = StringUtils.toHexStringChecksummed(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringNoPrefix_differential(address value) public pure {
        string memory expected = toHexString(value, false, false);
        string memory result = StringUtils.toHexStringNoPrefix(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }
}

contract StringUtilsToHexStringBytesTest is StringUtilsToHexStringTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toHexString_basic() public pure {
        assertEq(StringUtils.toHexString(hex"00"), "0x00");
        assertEq(StringUtils.toHexStringNoPrefix(hex"00"), "00");

        assertEq(StringUtils.toHexString(hex"01"), "0x01");
        assertEq(StringUtils.toHexStringNoPrefix(hex"01"), "01");

        assertEq(StringUtils.toHexString(hex"02"), "0x02");
        assertEq(StringUtils.toHexStringNoPrefix(hex"02"), "02");

        assertEq(StringUtils.toHexString(hex"0102"), "0x0102");
        assertEq(StringUtils.toHexStringNoPrefix(hex"0102"), "0102");

        assertEq(StringUtils.toHexString(hex"0102ffff"), "0x0102ffff");
        assertEq(StringUtils.toHexStringNoPrefix(hex"0102ffff"), "0102ffff");

        assertEq(StringUtils.toHexString(hex"deadbeef"), "0xdeadbeef");
        assertEq(StringUtils.toHexStringNoPrefix(hex"deadbeef"), "deadbeef");
    }

    function test_toHexString_emptyBytes() public pure {
        assertEq(StringUtils.toHexString(hex""), "0x");
        assertEq(StringUtils.toHexStringNoPrefix(hex""), "");
    }

    function test_toHexString_longerThanWord() public pure {
        assertEq(
            StringUtils.toHexString("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
            "0x4142434445464748494a4b4c4d4e4f505152535455565758595a"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
            "4142434445464748494a4b4c4d4e4f505152535455565758595a"
        );

        assertEq(
            StringUtils.toHexString("abcdefghijklmnopqrstuvwxyz"),
            "0x6162636465666768696a6b6c6d6e6f707172737475767778797a"
        );
        assertEq(
            StringUtils.toHexStringNoPrefix("abcdefghijklmnopqrstuvwxyz"),
            "6162636465666768696a6b6c6d6e6f707172737475767778797a"
        );

        assertEq(StringUtils.toHexString("0123456789abcdef"), "0x30313233343536373839616263646566");
        assertEq(StringUtils.toHexStringNoPrefix("0123456789abcdef"), "30313233343536373839616263646566");
    }

    function test_toHexString_repeatedZeroBytes() public pure {
        bytes memory buffer = hex"";
        string memory zeroBytes = "";

        for (uint256 i = 0; i < 32; ++i) {
            string memory expected = string.concat("0x", zeroBytes = string.concat(zeroBytes, "00"));
            string memory result = StringUtils.toHexString(buffer = bytes.concat(buffer, hex"00"));

            assertEq(bytes(result).length, 2 * buffer.length + 2);
            assertEq(result, expected);
            assertMemoryInvariants(result);
        }
    }

    function test_toHexString_repeatedMaxBytes() public pure {
        bytes memory buffer = hex"";
        string memory maxBytes = "";

        for (uint256 i = 0; i < 32; ++i) {
            string memory expected = string.concat("0x", maxBytes = string.concat(maxBytes, "ff"));
            string memory result = StringUtils.toHexString(buffer = bytes.concat(buffer, hex"ff"));

            assertEq(bytes(result).length, 2 * buffer.length + 2);
            assertEq(result, expected);
            assertMemoryInvariants(result);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_overloadEquivalence(bytes memory buffer) public pure {
        assertEq(StringUtils.toHexString(buffer), StringUtils.toHexString(buffer, true));
        assertEq(StringUtils.toHexStringNoPrefix(buffer), StringUtils.toHexString(buffer, false));
    }

    function test_fuzz_toHexString_charset(bytes memory buffer) public pure {
        bytes memory result = bytes(StringUtils.toHexString(buffer));
        assertEq(result.length, 2 * buffer.length + 2, "hex string has incorrect length");
        assertEq(result[0], "0", "hex string is missing leading zero");
        assertEq(result[1], "x", "hex string is missing x prefix");

        for (uint256 i = 2; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            bool isDigit = char >= 0x30 && char <= 0x39;
            bool isLowercase = char >= 0x61 && char <= 0x66;
            assertTrue(isDigit || isLowercase, "hex string contains invalid lowercase hex character");
        }

        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_roundtrip(bytes memory buffer) public pure {
        assertEq(vm.parseBytes(StringUtils.toHexString(buffer)), buffer, "hex string does not round-trip");
    }

    function test_fuzz_toHexStringNoPrefix_roundtrip(bytes memory buffer) public pure {
        assertEq(
            vm.parseBytes(string.concat("0x", StringUtils.toHexStringNoPrefix(buffer))),
            buffer,
            "unprefixed hex string does not round-trip"
        );
    }

    function test_fuzz_toHexString(bytes memory buffer) public pure {
        assertEq(StringUtils.toHexString(buffer), vm.toString(buffer), "result differs from reference encoding");
    }

    function test_fuzz_toHexStringNoPrefix(bytes memory buffer) public pure {
        assertEq(
            StringUtils.toHexStringNoPrefix(buffer),
            vm.replace(vm.toString(buffer), "0x", ""),
            "result differs from unprefixed reference encoding"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_differential(bytes memory buffer, bool prefixed) public pure {
        string memory expected = toHexString(buffer, prefixed);
        string memory result = StringUtils.toHexString(buffer, prefixed);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_differential(bytes memory buffer) public pure {
        string memory expected = toHexString(buffer, true);
        string memory result = StringUtils.toHexString(buffer);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringNoPrefix_differential(bytes memory buffer) public pure {
        string memory expected = toHexString(buffer, false);
        string memory result = StringUtils.toHexStringNoPrefix(buffer);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }
}

contract StringUtilsToHexStringUint256Test is StringUtilsToHexStringTest {
    // ─────────────────────────────────────────────────────────────────────────────
    // 	Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toHexString_fixed_basic() public pure {
        assertEq(StringUtils.toHexString(uint256(0x00), 1), "0x00");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x0000), 2), "0000");

        assertEq(StringUtils.toHexString(uint256(0xff), 1), "0xff");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0xffff), 2), "ffff");

        assertEq(StringUtils.toHexString(uint256(0x0123), 2), "0x0123");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x0123), 2), "0123");

        assertEq(StringUtils.toHexString(uint256(0x0123), 4), "0x00000123");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x0123), 4), "00000123");
    }

    function test_toHexString_fixed_zero() public pure {
        assertEq(StringUtils.toHexString(uint256(0x00), 1), "0x00");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x00), 1), "00");
    }

    function test_toHexString_fixed_zeroLength() public pure {
        assertEq(StringUtils.toHexString(uint256(0x00), 0), "0x");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x00), 0), "");
    }

    function test_toHexString_fixed_maxValuePerByteLength() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 maxUint = type(uint256).max >> ((32 - i) << 3);
            string memory maxBytes = vm.toString(bytes32(maxUint));
            string memory expected = vm.replace(maxBytes, "00", "");
            string memory result = StringUtils.toHexString(maxUint, i);

            assertEq(bytes(result).length, 2 * i + 2);
            assertEq(result, expected);
            assertMemoryInvariants(result);
        }
    }

    function test_toHexString_fixed_leftZeroPadding() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            bytes memory result = bytes(StringUtils.toHexString(uint256(0xff), i));
            assertEq(result.length, 2 * i + 2);
            assertEq(result[0], "0");
            assertEq(result[1], "x");

            for (uint256 j = 2; j < result.length - 2; ++j) {
                assertEq(result[j], "0");
            }

            assertEq(result[result.length - 2], "f");
            assertEq(result[result.length - 1], "f");
            assertMemoryInvariants(result);
        }
    }

    function test_toHexString_basic() public pure {
        assertEq(StringUtils.toHexString(uint256(0x01)), "0x01");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x01)), "01");

        assertEq(StringUtils.toHexString(uint256(0x0123)), "0x0123");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x0123)), "0123");

        assertEq(StringUtils.toHexString(uint256(0xff)), "0xff");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0xff)), "ff");

        assertEq(StringUtils.toHexString(uint256(0xffff)), "0xffff");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0xffff)), "ffff");

        assertEq(StringUtils.toHexString(uint256(0xdeadbeef)), "0xdeadbeef");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0xdeadbeef)), "deadbeef");
    }

    function test_toHexString_zero() public pure {
        assertEq(StringUtils.toHexString(uint256(0x00)), "0x00");
        assertEq(StringUtils.toHexStringNoPrefix(uint256(0x00)), "00");
    }

    function test_toHexString_unsignedIntegerBoundaries() public pure {
        for (uint256 i = 1; i <= 32; ++i) {
            uint256 maxUint = type(uint256).max >> ((32 - i) << 3);
            string memory maxBytes = vm.toString(bytes32(maxUint));
            string memory expected = vm.replace(maxBytes, "00", "");
            string memory result = StringUtils.toHexString(maxUint);

            assertEq(result, expected);
            assertEq(vm.parseUint(result), maxUint);
            assertMemoryInvariants(result);
        }
    }

    function test_toHexString_fixed_revertsWithInsufficientHexStringLength() public {
        vm.expectRevert(StringUtils.InsufficientHexStringLength.selector);
        StringUtils.toHexString(uint256(0xabcd), 1);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_fixed_revertsIfInsufficientHexStringLength(uint256 value, uint8 length) public {
        vm.assume(length < log256(value));
        vm.expectRevert(StringUtils.InsufficientHexStringLength.selector);
        StringUtils.toHexString(value, length);
    }

    function test_fuzz_toHexString_overloadEquivalence(uint256 value) public pure {
        uint256 byteLength = log256(value) + 1;

        assertEq(StringUtils.toHexString(value), StringUtils.toHexString(value, true));
        assertEq(StringUtils.toHexStringNoPrefix(value), StringUtils.toHexString(value, false));
        assertEq(StringUtils.toHexString(value, byteLength), StringUtils.toHexString(value, byteLength, true));
        assertEq(StringUtils.toHexStringNoPrefix(value, byteLength), StringUtils.toHexString(value, byteLength, false));
    }

    function test_fuzz_toHexString_overloadEquivalence(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);

        assertEq(StringUtils.toHexString(value), StringUtils.toHexString(value, true));
        assertEq(StringUtils.toHexStringNoPrefix(value), StringUtils.toHexString(value, false));
        assertEq(StringUtils.toHexString(value, byteLength), StringUtils.toHexString(value, byteLength, true));
        assertEq(StringUtils.toHexStringNoPrefix(value, byteLength), StringUtils.toHexString(value, byteLength, false));
    }

    function test_fuzz_toHexString_fixed_charset(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);
        bytes memory result = bytes(StringUtils.toHexString(value, byteLength));

        assertEq(result.length, 2 * byteLength + 2, "hex string has incorrect fixed width");
        assertEq(result[0], "0", "hex string is missing leading zero");
        assertEq(result[1], "x", "hex string is missing x prefix");

        for (uint256 i = 2; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            bool isDigit = char >= 0x30 && char <= 0x39;
            bool isLowercase = char >= 0x61 && char <= 0x66;
            assertTrue(isDigit || isLowercase, "hex string contains invalid lowercase hex character");
        }

        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_fixed_roundtrip(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);

        assertEq(
            vm.parseUint(StringUtils.toHexString(value, byteLength)),
            value,
            "fixed-width hex string does not round-trip"
        );
    }

    function test_fuzz_toHexStringNoPrefix_fixed_roundtrip(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);

        assertEq(
            vm.parseUint(string.concat("0x", StringUtils.toHexStringNoPrefix(value, byteLength))),
            value,
            "unprefixed fixed-width hex string does not round-trip"
        );
    }

    function test_fuzz_toHexString_fixed(uint256 value, uint256 length) public {
        uint256 byteLength = bound(length, 1, type(uint8).max);
        if (byteLength < log256(value) + 1) vm.expectRevert(StringUtils.InsufficientHexStringLength.selector);

        assertEq(
            StringUtils.toHexString(value, byteLength),
            toHexString(value, byteLength, true),
            "result differs from reference implementation"
        );
    }

    function test_fuzz_toHexString_charset(uint256 value) public pure {
        bytes memory result = bytes(StringUtils.toHexString(value));
        assertEq(result[0], "0", "hex string is missing leading zero");
        assertEq(result[1], "x", "hex string is missing x prefix");

        for (uint256 i = 2; i < result.length; ++i) {
            uint8 char = uint8(result[i]);
            bool isDigit = char >= 0x30 && char <= 0x39;
            bool isLowercase = char >= 0x61 && char <= 0x66;
            assertTrue(isDigit || isLowercase, "hex string contains invalid lowercase hex character");
        }

        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_roundtrip(uint256 value) public pure {
        assertEq(vm.parseUint(StringUtils.toHexString(value)), value, "hex string does not round-trip");
    }

    function test_fuzz_toHexStringNoPrefix_roundtrip(uint256 value) public pure {
        assertEq(
            vm.parseUint(string.concat("0x", StringUtils.toHexStringNoPrefix(value))),
            value,
            "unprefixed hex string does not round-trip"
        );
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toHexString_fixed_differential(uint256 value, uint256 length, bool prefixed) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);
        string memory expected = toHexString(value, byteLength, prefixed);
        string memory result = StringUtils.toHexString(value, byteLength, prefixed);

        assertEq(bytes(result).length, 2 * byteLength + (prefixed ? 2 : 0), "hex string has incorrect fixed width");
        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_fixed_differential(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);
        string memory expected = toHexString(value, byteLength, true);
        string memory result = StringUtils.toHexString(value, byteLength);

        assertEq(bytes(result).length, 2 * byteLength + 2, "hex string has incorrect fixed width");
        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringNoPrefix_fixed_differential(uint256 value, uint256 length) public pure {
        uint256 byteLength = bound(length, log256(value) + 1, type(uint8).max);
        string memory expected = toHexString(value, byteLength, false);
        string memory result = StringUtils.toHexStringNoPrefix(value, byteLength);

        assertEq(bytes(result).length, 2 * byteLength, "hex string has incorrect fixed width");
        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_differential(uint256 value, bool prefixed) public pure {
        string memory expected = toHexString(value, prefixed);
        string memory result = StringUtils.toHexString(value, prefixed);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexString_differential(uint256 value) public pure {
        string memory expected = toHexString(value, true);
        string memory result = StringUtils.toHexString(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    function test_fuzz_toHexStringNoPrefix_differential(uint256 value) public pure {
        string memory expected = toHexString(value, false);
        string memory result = StringUtils.toHexStringNoPrefix(value);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }
}
