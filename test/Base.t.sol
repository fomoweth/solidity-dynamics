// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    uint256 internal constant NOT_FOUND = type(uint256).max;

    function allBytes() internal pure returns (string memory) {
        bytes memory buffer = new bytes(256);
        for (uint256 i = 0; i < 256; ++i) {
            buffer[i] = bytes1(uint8(i));
        }
        return string(buffer);
    }

    function singleByte(uint256 value) internal pure returns (string memory) {
        vm.assume(value <= type(uint8).max);
        return string(abi.encodePacked(bytes1(uint8(value))));
    }

    function matchesAt(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (bool) {
        if (offset + needle.length > subject.length) return false;
        for (uint256 i = 0; i < needle.length; ++i) {
            if (subject[offset + i] != needle[i]) return false;
        }
        return true;
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
}
