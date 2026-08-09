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

    function eq(string memory x, string memory y) internal pure returns (bool result) {}

    function cmp(string memory x, string memory y) internal pure returns (int256 result) {}
}
