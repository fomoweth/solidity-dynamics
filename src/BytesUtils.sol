// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title BytesUtils
/// @author fomoweth
/// @notice Utilities for constructing, slicing, searching, and comparing byte arrays.
library BytesUtils {
    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONSTRUCTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Concatenates a sequence of byte arrays.
    /// @dev Returns an empty byte array if the array is empty.
    /// @param segments The array of byte arrays to concatenate.
    /// @return result The concatenated byte array.
    function concat(bytes[] memory segments) internal pure returns (bytes memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the segment count.
            let segmentsLength := mload(segments)

            if segmentsLength {
                // Derive the segment pointer range.
                let cursor := add(segments, 0x20)
                let end := add(cursor, shl(0x05, segmentsLength))

                // Copy each segment sequentially.
                for {} lt(cursor, end) { cursor := add(cursor, 0x20) } {
                    let segment := mload(cursor)
                    let length := mload(segment)

                    mcopy(ptr, add(segment, 0x20), length)
                    ptr := add(ptr, length)
                }
            }

            // Store the output length.
            mstore(result, sub(ptr, add(result, 0x20)))

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Joins a sequence of byte arrays with a delimiter between adjacent elements.
    /// @dev Returns an empty byte array if the array is empty.
    /// @param segments The array of byte arrays to join.
    /// @param delimiter The delimiter inserted between consecutive byte arrays.
    /// @return result The joined byte array.
    function join(bytes[] memory segments, bytes memory delimiter) internal pure returns (bytes memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the segment count.
            let segmentsLength := mload(segments)

            if segmentsLength {
                // Load the delimiter length and advance to its byte data.
                let delimiterLength := mload(delimiter)
                delimiter := add(delimiter, 0x20)

                // Derive the segment pointer table.
                let table := add(segments, 0x20)
                let size := shl(0x05, segmentsLength)

                // Copy each segment sequentially, inserting the delimiter between segments.
                for { let offset := 0x00 } lt(offset, size) { offset := add(offset, 0x20) } {
                    if offset {
                        mcopy(ptr, delimiter, delimiterLength)
                        ptr := add(ptr, delimiterLength)
                    }

                    let segment := mload(add(table, offset))
                    let length := mload(segment)

                    mcopy(ptr, add(segment, 0x20), length)
                    ptr := add(ptr, length)
                }
            }

            // Store the output length.
            mstore(result, sub(ptr, add(result, 0x20)))

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Splits a byte array on non-overlapping occurrences of a delimiter.
    /// @dev An empty delimiter produces one independently allocated single-byte
    ///      array per byte, and therefore an empty array for an empty byte array.
    ///      Leading, trailing, and adjacent delimiters produce empty byte arrays.
    /// @param subject The byte array to split.
    /// @param delimiter The byte sequence at which to split.
    /// @return result The resulting byte arrays.
    function split(bytes memory subject, bytes memory delimiter) internal pure returns (bytes[] memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let slot := add(result, 0x20)
            let ptr := slot

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let delimiterLength := mload(delimiter)

            // Advance to the input byte data.
            subject := add(subject, 0x20)
            delimiter := add(delimiter, 0x20)

            switch delimiterLength
            case 0x00 {
                // An empty delimiter produces one single-byte array per byte.
                mstore(result, subjectLength)

                // Advance past the outer array's element-pointer table.
                ptr := add(ptr, shl(0x05, subjectLength))

                for { let i := 0x00 } lt(i, subjectLength) { i := add(i, 0x01) } {
                    // Store the pointer to the next single-byte array in the outer array.
                    mstore(slot, ptr)

                    // Construct a one-byte array in a zero-padded word.
                    mstore(ptr, 0x01)
                    mstore(add(ptr, 0x20), and(mload(add(subject, i)), shl(0xf8, 0xff)))

                    // Advance to the next array allocation and element slot.
                    ptr := add(ptr, 0x40)
                    slot := add(slot, 0x20)
                }
            }
            default {
                // Initialize the subject range and traversal pointers.
                let cursor := subject
                let previous := subject
                let end := add(subject, subjectLength)

                // Derive the exclusive search boundary when the delimiter can fit.
                let guard := 0x00
                if iszero(gt(delimiterLength, subjectLength)) {
                    guard := add(sub(end, delimiterLength), 0x01)
                }

                // Derive the shift used to compare the significant leading bytes.
                let maskShift := mul(shl(0x03, sub(0x20, delimiterLength)), lt(delimiterLength, 0x20))

                // Delimiters of at least 32-bytes additionally require a full-length hash comparison.
                let requiresHash := iszero(lt(delimiterLength, 0x20))
                let delimiterWord := mload(delimiter)
                let delimiterHash := 0x00
                if requiresHash { delimiterHash := keccak256(delimiter, delimiterLength) }

                // First pass: count the resulting parts.
                let partCount := 0x01 // One more than the number of delimiter occurrences.

                for {} lt(cursor, guard) {} {
                    let matched := iszero(shr(maskShift, xor(mload(cursor), delimiterWord)))

                    if and(matched, requiresHash) {
                        matched := eq(keccak256(cursor, delimiterLength), delimiterHash)
                    }

                    if matched {
                        cursor := add(cursor, delimiterLength)
                        partCount := add(partCount, 0x01)
                        continue
                    }

                    cursor := add(cursor, 0x01)
                }

                // Store the output element count.
                mstore(result, partCount)

                // Advance past the outer array's element-pointer table.
                ptr := add(ptr, shl(0x05, partCount))

                // Second pass: construct every part, including the final part.
                for { cursor := subject } 0x01 {} {
                    // Default to the subject end when no further delimiter matches.
                    let boundary := end
                    let matched := 0x00

                    // Search only while a complete delimiter can begin at `cursor`.
                    // A zero `guard` disables searching when the delimiter cannot fit.
                    if lt(cursor, guard) {
                        matched := iszero(shr(maskShift, xor(mload(cursor), delimiterWord)))

                        if and(matched, requiresHash) {
                            matched := eq(keccak256(cursor, delimiterLength), delimiterHash)
                        }

                        if iszero(matched) {
                            cursor := add(cursor, 0x01)
                            continue
                        }

                        boundary := cursor
                    }

                    // Construct the byte array spanning [previous, boundary).
                    // Empty intervals preserve leading, trailing, and adjacent delimiter semantics.
                    let length := sub(boundary, previous)

                    // Store the element pointer in the outer array.
                    mstore(slot, ptr)

                    // Construct the byte array and copy its bytes.
                    mstore(ptr, length)
                    mcopy(add(ptr, 0x20), previous, length)

                    // Advance past the byte-array header and byte data.
                    ptr := add(add(ptr, 0x20), length)

                    // Zeroize the trailing memory word.
                    mstore(ptr, 0x00)

                    // Advance to the next aligned allocation and element slot.
                    ptr := and(add(ptr, 0x3f), not(0x1f))
                    slot := add(slot, 0x20)

                    // A non-match at the boundary completes the final byte array.
                    if iszero(matched) { break }

                    // Consume the delimiter and begin the next byte array after it.
                    cursor := add(cursor, delimiterLength)
                    previous := cursor
                }
            }

            // Advance the free-memory pointer past the outer array and nested byte arrays.
            mstore(0x40, ptr)
        }
    }

    /// @notice Replaces every non-overlapping occurrence of a byte sequence within a byte array.
    /// @dev Searches from left to right and does not rescan newly inserted replacement bytes.
    ///      An empty byte sequence matches at every byte boundary, including before the first
    ///      byte and after the last byte.
    /// @param subject The byte array to search within.
    /// @param needle The byte sequence to replace.
    /// @param replacement The byte sequence to substitute for each occurrence.
    /// @return result The byte array with all matching occurrences replaced.
    function replace(bytes memory subject, bytes memory needle, bytes memory replacement)
        internal
        pure
        returns (bytes memory result)
    {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)

            // Derive the source-to-destination pointer displacement.
            let displacement := sub(result, subject)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let needleLength := mload(needle)
            let replacementLength := mload(replacement)

            // Derive the subject byte range `[cursor, end)`.
            let cursor := add(subject, 0x20)
            let end := add(cursor, subjectLength)

            // Search only when the needle fits within the subject.
            if iszero(gt(needleLength, subjectLength)) {
                // Advance to the needle and replacement byte data.
                needle := add(needle, 0x20)
                replacement := add(replacement, 0x20)

                // Derive the exclusive search boundary, including the final boundary for an empty needle.
                let guard := add(sub(end, needleLength), 0x01)

                // Derive the shift used to compare the significant leading bytes.
                let maskShift := mul(shl(0x03, sub(0x20, needleLength)), lt(needleLength, 0x20))

                // Needles of at least 32-bytes additionally require a full-length hash comparison.
                let requiresHash := iszero(lt(needleLength, 0x20))
                let needleWord := mload(needle)
                let needleHash := 0x00
                if requiresHash { needleHash := keccak256(needle, needleLength) }

                // Search from left to right and consume matches without overlap.
                for {} lt(cursor, guard) {} {
                    let candidate := mload(cursor)
                    let matched := iszero(shr(maskShift, xor(candidate, needleWord)))

                    if and(matched, requiresHash) {
                        matched := eq(keccak256(cursor, needleLength), needleHash)
                    }

                    if matched {
                        // Copy the replacement at the corresponding destination.
                        mcopy(add(cursor, displacement), replacement, replacementLength)

                        // Adjust the displacement by the replacement-to-needle length difference.
                        displacement := sub(add(displacement, replacementLength), needleLength)

                        // Consume non-empty matches in full.
                        // Empty matches fall through to copy the current subject byte.
                        if needleLength {
                            cursor := add(cursor, needleLength)
                            continue
                        }
                    }

                    // Copy the current subject byte using a full-word write.
                    mstore(add(cursor, displacement), candidate)
                    cursor := add(cursor, 0x01)
                }
            }

            // Copy the remaining suffix, if any.
            if lt(cursor, end) { mcopy(add(cursor, displacement), cursor, sub(end, cursor)) }

            // Derive the logical output end.
            let ptr := add(displacement, end)

            // Store the output length.
            mstore(result, sub(ptr, add(result, 0x20)))

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Repeats a byte array a specified number of times.
    /// @dev Returns an empty byte array if the input is empty or the repetition count is zero.
    /// @param subject The byte array to repeat.
    /// @param count The number of repetitions.
    /// @return result The repeated byte array.
    function repeat(bytes memory subject, uint256 count) internal pure returns (bytes memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the subject length and advance to its byte data.
            let subjectLength := mload(subject)
            subject := add(subject, 0x20)

            if iszero(or(iszero(count), iszero(subjectLength))) {
                // Step backward by one byte.
                let stride := not(0x00) // -1 modulo 2²⁵⁶

                // Copy the subject once per iteration.
                for { let remaining := count } remaining { remaining := add(remaining, stride) } {
                    mcopy(ptr, subject, subjectLength)
                    ptr := add(ptr, subjectLength)
                }
            }

            // Store the output length.
            mstore(result, sub(ptr, add(result, 0x20)))

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

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

                // Step backward by one byte.
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

    /// @notice Determines whether a byte array begins with a byte sequence.
    /// @dev An empty byte sequence always matches the beginning of a byte array.
    /// @param subject The byte array to inspect.
    /// @param needle The byte sequence to compare against the beginning of the byte array.
    /// @return result Whether the byte array begins with the byte sequence.
    function startsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            if iszero(gt(needleLength, subjectLength)) {
                result := eq(keccak256(add(subject, 0x20), needleLength), keccak256(add(needle, 0x20), needleLength))
            }
        }
    }

    /// @notice Determines whether a byte array ends with a byte sequence.
    /// @dev An empty byte sequence always matches the end of a byte array.
    /// @param subject The byte array to inspect.
    /// @param needle The byte sequence to compare against the end of the byte array.
    /// @return result Whether the byte array ends with the byte sequence.
    function endsWith(bytes memory subject, bytes memory needle) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            if iszero(gt(needleLength, subjectLength)) {
                // Derive the start of the candidate suffix.
                let offset := add(add(subject, 0x20), sub(subjectLength, needleLength))
                result := eq(keccak256(offset, needleLength), keccak256(add(needle, 0x20), needleLength))
            }
        }
    }

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
