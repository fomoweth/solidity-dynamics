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

    function eq(bytes memory x, bytes memory y) internal pure returns (bool result) {}

    function cmp(bytes memory x, bytes memory y) internal pure returns (int256 result) {}
}
