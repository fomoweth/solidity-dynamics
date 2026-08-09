// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title BytesUtils
/// @author fomoweth
library BytesUtils {
    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONSTRUCTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function concat(bytes[] memory segments) internal pure returns (bytes memory result) {}

    function join(bytes[] memory segments, bytes memory delimiter) internal pure returns (bytes memory result) {}

    function split(bytes memory subject, bytes memory delimiter) internal pure returns (bytes[] memory result) {}

    function replace(bytes memory subject, bytes memory needle, bytes memory replacement)
        internal
        pure
        returns (bytes memory result)
    {}

    function repeat(bytes memory subject, uint256 count) internal pure returns (bytes memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SLICING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function slice(bytes memory subject, uint256 offset, uint256 length) internal pure returns (bytes memory result) {}

    function slice(bytes memory subject, uint256 offset) internal pure returns (bytes memory result) {
        return slice(subject, offset, type(uint256).max);
    }

    function truncate(bytes memory subject, uint256 length) internal pure returns (bytes memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SEARCHING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function indexOf(bytes memory subject, bytes memory needle, uint256 offset)
        internal
        pure
        returns (uint256 result)
    {}

    function indexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256 result) {
        return indexOf(subject, needle, 0);
    }

    function lastIndexOf(bytes memory subject, bytes memory needle, uint256 offset)
        internal
        pure
        returns (uint256 result)
    {}

    function lastIndexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256 result) {
        return lastIndexOf(subject, needle, type(uint256).max);
    }

    function indicesOf(bytes memory subject, bytes memory needle) internal pure returns (uint256[] memory result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            INSPECTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function contains(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (bool result) {}

    function contains(bytes memory subject, bytes memory needle) internal pure returns (bool result) {
        return contains(subject, needle, 0);
    }

    function startsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {}

    function endsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {}

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            COMPARISON
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Compares two byte arrays for equality.
    /// @param x The first byte array to compare.
    /// @param y The second byte array to compare.
    /// @return result Whether the two byte arrays are equal.
    function eq(bytes memory x, bytes memory y) internal pure returns (bool result) {
        assembly ("memory-safe") {
            result := eq(keccak256(add(x, 0x20), mload(x)), keccak256(add(y, 0x20), mload(y)))
        }
    }

    /// @notice Compares two byte arrays lexicographically by byte value.
    /// @dev Returns `-1`, `0`, or `1` if the first byte array is respectively less than,
    ///      equal to, or greater than the second byte array.
    ///      When all shared bytes compare equal, the shorter byte array is ordered first.
    /// @param x The first byte array to compare.
    /// @param y The second byte array to compare.
    /// @return result `-1`, `0`, or `1` depending on the lexicographical ordering.
    function cmp(bytes memory x, bytes memory y) internal pure returns (int256 result) {
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

                // Mask trailing bytes outside each byte array's logical length.
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
