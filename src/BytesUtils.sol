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

    /// @notice Extracts a byte array from a specified byte offset with a maximum byte length.
    /// @dev Clamps the requested length to the remaining bytes of the byte array.
    ///      Returns an empty byte array if the starting offset is greater than or equal to the byte length.
    /// @param subject The byte array to slice.
    /// @param offset The zero-based byte offset at which the slice begins.
    /// @param length The maximum number of bytes to include.
    /// @return result The extracted byte array.
    function slice(bytes memory subject, uint256 offset, uint256 length) internal pure returns (bytes memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Clamp the starting offset to the end of the subject.
            let subjectLength := mload(subject)
            if gt(offset, subjectLength) { offset := subjectLength }

            // Derive the exclusive end offset, clamping it to the subject length on overflow or overrun.
            let end := add(offset, length)
            if or(lt(end, offset), gt(end, subjectLength)) { end := subjectLength }

            // Store the output length and copy the selected byte range.
            length := sub(end, offset)
            mstore(result, length)
            mcopy(ptr, add(add(subject, 0x20), offset), length)

            // Derive the logical output end.
            ptr := add(ptr, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @dev Variant of {slice-bytes-uint256-uint256} with `length` set to `type(uint256).max`.
    function slice(bytes memory subject, uint256 offset) internal pure returns (bytes memory result) {
        return slice(subject, offset, type(uint256).max);
    }

    /// @notice Shortens a byte array in place to at most a specified number of bytes.
    /// @dev Does not allocate memory. The returned byte array aliases the subject, so truncation is observable through
    ///      other references to the same byte array. Use {slice-bytes-uint256-uint256} to obtain an independent copy.
    ///      Leaves the byte array unchanged if the requested length is greater than or equal to its byte length.
    /// @param subject The byte array to truncate.
    /// @param length The maximum number of bytes to retain.
    /// @return result The truncated byte array.
    function truncate(bytes memory subject, uint256 length) internal pure returns (bytes memory result) {
        assembly ("memory-safe") {
            // Reuse the original allocation by aliasing the subject.
            result := subject

            // Shrink the logical length only when truncation is required.
            if lt(length, mload(result)) { mstore(result, length) }
        }
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SEARCHING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Finds the byte index of the first occurrence of a byte sequence within a byte array, searching
    ///         forward from a specified byte offset.
    /// @dev An empty byte sequence matches at the lesser of the starting offset and the byte array's length.
    /// @param subject The byte array to search within.
    /// @param needle The byte sequence to search for.
    /// @param offset The zero-based byte offset from which to begin searching.
    /// @return result The byte index of the first match, or `type(uint256).max` if no match exists.
    function indexOf(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            // Initialize the output to the not-found sentinel.
            result := not(0x00)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            // Clamp the starting offset to the final boundary of the subject.
            if gt(offset, subjectLength) { offset := subjectLength }

            switch needleLength
            case 0x00 {
                // An empty sequence matches at the starting byte boundary.
                result := offset
            }
            default {
                // Search only when the needle fits and the starting offset is a valid candidate.
                if and(iszero(gt(needleLength, subjectLength)), iszero(gt(offset, sub(subjectLength, needleLength)))) {
                    // Advance to the input byte data.
                    subject := add(subject, 0x20)
                    needle := add(needle, 0x20)

                    // Derive the exclusive search boundary.
                    let guard := add(add(subject, sub(subjectLength, needleLength)), 0x01)

                    // Derive the shift used to compare the significant leading bytes.
                    let maskShift := mul(shl(0x03, sub(0x20, needleLength)), lt(needleLength, 0x20))

                    // Needles of at least 32-bytes additionally require a full-length hash comparison.
                    let requiresHash := iszero(lt(needleLength, 0x20))
                    let needleWord := mload(needle)
                    let needleHash := 0x00
                    if requiresHash { needleHash := keccak256(needle, needleLength) }

                    // Examine each valid candidate position from left to right.
                    for { let cursor := add(subject, offset) } lt(cursor, guard) { cursor := add(cursor, 0x01) } {
                        let matched := iszero(shr(maskShift, xor(mload(cursor), needleWord)))

                        if and(matched, requiresHash) {
                            matched := eq(keccak256(cursor, needleLength), needleHash)
                        }

                        if matched {
                            result := sub(cursor, subject)
                            break
                        }
                    }
                }
            }
        }
    }

    /// @dev Variant of {indexOf-bytes-bytes-uint256} with `offset` set to `0`.
    function indexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256 result) {
        return indexOf(subject, needle, 0);
    }

    /// @notice Finds the byte index of the last occurrence of a byte sequence within a byte array, searching
    ///         backward from a specified byte offset.
    /// @dev An empty byte sequence matches at the lesser of the starting offset and the byte array's length.
    /// @param subject The byte array to search within.
    /// @param needle The byte sequence to search for.
    /// @param offset The zero-based byte offset from which to begin searching backward.
    /// @return result The byte index of the last match, or `type(uint256).max` if no match exists.
    function lastIndexOf(bytes memory subject, bytes memory needle, uint256 offset)
        internal
        pure
        returns (uint256 result)
    {
        assembly ("memory-safe") {
            // Initialize the output to the not-found sentinel.
            result := not(0x00)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            // Search only when the needle fits within the subject.
            if iszero(gt(needleLength, subjectLength)) {
                // Clamp the requested offset to the final position at which the complete needle can begin.
                let maxOffset := sub(subjectLength, needleLength)
                if gt(offset, maxOffset) { offset := maxOffset }

                // Advance to the input byte data.
                subject := add(subject, 0x20)
                needle := add(needle, 0x20)

                let stride := not(0x00) // -1 modulo 2²⁵⁶

                // Derive the exclusive search boundary.
                let guard := add(subject, stride)

                // Derive the shift used to compare the significant leading bytes.
                let maskShift := mul(shl(0x03, sub(0x20, needleLength)), lt(needleLength, 0x20))

                // Needles of at least 32-bytes additionally require a full-length hash comparison.
                let requiresHash := iszero(lt(needleLength, 0x20))
                let needleWord := mload(needle)
                let needleHash := 0x00
                if requiresHash { needleHash := keccak256(needle, needleLength) }

                // Examine each valid candidate position from right to left.
                for { let cursor := add(subject, offset) } gt(cursor, guard) { cursor := add(cursor, stride) } {
                    let matched := iszero(shr(maskShift, xor(mload(cursor), needleWord)))

                    if and(matched, requiresHash) {
                        matched := eq(keccak256(cursor, needleLength), needleHash)
                    }

                    if matched {
                        result := sub(cursor, subject)
                        break
                    }
                }
            }
        }
    }

    /// @dev Variant of {lastIndexOf-bytes-bytes-uint256} with `offset` set to `type(uint256).max`.
    function lastIndexOf(bytes memory subject, bytes memory needle) internal pure returns (uint256 result) {
        return lastIndexOf(subject, needle, type(uint256).max);
    }

    /// @notice Finds the byte indices of every non-overlapping occurrence of a byte sequence within a byte array.
    /// @dev An empty byte sequence matches at every byte boundary, including the boundary after the final byte.
    ///      Returns an empty array if no match exists.
    /// @param subject The byte array to search within.
    /// @param needle The byte sequence to search for.
    /// @return result The byte indices of all matches in ascending order.
    function indicesOf(bytes memory subject, bytes memory needle) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            switch needleLength
            case 0x00 {
                // An empty sequence matches at every byte boundary.
                for { let index := 0x00 } iszero(gt(index, subjectLength)) { index := add(index, 0x01) } {
                    mstore(ptr, index)
                    ptr := add(ptr, 0x20)
                }
            }
            default {
                // Search only when the needle fits within the subject.
                if iszero(gt(needleLength, subjectLength)) {
                    // Advance to the input byte data.
                    subject := add(subject, 0x20)
                    needle := add(needle, 0x20)

                    // Derive the exclusive search boundary.
                    let guard := add(add(subject, sub(subjectLength, needleLength)), 0x01)

                    // Derive the shift used to compare the significant leading bytes.
                    let maskShift := mul(shl(0x03, sub(0x20, needleLength)), lt(needleLength, 0x20))

                    // Needles of at least 32-bytes additionally require a full-length hash comparison.
                    let requiresHash := iszero(lt(needleLength, 0x20))
                    let needleWord := mload(needle)
                    let needleHash := 0x00
                    if requiresHash { needleHash := keccak256(needle, needleLength) }

                    // Examine candidate positions from left to right.
                    for { let cursor := subject } lt(cursor, guard) {} {
                        let matched := iszero(shr(maskShift, xor(mload(cursor), needleWord)))

                        if and(matched, requiresHash) {
                            matched := eq(keccak256(cursor, needleLength), needleHash)
                        }

                        if matched {
                            // Record the match index and advance past the needle to exclude overlaps.
                            mstore(ptr, sub(cursor, subject))
                            ptr := add(ptr, 0x20)
                            cursor := add(cursor, needleLength)
                            continue
                        }

                        cursor := add(cursor, 0x01)
                    }
                }
            }

            // Store the output length.
            mstore(result, shr(0x05, sub(ptr, add(result, 0x20))))

            // Advance the free-memory pointer.
            mstore(0x40, ptr)
        }
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            INSPECTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Determines whether a byte array contains a byte sequence at or after a specified byte offset.
    /// @dev An empty byte sequence matches if the starting offset is less than or equal to the byte array's length.
    /// @param subject The byte array to search within.
    /// @param needle The byte sequence to search for.
    /// @param offset The zero-based byte offset from which to begin searching.
    /// @return result Whether a match exists at or after the specified offset.
    function contains(bytes memory subject, bytes memory needle, uint256 offset) internal pure returns (bool result) {
        return indexOf(subject, needle, offset) != type(uint256).max;
    }

    /// @dev Variant of {contains-bytes-bytes-uint256} with `offset` set to `0`.
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
