// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title StringUtils
/// @author fomoweth
library StringUtils {
    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONVERSION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function toString(uint256 value) internal pure returns (string memory result) {}

    function toString(int256 value) internal pure returns (string memory result) {}

    function toHexString(uint256 value, uint256 byteLength, bool prefixed)
        internal
        pure
        returns (string memory result)
    {}

    function toHexString(uint256 value, bool prefixed) internal pure returns (string memory result) {}

    function toHexString(address value, bool prefixed, bool checksummed) internal pure returns (string memory result) {}

    function toHexString(bytes memory buffer, bool prefixed) internal pure returns (string memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            FORMATTING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function toLowerCase(string memory subject) internal pure returns (string memory result) {}

    function toUpperCase(string memory subject) internal pure returns (string memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONSTRUCTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function concat(string[] memory segments) internal pure returns (string memory result) {}

    function join(string[] memory segments, string memory delimiter) internal pure returns (string memory result) {}

    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {}

    function replace(string memory subject, string memory needle, string memory replacement)
        internal
        pure
        returns (string memory result)
    {}

    function repeat(string memory subject, uint256 count) internal pure returns (string memory result) {}

    function padStart(string memory subject, string memory needle, uint256 length)
        internal
        pure
        returns (string memory result)
    {}

    function padEnd(string memory subject, string memory needle, uint256 length)
        internal
        pure
        returns (string memory result)
    {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SLICING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function slice(string memory subject, uint256 offset, uint256 length)
        internal
        pure
        returns (string memory result)
    {}

    function slice(string memory subject, uint256 offset) internal pure returns (string memory result) {
        return slice(subject, offset, type(uint256).max);
    }

    function truncate(string memory subject, uint256 length) internal pure returns (string memory result) {}

    function trim(string memory subject) internal pure returns (string memory result) {}

    function trimStart(string memory subject) internal pure returns (string memory result) {}

    function trimEnd(string memory subject) internal pure returns (string memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SEARCHING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function indexOf(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (uint256 result)
    {}

    function indexOf(string memory subject, string memory needle) internal pure returns (uint256 result) {
        return indexOf(subject, needle, 0);
    }

    function lastIndexOf(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (uint256 result)
    {}

    function lastIndexOf(string memory subject, string memory needle) internal pure returns (uint256 result) {
        return lastIndexOf(subject, needle, type(uint256).max);
    }

    function indicesOf(string memory subject, string memory needle) internal pure returns (uint256[] memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            INSPECTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function contains(string memory subject, string memory needle, uint256 offset)
        internal
        pure
        returns (bool result)
    {}

    function contains(string memory subject, string memory needle) internal pure returns (bool result) {
        return contains(subject, needle, 0);
    }

    function startsWith(string memory subject, string memory needle) internal pure returns (bool result) {}

    function endsWith(string memory subject, string memory needle) internal pure returns (bool result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            COMPARISON
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Compares two strings for equality.
    /// @param x The first string to compare.
    /// @param y The second string to compare.
    /// @return result Whether the two strings are equal.
    function eq(string memory x, string memory y) internal pure returns (bool result) {
        assembly ("memory-safe") {
            result := eq(keccak256(add(x, 0x20), mload(x)), keccak256(add(y, 0x20), mload(y)))
        }
    }

    /// @notice Compares two strings lexicographically by byte value.
    /// @dev Returns `-1`, `0`, or `1` if the first string is respectively less than,
    ///      equal to, or greater than the second string.
    ///      When all shared bytes compare equal, the shorter string is ordered first.
    /// @param x The first string to compare.
    /// @param y The second string to compare.
    /// @return result `-1`, `0`, or `1` depending on the lexicographical ordering.
    function cmp(string memory x, string memory y) internal pure returns (int256 result) {
        assembly ("memory-safe") {
            // Compute the shared length that can be compared as complete 32-byte words:
            // `floor(min(x.length, y.length) ÷ 32) × 32`.
            let xLength := mload(x)
            let yLength := mload(y)
            let length := and(xor(xLength, mul(xor(xLength, yLength), lt(yLength, xLength))), not(0x1f))

            if length {
                // Compare complete words from left to right. Unsigned integer comparison
                // preserves the lexicographical ordering of their big-endian byte sequences.
                for { let offset := 0x20 } 0x01 {} {
                    let xWord := mload(add(x, offset))
                    let yWord := mload(add(y, offset))

                    // Continue while equal and another shared word remains.
                    if iszero(or(xor(xWord, yWord), eq(offset, length))) {
                        offset := add(offset, 0x20)
                        continue
                    }

                    // The first differing word determines the ordering.
                    result := sub(gt(xWord, yWord), lt(xWord, yWord))
                    break
                }
            }

            // forgefmt: disable-next-item
            if iszero(result) {
                // Map the remaining byte count to the shift used for the partial-word mask.
                let table := 0x201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201
                let mask := not(0x00)

                // Mask trailing bytes outside each string's logical length.
                let xWord := and(mload(add(add(x, 0x20), length)), shl(shl(0x03, byte(sub(xLength, length), table)), mask))
                let yWord := and(mload(add(add(y, 0x20), length)), shl(shl(0x03, byte(sub(yLength, length), table)), mask))

                // The first differing word determines the ordering.
                result := sub(gt(xWord, yWord), lt(xWord, yWord))

                // Equal shared bytes are ordered by total length.
                if iszero(result) { result := sub(gt(xLength, yLength), lt(xLength, yLength)) }
            }
        }
    }
}
