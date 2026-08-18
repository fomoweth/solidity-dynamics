// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StringUtils} from "src/StringUtils.sol";

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

    function capitalize(string memory subject) internal pure returns (string memory) {
        return string.concat(vm.toUppercase(StringUtils.slice(subject, 0, 1)), StringUtils.slice(subject, 1));
    }

    function coalesce(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := or(x, mul(y, iszero(x)))
        }
    }

    function ternary(bool condition, uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), iszero(condition)))
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
}

abstract contract BytesUtilsTest is BaseTest {
    function boundAscii(bytes memory subject) internal pure returns (bytes memory result) {
        result = new bytes(subject.length);
        for (uint256 i = 0; i < subject.length; ++i) {
            result[i] = bytes1(uint8(0x20 + (uint8(subject[i]) % 0x5f)));
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
    function boundAscii(bytes memory subject) internal pure returns (string memory) {
        bytes memory buffer = new bytes(subject.length);
        for (uint256 i = 0; i < subject.length; ++i) {
            buffer[i] = bytes1(uint8(0x20 + (uint8(subject[i]) % 0x5f)));
        }
        return string(buffer);
    }

    function allBytes() internal pure returns (string memory) {
        bytes memory buffer = new bytes(256);
        for (uint256 i = 0; i < 256; ++i) {
            buffer[i] = bytes1(uint8(i));
        }
        return string(buffer);
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
