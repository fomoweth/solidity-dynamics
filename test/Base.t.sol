// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    uint256 internal constant NOT_FOUND = type(uint256).max;

    function assertMemoryInvariants(bytes memory buffer) internal pure {
        uint256 offset;
        uint256 length;
        uint256 ptr;
        assembly ("memory-safe") {
            offset := buffer
            length := mload(buffer)
            ptr := mload(0x40)
        }
        assertTrue(offset == 0x60 || offset + 0x20 + length <= ptr, "bytes data extends past free memory pointer");
    }

    function assertMemoryInvariants(string memory buffer) internal pure {
        uint256 offset;
        uint256 length;
        uint256 ptr;
        assembly ("memory-safe") {
            offset := buffer
            length := mload(buffer)
            ptr := mload(0x40)
        }
        assertTrue(offset == 0x60 || offset + 0x20 + length <= ptr, "string data extends past free memory pointer");
    }

    function matchesAt(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (bool) {
        if (offset + needle.length > subject.length) return false;
        for (uint256 i = 0; i < needle.length; ++i) {
            if (subject[i + offset] != needle[i]) return false;
        }
        return true;
    }

    function matchesAt(string memory subject, string memory needle, uint256 offset) internal pure returns (bool) {
        return matchesAt(bytes(subject), bytes(needle), offset);
    }

    function isAlphanumeric(bytes1 char) internal pure virtual returns (bool) {
        return isNumeric(char) || isUpperCase(char) || isLowerCase(char);
    }

    function isNumeric(bytes1 char) internal pure virtual returns (bool) {
        return char >= 0x30 && char <= 0x39; // (`0` - `9`)
    }

    function isUpperCase(bytes1 char) internal pure virtual returns (bool) {
        return char >= 0x41 && char <= 0x5a; // (`A` - `Z`)
    }

    function isLowerCase(bytes1 char) internal pure virtual returns (bool) {
        return char >= 0x61 && char <= 0x7a; // (`a` - `z`)
    }

    function isPrintable(bytes1 char) internal pure virtual returns (bool) {
        return char >= 0x20 && char <= 0x7e; // (` ` - `~`)
    }

    function isSeparator(bytes1 char) internal pure virtual returns (bool) {
        return char == 0x20 // space (` `)
            || char == 0x2d // hyphen (`-`)
            || char == 0x5f; // underscore (`_`)
    }

    function isWhitespace(bytes1 char) internal pure virtual returns (bool) {
        // horizontal tab (`\t`), line feed (`\n`), vertical tab (`\v`),
        // form feed (`\f`), carriage return (`\r`), or space (` `)
        return (char >= 0x09 && char <= 0x0d) || char == 0x20;
    }

    function toUpperCase(bytes1 char) internal pure returns (bytes1) {
        return isLowerCase(char) ? bytes1(uint8(char) - 0x20) : char;
    }

    function toLowerCase(bytes1 char) internal pure returns (bytes1) {
        return isUpperCase(char) ? bytes1(uint8(char) + 0x20) : char;
    }

    function coalesce(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := or(x, mul(y, iszero(x)))
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    function saturatingSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := mul(sub(x, y), gt(x, y))
        }
    }

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

abstract contract BytesUtilsTest is BaseTest {
    function boundAscii(bytes memory subject) internal pure returns (bytes memory result) {
        result = new bytes(subject.length);
        for (uint256 i = 0; i < subject.length; ++i) {
            result[i] = bytes1(32 + (uint8(subject[i]) % 95));
        }
    }

    function allBytes() internal pure returns (bytes memory result) {
        result = new bytes(256);
        for (uint256 i = 0; i < 256; ++i) {
            result[i] = bytes1(uint8(i));
        }
    }

    function singleByte(uint256 value) internal pure returns (bytes memory) {
        assertLe(value, type(uint8).max);
        return abi.encodePacked(bytes1(uint8(value)));
    }

    function arrayify(bytes memory a) internal pure returns (bytes[] memory result) {
        result = new bytes[](1);
        result[0] = a;
    }

    function arrayify(bytes memory a, bytes memory b) internal pure returns (bytes[] memory result) {
        result = new bytes[](2);
        result[0] = a;
        result[1] = b;
    }

    function arrayify(bytes memory a, bytes memory b, bytes memory c) internal pure returns (bytes[] memory result) {
        result = new bytes[](3);
        result[0] = a;
        result[1] = b;
        result[2] = c;
    }

    function arrayify(bytes memory a, bytes memory b, bytes memory c, bytes memory d)
        internal
        pure
        returns (bytes[] memory result)
    {
        result = new bytes[](4);
        result[0] = a;
        result[1] = b;
        result[2] = c;
        result[3] = d;
    }
}

abstract contract StringUtilsTest is BaseTest {
    function boundAscii(string memory subject) internal pure returns (string memory) {
        bytes memory buffer = bytes(subject);
        bytes memory result = new bytes(buffer.length);
        for (uint256 i = 0; i < result.length; ++i) {
            result[i] = bytes1(32 + (uint8(buffer[i]) % 95));
        }
        return string(result);
    }

    function allBytes() internal pure returns (string memory) {
        bytes memory result = new bytes(256);
        for (uint256 i = 0; i < 256; ++i) {
            result[i] = bytes1(uint8(i));
        }
        return string(result);
    }

    function singleByte(uint256 value) internal pure returns (string memory) {
        assertLe(value, type(uint8).max);
        return string(abi.encodePacked(bytes1(uint8(value))));
    }

    function arrayify(string memory a) internal pure returns (string[] memory result) {
        result = new string[](1);
        result[0] = a;
    }

    function arrayify(string memory a, string memory b) internal pure returns (string[] memory result) {
        result = new string[](2);
        result[0] = a;
        result[1] = b;
    }

    function arrayify(string memory a, string memory b, string memory c)
        internal
        pure
        returns (string[] memory result)
    {
        result = new string[](3);
        result[0] = a;
        result[1] = b;
        result[2] = c;
    }

    function arrayify(string memory a, string memory b, string memory c, string memory d)
        internal
        pure
        returns (string[] memory result)
    {
        result = new string[](4);
        result[0] = a;
        result[1] = b;
        result[2] = c;
        result[3] = d;
    }
}
