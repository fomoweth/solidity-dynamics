// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsToUpperCaseTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toUpperCase_basic() public pure {
        assertEq(StringUtils.toUpperCase("Hello World"), "HELLO WORLD");
        assertEq(StringUtils.toUpperCase("sOlIdItY"), "SOLIDITY");
    }

    function test_toUpperCase_capitalize() public pure {
        assertEq(capitalize("hello"), "Hello");
        assertEq(capitalize("world"), "World");
        assertEq(capitalize("solidity"), "Solidity");
    }

    function test_toUpperCase_singleByte() public pure {
        assertEq(StringUtils.toUpperCase("A"), "A");
        assertEq(StringUtils.toUpperCase("a"), "A");
        assertEq(StringUtils.toUpperCase("Z"), "Z");
        assertEq(StringUtils.toUpperCase("z"), "Z");
        assertEq(StringUtils.toUpperCase("0"), "0");
        assertEq(StringUtils.toUpperCase("9"), "9");
        assertEq(StringUtils.toUpperCase(" "), " ");
    }

    function test_toUpperCase_emptySubject() public pure {
        assertEq(StringUtils.toUpperCase(""), "");
    }

    function test_toUpperCase_alreadyUpperCase_isIdentity() public pure {
        assertEq(StringUtils.toUpperCase("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    }

    function test_toUpperCase_allLowerCase() public pure {
        assertEq(StringUtils.toUpperCase("abcdefghijklmnopqrstuvwxyz"), "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    }

    function test_toUpperCase_asciiRangeBoundaries() public pure {
        assertEq(StringUtils.toUpperCase("`"), "`"); // 0x60, one below `a`
        assertEq(StringUtils.toUpperCase("a"), "A"); // 0x61
        assertEq(StringUtils.toUpperCase("z"), "Z"); // 0x7a
        assertEq(StringUtils.toUpperCase("{"), "{"); // 0x7b, one above `z`
        assertEq(StringUtils.toUpperCase("@"), "@"); // 0x40, one below `A`
        assertEq(StringUtils.toUpperCase("["), "["); // 0x5b, one above `Z`
    }

    function test_toUpperCase_nonAlphabeticUnchanged() public pure {
        string memory chars = " !\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}~";
        assertEq(StringUtils.toUpperCase(chars), chars);
    }

    function test_toUpperCase_longerThanWord() public pure {
        string memory subject = "the quick brown fox jumps over the lazy dog 0123456789";
        assertEq(StringUtils.toUpperCase(subject), "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG 0123456789");
    }

    function test_toUpperCase_everyByteValue() public pure {
        bytes memory buffer = bytes(allBytes());
        bytes memory result = bytes(StringUtils.toUpperCase(string(buffer)));
        assertEq(result.length, buffer.length);

        for (uint256 i = 0; i < buffer.length; ++i) {
            if (isLowerCase(buffer[i])) {
                assertEq(result[i], bytes1(uint8(buffer[i]) - 0x20), "lowercase ASCII must shift by 0x20");
            } else {
                assertEq(result[i], buffer[i], "every other byte must be preserved");
            }
        }
    }

    function test_toUpperCase_highBitBytesUnchanged() public pure {
        for (uint256 i = 0x80; i <= 0xff; ++i) {
            string memory char = singleByte(i);
            assertEq(StringUtils.toUpperCase(char), char, "high-bit bytes must remain unchanged");
        }
    }

    function test_toUpperCase_utf8IsBytePreserving() public pure {
        assertEq(StringUtils.toUpperCase(unicode"aé☃𝄞"), unicode"Aé☃𝄞");
        assertEq(StringUtils.toUpperCase(unicode"a☃z"), unicode"A☃Z");
    }

    function test_toUpperCase_ignoresUnicode() public pure {
        assertEq(StringUtils.toUpperCase(unicode"éàü"), unicode"éàü");
        assertEq(vm.toUppercase(unicode"éàü"), unicode"ÉÀÜ");

        assertEq(StringUtils.toUpperCase(unicode"ѩ"), unicode"ѩ");
        assertEq(vm.toUppercase(unicode"ѩ"), unicode"Ѩ");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toUpperCase_preservesLength(string memory subject) public pure {
        string memory result = StringUtils.toUpperCase(subject);
        assertEq(bytes(result).length, bytes(subject).length, "uppercasing changed string length");
    }

    function test_fuzz_toUpperCase_idempotent(string memory subject) public pure {
        string memory once = StringUtils.toUpperCase(subject);
        assertEq(StringUtils.toUpperCase(once), once, "repeated uppercasing changed result");
    }

    function test_fuzz_toUpperCase_containsNoLowerCase(string memory subject) public pure {
        bytes memory result = bytes(StringUtils.toUpperCase(subject));
        for (uint256 i = 0; i < result.length; ++i) {
            assertFalse(isLowerCase(result[i]), "lowercase ASCII survived conversion");
        }
    }

    function test_fuzz_toUpperCase_absorbsToLowerCase(string memory subject) public pure {
        string memory expected = StringUtils.toUpperCase(subject);
        string memory result = StringUtils.toUpperCase(StringUtils.toLowerCase(subject));

        assertEq(result, expected, "uppercasing does not absorb lowercasing");
        assertMemoryInvariants(result);
        assertMemoryInvariants(expected);
    }

    function test_fuzz_toUpperCase_agreesWithCheatcodeOnAscii(string memory subject) public pure {
        string memory expected = vm.toUppercase(subject = boundAscii(subject));
        string memory result = StringUtils.toUpperCase(subject);

        assertEq(result, expected, "result differs from cheatcode on ASCII input");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toUpperCase_differential(string memory subject) public pure {
        string memory expected = referenceToUpperCase(subject);
        string memory result = StringUtils.toUpperCase(subject);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceToUpperCase(string memory subject) internal pure returns (string memory) {
        bytes memory buffer = bytes(subject);
        bytes memory result = new bytes(buffer.length);

        for (uint256 i = 0; i < buffer.length; ++i) {
            result[i] = toUpperCase(buffer[i]);
        }

        return string(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function capitalize(string memory subject) internal pure returns (string memory) {
        return string.concat(StringUtils.toUpperCase(StringUtils.slice(subject, 0, 1)), StringUtils.slice(subject, 1));
    }
}
