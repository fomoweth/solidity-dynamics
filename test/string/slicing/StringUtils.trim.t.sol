// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {BaseTest} from "test/Base.t.sol";

contract StringUtilsTrimTest is BaseTest {
    string internal constant WS = " \t\n\x0b\x0c\r ";

    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_trim_basic() public pure {
        assertEq(StringUtils.trim("  hello world  "), "hello world");
        assertEq(StringUtils.trim("\thello world\t"), "hello world");
        assertEq(StringUtils.trim("\nhello world\n"), "hello world");
        assertEq(StringUtils.trim("\rhello world\r"), "hello world");
    }

    function test_trim_leadingOnly() public pure {
        assertEq(StringUtils.trim("    hello world"), "hello world");
        assertEq(StringUtils.trim("\thello world"), "hello world");
        assertEq(StringUtils.trim("\nhello world"), "hello world");
        assertEq(StringUtils.trim("\rhello world"), "hello world");
    }

    function test_trim_trailingOnly() public pure {
        assertEq(StringUtils.trim("hello world    "), "hello world");
        assertEq(StringUtils.trim("hello world\t"), "hello world");
        assertEq(StringUtils.trim("hello world\n"), "hello world");
        assertEq(StringUtils.trim("hello world\r"), "hello world");
    }

    function test_trim_singleChar() public pure {
        assertEq(StringUtils.trim("  a  "), "a");
        assertEq(StringUtils.trim("    a"), "a");
        assertEq(StringUtils.trim("a    "), "a");
    }

    function test_trim_emptySubject() public pure {
        assertEq(StringUtils.trim(""), "");
    }

    function test_trim_noWhitespace() public pure {
        assertEq(StringUtils.trim("hello world"), "hello world");
    }

    function test_trim_allWhitespace() public pure {
        string memory subject = string.concat(WS, "hello world", WS);
        assertEq(StringUtils.trim(subject), "hello world");
        assertEq(StringUtils.trim(WS), "");
    }

    function test_trim_mixedWhitespace() public pure {
        assertEq(StringUtils.trim("\t \n hello world \r\n"), "hello world");
    }

    function test_trimStart_basic() public pure {
        assertEq(StringUtils.trimStart("  hello world"), "hello world");
        assertEq(StringUtils.trimStart("\thello world"), "hello world");
        assertEq(StringUtils.trimStart("\nhello world"), "hello world");
        assertEq(StringUtils.trimStart("\rhello world"), "hello world");
    }

    function test_trimStart_noLeading() public pure {
        assertEq(StringUtils.trimStart("hello world  "), "hello world  ");
        assertEq(StringUtils.trimStart("hello world\t"), "hello world\t");
        assertEq(StringUtils.trimStart("hello world\n"), "hello world\n");
        assertEq(StringUtils.trimStart("hello world\r"), "hello world\r");
    }

    function test_trimStart_trailingPreserved() public pure {
        assertEq(StringUtils.trimStart("  hello world  "), "hello world  ");
        assertEq(StringUtils.trimStart("\thello world\t"), "hello world\t");
        assertEq(StringUtils.trimStart("\nhello world\n"), "hello world\n");
        assertEq(StringUtils.trimStart("\rhello world\r"), "hello world\r");
    }

    function test_trimStart_singleChar() public pure {
        assertEq(StringUtils.trimStart("  a  "), "a  ");
        assertEq(StringUtils.trimStart("    a"), "a");
        assertEq(StringUtils.trimStart("a    "), "a    ");
    }

    function test_trimStart_emptySubject() public pure {
        assertEq(StringUtils.trimStart(""), "");
    }

    function test_trimStart_noWhitespace() public pure {
        assertEq(StringUtils.trimStart("hello world"), "hello world");
    }

    function test_trimStart_allWhitespace() public pure {
        string memory subject = string.concat(WS, "hello world", WS);
        assertEq(StringUtils.trimStart(subject), string.concat("hello world", WS));
        assertEq(StringUtils.trimStart(WS), "");
    }

    function test_trimEnd_basic() public pure {
        assertEq(StringUtils.trimEnd("hello world  "), "hello world");
        assertEq(StringUtils.trimEnd("hello world\t"), "hello world");
        assertEq(StringUtils.trimEnd("hello world\n"), "hello world");
        assertEq(StringUtils.trimEnd("hello world\r"), "hello world");
    }

    function test_trimEnd_noTrailing() public pure {
        assertEq(StringUtils.trimEnd("  hello world"), "  hello world");
        assertEq(StringUtils.trimEnd("\thello world"), "\thello world");
        assertEq(StringUtils.trimEnd("\nhello world"), "\nhello world");
        assertEq(StringUtils.trimEnd("\rhello world"), "\rhello world");
    }

    function test_trimEnd_leadingPreserved() public pure {
        assertEq(StringUtils.trimEnd("  hello world  "), "  hello world");
        assertEq(StringUtils.trimEnd("\thello world\t"), "\thello world");
        assertEq(StringUtils.trimEnd("\nhello world\n"), "\nhello world");
        assertEq(StringUtils.trimEnd("\rhello world\r"), "\rhello world");
    }

    function test_trimEnd_singleChar() public pure {
        assertEq(StringUtils.trimEnd("  a  "), "  a");
        assertEq(StringUtils.trimEnd("    a"), "    a");
        assertEq(StringUtils.trimEnd("a    "), "a");
    }

    function test_trimEnd_emptySubject() public pure {
        assertEq(StringUtils.trimEnd(""), "");
    }

    function test_trimEnd_noWhitespace() public pure {
        assertEq(StringUtils.trimEnd("hello world"), "hello world");
    }

    function test_trimEnd_allWhitespace() public pure {
        string memory subject = string.concat(WS, "hello world", WS);
        assertEq(StringUtils.trimEnd(subject), string.concat(WS, "hello world"));
        assertEq(StringUtils.trimEnd(WS), "");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_trim_idempotent(string memory subject) public pure {
        string memory once = StringUtils.trim(subject);
        assertEq(StringUtils.trim(once), once);
    }

    function test_fuzz_trimStart_idempotent(string memory subject) public pure {
        string memory once = StringUtils.trimStart(subject);
        assertEq(StringUtils.trimStart(once), once);
    }

    function test_fuzz_trimEnd_idempotent(string memory subject) public pure {
        string memory once = StringUtils.trimEnd(subject);
        assertEq(StringUtils.trimEnd(once), once);
    }

    function test_fuzz_trim(string memory subject) public pure {
        assertEq(StringUtils.trim(subject), vm.trim(subject));
    }

    function test_fuzz_trimStart(string memory subject) public pure {
        bytes memory buffer = bytes(StringUtils.trimStart(subject));
        if (buffer.length != 0) assertFalse(isWhitespace(buffer[0]));
    }

    function test_fuzz_trimEnd(string memory subject) public pure {
        bytes memory buffer = bytes(StringUtils.trimEnd(subject));
        if (buffer.length != 0) assertFalse(isWhitespace(buffer[buffer.length - 1]));
    }

    function test_fuzz_trim_compose(bytes memory buffer, uint256 seed) public pure {
        (string memory subject, string memory expected) = compose(buffer, seed, true, true);
        string memory actual = StringUtils.trim(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_trimStart_compose(bytes memory buffer, uint256 seed) public pure {
        (string memory subject, string memory expected) = compose(buffer, seed, true, false);
        string memory actual = StringUtils.trimStart(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_trimEnd_compose(bytes memory buffer, uint256 seed) public pure {
        (string memory subject, string memory expected) = compose(buffer, seed, false, true);
        string memory actual = StringUtils.trimEnd(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_trim_differential(string memory subject) public pure {
        string memory expected = referenceTrim(subject, true, true);
        string memory actual = StringUtils.trim(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_trimStart_differential(string memory subject) public pure {
        string memory expected = referenceTrim(subject, true, false);
        string memory actual = StringUtils.trimStart(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    function test_fuzz_trimEnd_differential(string memory subject) public pure {
        string memory expected = referenceTrim(subject, false, true);
        string memory actual = StringUtils.trimEnd(subject);

        assertEq(actual, expected);
        assertMemoryInvariants(actual);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceTrim(string memory subject, bool trimLeading, bool trimTrailing)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = bytes(subject);
        uint256 start = 0;
        uint256 end = buffer.length;

        if (trimLeading) while (start < end && isWhitespace(buffer[start])) start++;
        if (trimTrailing) while (end > start && isWhitespace(buffer[end - 1])) end--;

        bytes memory result = new bytes(end - start);
        for (uint256 i = 0; i < result.length; ++i) {
            result[i] = buffer[start + i];
        }
        return string(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function compose(bytes memory buffer, uint256 seed, bool useLeading, bool useTrailing)
        internal
        pure
        returns (string memory subject, string memory expected)
    {
        if (buffer.length != 0) {
            buffer[0] = "x";
            buffer[buffer.length - 1] = "y";
        }

        bytes memory ws = "\t\n\x0b\x0c\r ";
        bytes memory leadingBytes = new bytes(useLeading ? seed % 7 : 0);
        bytes memory trailingBytes = new bytes(useTrailing ? (seed >> 8) % 7 : 0);

        for (uint256 i = 0; i < leadingBytes.length; ++i) {
            leadingBytes[i] = ws[(seed >> i) % 6];
        }

        for (uint256 i = 0; i < trailingBytes.length; ++i) {
            trailingBytes[i] = ws[(seed >> (i + 16)) % 6];
        }

        subject = string(abi.encodePacked(leadingBytes, buffer, trailingBytes));
        expected = string(buffer);
    }

    function isWhitespace(bytes1 char) internal pure returns (bool) {
        return char == bytes1(0x09) // horizontal tab (`\t`)
            || char == bytes1(0x0a) // line feed (`\n`)
            || char == bytes1(0x0b) // vertical tab (`\v`)
            || char == bytes1(0x0c) // form feed (`\f`)
            || char == bytes1(0x0d) // carriage return (`\r`)
            || char == bytes1(0x20); // space (` `)
    }
}
