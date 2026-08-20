// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title StringUtils
/// @author fomoweth
/// @notice Utilities for converting, formatting, comparing, inspecting, searching, constructing, and slicing strings.
library StringUtils {
    /// @dev Thrown when a value cannot be represented within the requested hexadecimal byte length.
    error InsufficientHexStringLength();

    /// @dev Thrown when a byte is not supported for case formatting.
    error InvalidFormatChar();

    /// @dev Thrown when an unsupported case convention is requested.
    error InvalidCaseType();

    /// @dev Supported string case conventions for {formatCase}.
    enum CaseType {
        Camel,
        Pascal,
        Constant,
        Snake,
        Kebab
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONVERSION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Converts an unsigned integer to its ASCII decimal string representation.
    /// @param value The unsigned integer to convert.
    /// @return result The decimal string representation.
    function toString(uint256 value) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Cache the end of the fixed output region.
            result := add(mload(0x40), 0x80)
            let ptr := result

            // Step backward by one byte.
            let stride := not(0x00) // -1 modulo 2²⁵⁶

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, add(ptr, 0x20))

            // Encode each significant decimal digit from right to left.
            // Emit at least one digit, ensuring zero is represented as `0`.
            for { let remaining := value } 0x01 {} {
                ptr := add(ptr, stride)
                mstore8(ptr, add(0x30, mod(remaining, 0x0a)))

                remaining := div(remaining, 0x0a)
                if iszero(remaining) { break }
            }

            // Derive the output length.
            let length := sub(result, ptr)

            // Position the string header before the digits.
            result := sub(ptr, 0x20)

            // Store the output length.
            mstore(result, length)
        }
    }

    /// @notice Converts a signed integer to its ASCII decimal string representation, prefixed with `-` when negative.
    /// @param value The signed integer to convert.
    /// @return result The decimal string representation.
    function toString(int256 value) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Cache the end of the fixed output region.
            result := add(mload(0x40), 0x80)
            let ptr := result
            let remaining := value

            // Step backward by one byte.
            let stride := not(0x00) // -1 modulo 2²⁵⁶

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, add(ptr, 0x20))

            // Convert negative values to their unsigned magnitude.
            if slt(value, 0x00) { remaining := add(not(value), 0x01) }

            // Encode each significant decimal digit from right to left.
            // Emit at least one digit, ensuring zero is represented as `0`.
            for {} 0x01 {} {
                ptr := add(ptr, stride)
                mstore8(ptr, add(0x30, mod(remaining, 0x0a)))

                remaining := div(remaining, 0x0a)
                if iszero(remaining) { break }
            }

            // Prepend a minus sign for negative values.
            if slt(value, 0x00) {
                ptr := add(ptr, stride)
                mstore8(ptr, 0x2d) // `-`
            }

            // Derive the output length.
            let length := sub(result, ptr)

            // Position the string header before the optional sign and digits.
            result := sub(ptr, 0x20)

            // Store the output length.
            mstore(result, length)
        }
    }

    /// @notice Converts an unsigned integer to a fixed-width ASCII hexadecimal string representation.
    /// @dev Encodes exactly two lowercase hexadecimal digits per requested byte, left-padding with zero digits.
    ///      Reverts with {InsufficientHexStringLength} if the value does not fit within the requested width.
    /// @param value The unsigned integer to convert.
    /// @param byteLength The fixed number of bytes to encode.
    /// @param prefixed Whether to prepend the `0x` prefix.
    /// @return result The hexadecimal string representation.
    function toHexString(uint256 value, uint256 byteLength, bool prefixed)
        internal
        pure
        returns (string memory result)
    {
        assembly ("memory-safe") {
            // Cache the end of the fixed output region.
            result := add(mload(0x40), and(add(shl(0x01, byteLength), 0x42), not(0x1f)))
            let ptr := result
            let guard := sub(ptr, shl(0x01, byteLength))
            let remaining := value

            // Step backward by two bytes.
            let stride := not(0x01) // -2 modulo 2²⁵⁶

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, add(ptr, 0x20))

            // Store the hexadecimal lookup table (`0123456789abcdef`) in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // Encode exactly `byteLength` bytes from right to left as two lowercase hexadecimal digits each.
            for {} xor(ptr, guard) {} {
                ptr := add(ptr, stride)
                mstore8(add(ptr, 0x01), mload(and(remaining, 0x0f)))
                mstore8(ptr, mload(and(shr(0x04, remaining), 0x0f)))
                remaining := shr(0x08, remaining)
            }

            // A non-zero remainder indicates insufficient width.
            if remaining {
                mstore(0x00, 0xd4a3f1bc) // InsufficientHexStringLength()
                revert(0x1c, 0x04)
            }

            // Derive the optional prefix length and output length.
            let prefixLength := shl(0x01, iszero(iszero(prefixed)))
            let length := add(sub(result, ptr), prefixLength)

            // Position the string header before the optional prefix and digits.
            result := sub(ptr, add(prefixLength, 0x20))

            // Store the optional `0x` prefix, if requested.
            if prefixLength { mstore(add(result, 0x02), 0x3078) }

            // Store the output length.
            mstore(result, length)
        }
    }

    /// @dev Variant of {toHexString-uint256-uint256-bool} with `prefixed` set to `true`.
    function toHexString(uint256 value, uint256 byteLength) internal pure returns (string memory result) {
        return toHexString(value, byteLength, true);
    }

    /// @dev Variant of {toHexString-uint256-uint256-bool} with `prefixed` set to `false`.
    function toHexStringNoPrefix(uint256 value, uint256 byteLength) internal pure returns (string memory result) {
        return toHexString(value, byteLength, false);
    }

    /// @notice Converts an unsigned integer to a minimal-width ASCII hexadecimal string representation.
    /// @dev Encodes two lowercase hexadecimal digits per significant byte, so the digit count is always
    ///      even and zero is encoded as `00` rather than `0`.
    /// @param value The unsigned integer to convert.
    /// @param prefixed Whether to prepend the `0x` prefix.
    /// @return result The hexadecimal string representation.
    function toHexString(uint256 value, bool prefixed) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Cache the end of the fixed output region.
            result := add(mload(0x40), 0x80)
            let ptr := result

            // Step backward by two bytes.
            let stride := not(0x01) // -2 modulo 2²⁵⁶

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, add(ptr, 0x20))

            // Store the hexadecimal lookup table (`0123456789abcdef`) in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // Encode each significant byte from right to left as two lowercase hexadecimal digits.
            // Emit at least one byte, ensuring zero is represented as `00`.
            for { let remaining := value } 0x01 {} {
                ptr := add(ptr, stride)
                mstore8(add(ptr, 0x01), mload(and(remaining, 0x0f)))
                mstore8(ptr, mload(and(shr(0x04, remaining), 0x0f)))

                remaining := shr(0x08, remaining)
                if iszero(remaining) { break }
            }

            // Derive the optional prefix length and output length.
            let prefixLength := shl(0x01, iszero(iszero(prefixed)))
            let length := add(sub(result, ptr), prefixLength)

            // Position the string header before the optional prefix and digits.
            result := sub(ptr, add(prefixLength, 0x20))

            // Store the optional `0x` prefix, if requested.
            if prefixLength { mstore(add(result, 0x02), 0x3078) }

            // Store the output length.
            mstore(result, length)
        }
    }

    /// @dev Variant of {toHexString-uint256-bool} with `prefixed` set to `true`.
    function toHexString(uint256 value) internal pure returns (string memory result) {
        return toHexString(value, true);
    }

    /// @dev Variant of {toHexString-uint256-bool} with `prefixed` set to `false`.
    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory result) {
        return toHexString(value, false);
    }

    /// @notice Converts an address to its ASCII hexadecimal string representation.
    /// @dev Encodes exactly 40 hexadecimal digits representing 20 bytes, and optionally
    ///      applies the https://eips.ethereum.org/EIPS/eip-55[EIP-55] checksum casing.
    /// @param value The address to convert.
    /// @param prefixed Whether to prepend the `0x` prefix.
    /// @param checksummed Whether to apply the EIP-55 checksum casing.
    /// @return result The hexadecimal string representation.
    function toHexString(address value, bool prefixed, bool checksummed) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Cache the end of the fixed output region.
            let ptr := add(mload(0x40), 0x60)
            let guard := sub(ptr, 0x28)

            // Step backward by two bytes.
            let stride := not(0x01) // -2 modulo 2²⁵⁶

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, add(ptr, 0x20))

            // Store the hexadecimal lookup table (`0123456789abcdef`) in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // Encode all 20 address bytes from right to left as two lowercase hexadecimal digits each.
            for { let remaining := value } xor(ptr, guard) { remaining := shr(0x08, remaining) } {
                ptr := add(ptr, stride)
                mstore8(add(ptr, 0x01), mload(and(remaining, 0x0f)))
                mstore8(ptr, mload(and(shr(0x04, remaining), 0x0f)))
            }

            // Apply EIP-55 checksum casing using the hash of the lowercase hexadecimal digits, if requested.
            if checksummed {
                // ASCII case offset used to convert lowercase letters to uppercase.
                let caseDelta := not(0x1f) // -32 modulo 2²⁵⁶

                let hash := keccak256(ptr, 0x28)

                for { let i := 0x00 } lt(i, 0x28) { i := add(i, 0x01) } {
                    let char := byte(0x00, mload(add(ptr, i)))

                    // Only `a` through `f` have a distinct uppercase form.
                    if iszero(lt(char, 0x61)) {
                        // Even indices select the high hash nibble; odd indices select the low nibble.
                        let nibble := and(shr(mul(sub(0x01, and(i, 0x01)), 0x04), byte(shr(0x01, i), hash)), 0x0f)
                        if iszero(lt(nibble, 0x08)) { mstore8(add(ptr, i), add(char, caseDelta)) }
                    }
                }
            }

            // Derive the optional prefix length.
            let prefixLength := shl(0x01, iszero(iszero(prefixed)))

            // Position the string header before the optional prefix and 40 hexadecimal digits.
            result := sub(ptr, add(prefixLength, 0x20))

            // Store the optional `0x` prefix, if requested.
            if prefixLength { mstore(add(result, 0x02), 0x3078) }

            // Store the output length.
            mstore(result, add(prefixLength, 0x28))
        }
    }

    /// @dev Variant of {toHexString-address-bool-bool} with `prefixed` set to `true` and `checksummed` set to `false`.
    function toHexString(address value) internal pure returns (string memory result) {
        return toHexString(value, true, false);
    }

    /// @dev Variant of {toHexString-address-bool-bool} with both `prefixed` and `checksummed` set to `true`.
    function toHexStringChecksummed(address value) internal pure returns (string memory result) {
        return toHexString(value, true, true);
    }

    /// @dev Variant of {toHexString-address-bool-bool} with both `prefixed` and `checksummed` set to `false`.
    function toHexStringNoPrefix(address value) internal pure returns (string memory result) {
        return toHexString(value, false, false);
    }

    /// @notice Converts a byte array to its ASCII hexadecimal string representation.
    /// @dev Encodes exactly two lowercase hexadecimal digits per byte.
    /// @param buffer The byte array to convert.
    /// @param prefixed Whether to prepend the `0x` prefix.
    /// @return result The hexadecimal string representation.
    function toHexString(bytes memory buffer, bool prefixed) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Derive the buffer byte range.
            let cursor := add(buffer, 0x20)
            let bufferLength := mload(buffer)
            let end := add(cursor, bufferLength)

            // Derive the optional prefix length.
            let prefixLength := shl(0x01, iszero(iszero(prefixed)))

            // Store the hexadecimal lookup table (`0123456789abcdef`) in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // Write the optional prefix and advance to the hexadecimal digit region.
            if prefixLength {
                mstore8(ptr, 0x30) // `0`
                mstore8(add(ptr, 0x01), 0x78) // `x`
                ptr := add(ptr, prefixLength)
            }

            // Encode each input byte from left to right as two lowercase hexadecimal digits.
            for {} lt(cursor, end) {} {
                let char := byte(0x00, mload(cursor))
                mstore8(ptr, mload(shr(0x04, char)))
                mstore8(add(ptr, 0x01), mload(and(0x0f, char)))

                cursor := add(cursor, 0x01)
                ptr := add(ptr, 0x02)
            }

            // Store the output length, including the optional prefix.
            mstore(result, add(shl(0x01, bufferLength), prefixLength))

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @dev Variant of {toHexString-bytes-bool} with `prefixed` set to `true`.
    function toHexString(bytes memory buffer) internal pure returns (string memory result) {
        return toHexString(buffer, true);
    }

    /// @dev Variant of {toHexString-bytes-bool} with `prefixed` set to `false`.
    function toHexStringNoPrefix(bytes memory buffer) internal pure returns (string memory result) {
        return toHexString(buffer, false);
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            FORMATTING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Formats a string according to the specified case convention.
    /// @dev Supports camelCase, PascalCase, CONSTANT_CASE, snake_case, and kebab-case.
    ///      Accepts printable ASCII characters. Spaces, hyphens, and underscores are normalized
    ///      as separators, while other punctuation is preserved as a word boundary.
    ///      Detects word boundaries across separators, punctuation, case transitions, acronym
    ///      boundaries, and numeric fragments. Reverts with {InvalidFormatChar} for unsupported
    ///      bytes and {InvalidCaseType} for an invalid case convention.
    /// @param subject The string to format.
    /// @param caseType The target case convention.
    /// @return result The case-formatted string.
    function formatCase(string memory subject, CaseType caseType) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Return whether the byte is an ASCII letter or decimal digit.
            function isAlphanumeric(char) -> flag {
                flag := or(isNumeric(char), or(isUpperCase(char), isLowerCase(char)))
            }

            // Return whether the byte is an ASCII decimal digit (`0` through `9`).
            function isNumeric(char) -> flag {
                flag := lt(sub(char, 0x30), 0x0a)
            }

            // Return whether the byte is an uppercase ASCII letter (`A` through `Z`).
            function isUpperCase(char) -> flag {
                flag := lt(sub(char, 0x41), 0x1a)
            }

            // Return whether the byte is a lowercase ASCII letter (`a` through `z`).
            function isLowerCase(char) -> flag {
                flag := lt(sub(char, 0x61), 0x1a)
            }

            // Return whether the byte is a printable ASCII character (` ` through `~`).
            function isPrintable(char) -> flag {
                flag := lt(sub(char, 0x20), 0x5f)
            }

            // Return whether the byte is a recognized word separator:
            // space (` `), hyphen (`-`), or underscore (`_`).
            function isSeparator(char) -> flag {
                flag := or(eq(char, 0x20), or(eq(char, 0x2d), eq(char, 0x5f)))
            }

            // Read and validate one input byte.
            function read(ptr) -> char {
                char := byte(0x00, mload(ptr))
                if iszero(isPrintable(char)) {
                    mstore(0x00, 0xd6e4b4c1) // InvalidFormatChar()
                    revert(0x1c, 0x04)
                }
            }

            // Reject values outside the `CaseType` enum.
            if gt(caseType, 0x04) {
                mstore(0x00, 0x0b232f0e) // InvalidCaseType()
                revert(0x1c, 0x04)
            }

            // Step backward by one byte.
            let stride := not(0x00) // -1 modulo 2²⁵⁶

            // ASCII case offset used to convert lowercase letters to uppercase.
            let caseDelta := not(0x1f) // -32 modulo 2²⁵⁶

            // Load the subject byte range.
            let subjectLength := mload(subject)
            let src := add(subject, 0x20)

            // Remove trailing recognized separators while validating each inspected byte.
            for {} subjectLength {} {
                if iszero(isSeparator(read(add(src, add(subjectLength, stride))))) { break }
                subjectLength := add(subjectLength, stride)
            }

            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let dst := add(result, 0x20)

            // Track the number of emitted output bytes.
            let length := 0x00

            if subjectLength {
                // Classify the target case convention.
                // 0: Camel, 1: Pascal, 2: Constant, 3: Snake, 4: Kebab.
                let isCamel := iszero(caseType)
                let isPascal := eq(caseType, 0x01)
                let isConstant := eq(caseType, 0x02)
                let isSnake := eq(caseType, 0x03)
                let isKebab := eq(caseType, 0x04)

                // Constant/Snake/Kebab cases use a normalized separator.
                let usesSeparator := or(or(isConstant, isSnake), isKebab)

                // Select the normalized separator for separated case formats.
                let separator := 0x00
                if or(isConstant, isSnake) {
                    separator := 0x5f // `_`
                }
                if isKebab {
                    separator := 0x2d // `-`
                }

                // Initialize Pascal case to capitalize the first alphabetic byte.
                let capitalizeNext := isPascal

                // Scan the input from left to right.
                for { let i := 0x00 } lt(i, subjectLength) { i := add(i, 0x01) } {
                    // Read the current source byte.
                    let char := read(add(src, i))

                    // Read the next source byte when available.
                    let next := 0x00
                    if lt(add(i, 0x01), subjectLength) { next := read(add(src, add(i, 0x01))) }

                    // Read the previously emitted output byte when available.
                    let prev := 0x00
                    if length { prev := byte(0x00, mload(add(dst, add(length, stride)))) }

                    // Handle recognized separators and preserved punctuation.
                    if iszero(isAlphanumeric(char)) {
                        switch usesSeparator
                        case 0x01 {
                            switch isSeparator(char)
                            case 0x01 {
                                if length {
                                    // Find the next non-separator source byte.
                                    for { let o := add(i, 0x01) } lt(o, subjectLength) { o := add(o, 0x01) } {
                                        next := read(add(src, o))
                                        if iszero(isSeparator(next)) { break }
                                    }

                                    // Emit a normalized separator only after alphanumeric content
                                    // and suppress separator runs preceding numeric fragments.
                                    if and(isAlphanumeric(prev), iszero(isNumeric(next))) {
                                        mstore8(add(dst, length), separator)
                                        length := add(length, 0x01)
                                    }
                                }
                            }
                            default {
                                // Preserve printable punctuation as a word boundary.
                                if eq(prev, separator) { length := add(length, stride) }

                                mstore8(add(dst, length), char)
                                length := add(length, 0x01)
                            }
                        }
                        default {
                            // Preserve printable punctuation and remove recognized separators.
                            if iszero(isSeparator(char)) {
                                mstore8(add(dst, length), char)
                                length := add(length, 0x01)
                            }

                            // Punctuation always establishes a word boundary; recognized
                            // separators do so only after emitted content.
                            if or(iszero(isSeparator(char)), iszero(iszero(length))) {
                                capitalizeNext := 0x01
                            }
                        }

                        continue
                    }

                    // Read the previous source byte when available.
                    let prevSource := 0x00
                    if i { prevSource := read(add(src, add(i, stride))) }

                    switch usesSeparator
                    case 0x01 {
                        // Detect implicit boundaries only between adjacent source alphanumerics.
                        if isAlphanumeric(prevSource) {
                            // An alphabetic fragment following a numeric fragment begins a new word.
                            let insertBoundary := and(isNumeric(prevSource), iszero(isNumeric(char)))

                            if isUpperCase(char) {
                                // A lowercase-to-uppercase transition begins a new word.
                                if isLowerCase(prevSource) {
                                    insertBoundary := 0x01
                                }

                                // Insert a boundary before an acronym-ending uppercase byte
                                // followed by lowercase text.
                                if and(isUpperCase(prevSource), isLowerCase(next)) {
                                    insertBoundary := 0x01
                                }
                            }

                            if and(insertBoundary, iszero(eq(prev, separator))) {
                                mstore8(add(dst, length), separator)
                                length := add(length, 0x01)
                            }
                        }

                        // Constant case converts lowercase ASCII letters to uppercase.
                        if and(isConstant, isLowerCase(char)) {
                            char := add(char, caseDelta)
                        }

                        // Snake and Kebab cases convert uppercase ASCII letters to lowercase.
                        if and(iszero(isConstant), isUpperCase(char)) {
                            char := add(char, 0x20)
                        }
                    }
                    default {
                        switch or(isNumeric(prev), capitalizeNext)
                        case 0x01 {
                            // Capitalize the first alphabetic byte following a separator,
                            // punctuation boundary, or numeric fragment.
                            if isLowerCase(char) { char := add(char, caseDelta) }

                            // Digits do not consume pending capitalization.
                            if iszero(isNumeric(char)) { capitalizeNext := 0x00 }
                        }
                        default {
                            // Normalize uppercase bytes within Camel and Pascal case.
                            if isUpperCase(char) {
                                // Lowercase the initial Camel byte and interior acronym bytes.
                                if or(
                                    and(isCamel, iszero(length)),
                                    and(isUpperCase(prevSource), iszero(isLowerCase(next)))
                                ) {
                                    char := add(char, 0x20)
                                }
                            }
                        }
                    }

                    // Emit the normalized alphanumeric byte.
                    mstore8(add(dst, length), char)
                    length := add(length, 0x01)
                }
            }

            // Store the output length.
            mstore(result, length)

            // Derive the logical output end.
            let ptr := add(dst, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Converts all ASCII letters in a string to lowercase.
    /// @dev Only characters in the ASCII range `A` through `Z` are converted.
    ///      All other bytes, including non-ASCII bytes, are left unchanged.
    /// @param subject The string to convert.
    /// @return result The lowercased string.
    function toLowerCase(string memory subject) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)

            // Derive the output byte range and displacement to the corresponding input bytes.
            let ptr := add(result, 0x20)
            let displacement := sub(add(subject, 0x20), ptr)
            let length := mload(subject)

            // Convert each uppercase ASCII character by setting bit 5.
            for { let end := add(ptr, length) } lt(ptr, end) { ptr := add(ptr, 0x01) } {
                let char := byte(0x00, mload(add(ptr, displacement)))
                mstore8(ptr, add(char, shl(0x05, lt(sub(char, 0x41), 0x1a))))
            }

            // Store the output length.
            mstore(result, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Converts all ASCII letters in a string to uppercase.
    /// @dev Only characters in the ASCII range `a` through `z` are converted.
    ///      All other bytes, including non-ASCII bytes, are left unchanged.
    /// @param subject The string to convert.
    /// @return result The uppercased string.
    function toUpperCase(string memory subject) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)

            // Derive the output byte range and displacement to the corresponding input bytes.
            let ptr := add(result, 0x20)
            let displacement := sub(add(subject, 0x20), ptr)
            let length := mload(subject)

            // Convert each lowercase ASCII character by clearing bit 5.
            for { let end := add(ptr, length) } lt(ptr, end) { ptr := add(ptr, 0x01) } {
                let char := byte(0x00, mload(add(ptr, displacement)))
                mstore8(ptr, sub(char, shl(0x05, lt(sub(char, 0x61), 0x1a))))
            }

            // Store the output length.
            mstore(result, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            CONSTRUCTION
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Concatenates a sequence of strings.
    /// @dev Returns an empty string if the array is empty.
    /// @param segments The array of strings to concatenate.
    /// @return result The concatenated string.
    function concat(string[] memory segments) internal pure returns (string memory result) {
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

    /// @notice Joins a sequence of strings with a delimiter between adjacent elements.
    /// @dev Returns an empty string if the array is empty.
    /// @param segments The array of strings to join.
    /// @param delimiter The delimiter inserted between consecutive strings.
    /// @return result The joined string.
    function join(string[] memory segments, string memory delimiter) internal pure returns (string memory result) {
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

    /// @notice Splits a string on non-overlapping occurrences of a delimiter.
    /// @dev An empty delimiter produces one independently allocated single-byte
    ///      string per byte, and therefore an empty array for an empty string.
    ///      Leading, trailing, and adjacent delimiters produce empty strings.
    /// @param subject The string to split.
    /// @param delimiter The substring at which to split.
    /// @return result The resulting substrings.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
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
                // An empty delimiter produces one single-byte string per byte.
                mstore(result, subjectLength)

                // Advance past the outer array's element-pointer table.
                ptr := add(ptr, shl(0x05, subjectLength))

                for { let i := 0x00 } lt(i, subjectLength) { i := add(i, 0x01) } {
                    // Store the pointer to the next single-byte string in the outer array.
                    mstore(slot, ptr)

                    // Construct a one-byte string in a zero-padded word.
                    mstore(ptr, 0x01)
                    mstore(add(ptr, 0x20), and(mload(add(subject, i)), shl(0xf8, 0xff)))

                    // Advance to the next string allocation and element slot.
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

                // Delimiters of at least 32 bytes additionally require a full-length hash comparison.
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
                        partCount := add(partCount, 0x01)
                        cursor := add(cursor, delimiterLength)
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

                    // Construct the substring spanning [previous, boundary).
                    // Empty intervals preserve leading, trailing, and adjacent delimiter semantics.
                    let length := sub(boundary, previous)

                    // Store the element pointer in the outer array.
                    mstore(slot, ptr)

                    // Construct the string object and copy its bytes.
                    mstore(ptr, length)
                    mcopy(add(ptr, 0x20), previous, length)

                    // Advance past the string header and byte data.
                    ptr := add(add(ptr, 0x20), length)

                    // Zeroize the trailing memory word.
                    mstore(ptr, 0x00)

                    // Advance to the next aligned allocation and element slot.
                    ptr := and(add(ptr, 0x3f), not(0x1f))
                    slot := add(slot, 0x20)

                    // A non-match at the boundary completes the final substring.
                    if iszero(matched) { break }

                    // Consume the delimiter and begin the next substring after it.
                    cursor := add(cursor, delimiterLength)
                    previous := cursor
                }
            }

            // Advance the free-memory pointer past the outer array and nested strings.
            mstore(0x40, ptr)
        }
    }

    /// @notice Replaces every non-overlapping occurrence of a substring within a string.
    /// @dev Searches from left to right and does not rescan newly inserted replacement bytes.
    ///      An empty substring matches at every byte boundary, including before the first
    ///      byte and after the last byte.
    /// @param subject The string to search within.
    /// @param needle The substring to replace, interpreted as a byte sequence.
    /// @param replacement The substring to substitute for each occurrence.
    /// @return result The string with all matching occurrences replaced.
    function replace(string memory subject, string memory needle, string memory replacement)
        internal
        pure
        returns (string memory result)
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

                // Needles of at least 32 bytes additionally require a full-length hash comparison.
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

    /// @notice Repeats a string a specified number of times.
    /// @dev Returns an empty string if the input is empty or the repetition count is zero.
    /// @param subject The string to repeat.
    /// @param count The number of repetitions.
    /// @return result The repeated string.
    function repeat(string memory subject, uint256 count) internal pure returns (string memory result) {
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

    /// @notice Left-pads a string to at least a specified byte length by cyclically repeating a specified
    ///         padding string, truncating the final repetition as needed.
    /// @dev Returns an unchanged copy if no padding is required or the padding string is empty.
    /// @param subject The string to pad.
    /// @param fill The string cyclically repeated as padding.
    /// @param length The minimum byte length of the resulting string.
    /// @return result The left-padded string.
    function padStart(string memory subject, string memory fill, uint256 length)
        internal
        pure
        returns (string memory result)
    {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let fillLength := mload(fill)

            // Preserve the original byte length if no padding is required or the padding string is empty.
            if or(lt(length, subjectLength), iszero(fillLength)) { length := subjectLength }

            // The subject begins immediately after the padding region.
            let cursor := ptr
            let end := add(ptr, sub(length, subjectLength))
            mcopy(end, add(subject, 0x20), subjectLength)

            // Fill the padding region with cyclic repetitions of the fill string.
            for { fill := add(fill, 0x20) } lt(cursor, end) {} {
                let size := fillLength
                let remaining := sub(end, cursor)
                if gt(size, remaining) { size := remaining }

                mcopy(cursor, fill, size)
                cursor := add(cursor, size)
            }

            // Store the output length.
            mstore(result, length)

            // Derive the logical output end.
            ptr := add(ptr, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @notice Right-pads a string to at least a specified byte length by cyclically repeating a specified
    ///         padding string, truncating the final repetition as needed.
    /// @dev Returns an unchanged copy if no padding is required or the padding string is empty.
    /// @param subject The string to pad.
    /// @param fill The string cyclically repeated as padding.
    /// @param length The minimum byte length of the resulting string.
    /// @return result The right-padded string.
    function padEnd(string memory subject, string memory fill, uint256 length)
        internal
        pure
        returns (string memory result)
    {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let fillLength := mload(fill)

            // Preserve the original byte length if no padding is required or the padding string is empty.
            if or(iszero(gt(length, subjectLength)), iszero(fillLength)) { length := subjectLength }

            // The padding region begins immediately after the copied subject.
            let cursor := add(ptr, subjectLength)
            let end := add(ptr, length)
            mcopy(ptr, add(subject, 0x20), subjectLength)

            // Fill the padding region with cyclic repetitions of the fill string.
            for { fill := add(fill, 0x20) } lt(cursor, end) {} {
                let size := fillLength
                let remaining := sub(end, cursor)
                if gt(size, remaining) { size := remaining }

                mcopy(cursor, fill, size)
                cursor := add(cursor, size)
            }

            // Store the output length.
            mstore(result, length)

            // Zeroize the trailing memory word.
            mstore(end, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(end, 0x3f), not(0x1f)))
        }
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SLICING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Extracts a substring from a specified byte offset with a maximum byte length.
    /// @dev Clamps the requested length to the remaining bytes of the string.
    ///      Returns an empty string if the starting offset is greater than or equal to the byte length.
    /// @param subject The string to slice.
    /// @param offset The zero-based byte offset at which the substring begins.
    /// @param length The maximum number of bytes to include.
    /// @return result The extracted substring.
    function slice(string memory subject, uint256 offset, uint256 length) internal pure returns (string memory result) {
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

    /// @dev Variant of {slice-string-uint256-uint256} with `length` set to `type(uint256).max`.
    function slice(string memory subject, uint256 offset) internal pure returns (string memory result) {
        return slice(subject, offset, type(uint256).max);
    }

    /// @notice Shortens a string in place to at most a specified number of bytes.
    /// @dev Does not allocate memory. The returned string aliases the subject, so truncation is observable through
    ///      other references to the same string. Use {slice-string-uint256-uint256} to obtain an independent copy.
    ///      Leaves the string unchanged if the requested length is greater than or equal to its byte length.
    /// @param subject The string to truncate.
    /// @param length The maximum number of bytes to retain.
    /// @return result The truncated string.
    function truncate(string memory subject, uint256 length) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Reuse the original allocation by aliasing the subject.
            result := subject

            // Shrink the logical length only when truncation is required.
            if lt(length, mload(result)) { mstore(result, length) }
        }
    }

    /// @notice Trims ASCII whitespace from the selected ends of a string.
    /// @dev Returns an unchanged copy if no trimming is required.
    ///      Recognized whitespace consists of horizontal tab (`\t`), line feed (`\n`),
    ///      vertical tab (`\v`), form feed (`\f`), carriage return (`\r`), and space (` `).
    ///      All other bytes, including non-ASCII whitespace, are preserved unchanged.
    /// @param subject The string to trim.
    /// @param leading Whether to trim leading whitespace.
    /// @param trailing Whether to trim trailing whitespace.
    /// @return result The trimmed string.
    function trim(string memory subject, bool leading, bool trailing) internal pure returns (string memory result) {
        assembly ("memory-safe") {
            // Return whether the byte is recognized whitespace (`0x09`–`0x0d` or `0x20`).
            function isWhitespace(ptr) -> flag {
                let char := byte(0x00, mload(ptr))
                flag := or(lt(sub(char, 0x09), 0x05), eq(char, 0x20))
            }

            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Derive the subject byte range `[cursor, end)`.
            let cursor := add(subject, 0x20)
            let end := add(cursor, mload(subject))

            // Advance to the first retained byte, if requested.
            if leading {
                for {} lt(cursor, end) { cursor := add(cursor, 0x01) } {
                    if iszero(isWhitespace(cursor)) { break }
                }
            }

            // Move `end` backward past trailing whitespace, if requested.
            if trailing {
                // Step backward by one byte.
                let stride := not(0x00) // -1 modulo 2²⁵⁶

                for {} lt(cursor, end) { end := add(end, stride) } {
                    if iszero(isWhitespace(add(end, stride))) { break }
                }
            }

            // Store the output length and copy the retained byte range.
            let length := sub(end, cursor)
            mstore(result, length)
            mcopy(ptr, cursor, length)

            // Derive the logical output end.
            ptr := add(ptr, length)

            // Zeroize the trailing memory word.
            mstore(ptr, 0x00)

            // Advance the free-memory pointer.
            mstore(0x40, and(add(ptr, 0x3f), not(0x1f)))
        }
    }

    /// @dev Variant of {trim-string-bool-bool} with both `leading` and `trailing` set to `true`.
    function trim(string memory subject) internal pure returns (string memory result) {
        return trim(subject, true, true);
    }

    /// @dev Variant of {trim-string-bool-bool} with `leading` set to `true` and `trailing` set to `false`.
    function trimStart(string memory subject) internal pure returns (string memory result) {
        return trim(subject, true, false);
    }

    /// @dev Variant of {trim-string-bool-bool} with `leading` set to `false` and `trailing` set to `true`.
    function trimEnd(string memory subject) internal pure returns (string memory result) {
        return trim(subject, false, true);
    }

    /*///////////////////////////////////////////////////////////////////////////////////////////////////////
                                            SEARCHING
    ///////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Finds the byte index of the first occurrence of a substring within a string, searching forward
    ///         from a specified byte offset.
    /// @dev An empty substring matches at the lesser of the starting offset and the string's byte length.
    /// @param subject The string to search within.
    /// @param needle The substring to search for.
    /// @param offset The zero-based byte offset from which to begin searching.
    /// @return result The byte index of the first match, or `type(uint256).max` if no match exists.
    function indexOf(string memory subject, string memory needle, uint256 offset)
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

                    // Needles of at least 32 bytes additionally require a full-length hash comparison.
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

    /// @dev Variant of {indexOf-string-string-uint256} with `offset` set to `0`.
    function indexOf(string memory subject, string memory needle) internal pure returns (uint256 result) {
        return indexOf(subject, needle, 0);
    }

    /// @notice Finds the byte index of the last occurrence of a substring within a string, searching backward
    ///         from a specified byte offset.
    /// @dev An empty substring matches at the lesser of the starting offset and the string's byte length.
    /// @param subject The string to search within.
    /// @param needle The substring to search for.
    /// @param offset The zero-based byte offset from which to begin searching backward.
    /// @return result The byte index of the last match, or `type(uint256).max` if no match exists.
    function lastIndexOf(string memory subject, string memory needle, uint256 offset)
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

                // Needles of at least 32 bytes additionally require a full-length hash comparison.
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

    /// @dev Variant of {lastIndexOf-string-string-uint256} with `offset` set to `type(uint256).max`.
    function lastIndexOf(string memory subject, string memory needle) internal pure returns (uint256 result) {
        return lastIndexOf(subject, needle, type(uint256).max);
    }

    /// @notice Finds the byte indices of every non-overlapping occurrence of a substring within a string.
    /// @dev An empty substring matches at every byte boundary, including the boundary after the final byte.
    ///      Returns an empty array if no match exists.
    /// @param subject The string to search within.
    /// @param needle The substring to search for.
    /// @return result The byte indices of all matches in ascending order.
    function indicesOf(string memory subject, string memory needle) internal pure returns (uint256[] memory result) {
        assembly ("memory-safe") {
            // Construct the output directly at the current free-memory pointer.
            result := mload(0x40)
            let ptr := add(result, 0x20)

            // Load the input byte lengths.
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            switch needleLength
            case 0x00 {
                // An empty substring matches at every byte boundary.
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

                    // Needles of at least 32 bytes additionally require a full-length hash comparison.
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

    /// @notice Determines whether a string contains a substring at or after a specified byte offset.
    /// @dev An empty substring matches if the starting offset is less than or equal to the string's byte length.
    /// @param subject The string to search within.
    /// @param needle The substring to search for.
    /// @param offset The zero-based byte offset from which to begin searching.
    /// @return result Whether a match exists at or after the specified offset.
    function contains(string memory subject, string memory needle, uint256 offset) internal pure returns (bool result) {
        return indexOf(subject, needle, offset) != type(uint256).max;
    }

    /// @dev Variant of {contains-string-string-uint256} with `offset` set to `0`.
    function contains(string memory subject, string memory needle) internal pure returns (bool result) {
        return contains(subject, needle, 0);
    }

    /// @notice Determines whether a string begins with a substring.
    /// @dev An empty substring always matches the beginning of a string.
    /// @param subject The string to inspect.
    /// @param needle The substring to compare against the beginning of the string.
    /// @return result Whether the string begins with the substring.
    function startsWith(string memory subject, string memory needle) internal pure returns (bool result) {
        assembly ("memory-safe") {
            let subjectLength := mload(subject)
            let needleLength := mload(needle)

            if iszero(gt(needleLength, subjectLength)) {
                result := eq(keccak256(add(subject, 0x20), needleLength), keccak256(add(needle, 0x20), needleLength))
            }
        }
    }

    /// @notice Determines whether a string ends with a substring.
    /// @dev An empty substring always matches the end of a string.
    /// @param subject The string to inspect.
    /// @param needle The substring to compare against the end of the string.
    /// @return result Whether the string ends with the substring.
    function endsWith(string memory subject, string memory needle) internal pure returns (bool result) {
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
