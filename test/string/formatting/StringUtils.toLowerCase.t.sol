// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsToLowerCaseTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_toLowerCase_basic() public pure {
        assertEq(StringUtils.toLowerCase("Hello World"), "hello world");
        assertEq(StringUtils.toLowerCase("sOlIdItY"), "solidity");
    }

    function test_toLowerCase_singleByte() public pure {
        assertEq(StringUtils.toLowerCase("A"), "a");
        assertEq(StringUtils.toLowerCase("a"), "a");
        assertEq(StringUtils.toLowerCase("Z"), "z");
        assertEq(StringUtils.toLowerCase("z"), "z");
        assertEq(StringUtils.toLowerCase("0"), "0");
        assertEq(StringUtils.toLowerCase("9"), "9");
        assertEq(StringUtils.toLowerCase(" "), " ");
    }

    function test_toLowerCase_emptySubject() public pure {
        assertEq(StringUtils.toLowerCase(""), "");
    }

    function test_toLowerCase_alreadyLowerCaseIsIdentity() public pure {
        assertEq(StringUtils.toLowerCase("abcdefghijklmnopqrstuvwxyz"), "abcdefghijklmnopqrstuvwxyz");
    }

    function test_toLowerCase_allUpperCase() public pure {
        assertEq(StringUtils.toLowerCase("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), "abcdefghijklmnopqrstuvwxyz");
    }

    function test_toLowerCase_asciiRangeBoundaries() public pure {
        assertEq(StringUtils.toLowerCase("@"), "@"); // 0x40, one below `A`
        assertEq(StringUtils.toLowerCase("A"), "a"); // 0x41
        assertEq(StringUtils.toLowerCase("Z"), "z"); // 0x5a
        assertEq(StringUtils.toLowerCase("["), "["); // 0x5b, one above `Z`
        assertEq(StringUtils.toLowerCase("`"), "`"); // 0x60, one below `a`
        assertEq(StringUtils.toLowerCase("{"), "{"); // 0x7b, one above `z`
    }

    function test_toLowerCase_nonAlphabeticUnchanged() public pure {
        string memory chars = " !\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}~";
        assertEq(StringUtils.toLowerCase(chars), chars);
    }

    function test_toLowerCase_longerThanWord() public pure {
        string memory subject = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG 0123456789";
        assertEq(StringUtils.toLowerCase(subject), "the quick brown fox jumps over the lazy dog 0123456789");
    }

    function test_toLowerCase_everyByteValue() public pure {
        bytes memory buffer = bytes(allBytes());
        bytes memory result = bytes(StringUtils.toLowerCase(string(buffer)));
        assertEq(result.length, buffer.length);

        for (uint256 i = 0; i < buffer.length; ++i) {
            if (isUpperCase(buffer[i])) {
                assertEq(result[i], bytes1(uint8(buffer[i]) + 0x20), "uppercase ASCII must shift by 0x20");
            } else {
                assertEq(result[i], buffer[i], "every other byte must be preserved");
            }
        }
    }

    function test_toLowerCase_highBitBytesUnchanged() public pure {
        for (uint256 i = 0x80; i <= 0xff; ++i) {
            string memory char = singleByte(i);
            assertEq(StringUtils.toLowerCase(char), char, "high-bit bytes must remain unchanged");
        }
    }

    function test_toLowerCase_utf8IsBytePreserving() public pure {
        assertEq(StringUtils.toLowerCase(unicode"Aé☃𝄞"), unicode"aé☃𝄞");
        assertEq(StringUtils.toLowerCase(unicode"A☃Z"), unicode"a☃z");
    }

    function test_toLowerCase_ignoresUnicode() public pure {
        assertEq(StringUtils.toLowerCase(unicode"ÉÀÜ"), unicode"ÉÀÜ");
        assertEq(vm.toLowercase(unicode"ÉÀÜ"), unicode"éàü");

        assertEq(StringUtils.toLowerCase(unicode"Ѩ"), unicode"Ѩ");
        assertEq(vm.toLowercase(unicode"Ѩ"), unicode"ѩ");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toLowerCase_preservesLength(string memory subject) public pure {
        string memory result = StringUtils.toLowerCase(subject);
        assertEq(bytes(result).length, bytes(subject).length, "lowercasing changed string length");
    }

    function test_fuzz_toLowerCase_idempotent(string memory subject) public pure {
        string memory once = StringUtils.toLowerCase(subject);
        assertEq(StringUtils.toLowerCase(once), once, "repeated lowercasing changed result");
    }

    function test_fuzz_toLowerCase_containsNoUpperCase(string memory subject) public pure {
        bytes memory result = bytes(StringUtils.toLowerCase(subject));
        for (uint256 i = 0; i < result.length; ++i) {
            assertFalse(isUpperCase(result[i]), "uppercase ASCII survived conversion");
        }
    }

    function test_fuzz_toLowerCase_absorbsToUpperCase(string memory subject) public pure {
        string memory expected = StringUtils.toLowerCase(subject);
        string memory result = StringUtils.toLowerCase(StringUtils.toUpperCase(subject));

        assertEq(result, expected, "lowercasing does not absorb uppercasing");
        assertMemoryInvariants(result);
        assertMemoryInvariants(expected);
    }

    function test_fuzz_toLowerCase_agreesWithCheatcodeOnAscii(string memory subject) public pure {
        string memory expected = vm.toLowercase(subject = boundAscii(subject));
        string memory result = StringUtils.toLowerCase(subject);

        assertEq(result, expected, "result differs from cheatcode on ASCII input");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_toLowerCase_differential(string memory subject) public pure {
        string memory expected = referenceToLowerCase(subject);
        string memory result = StringUtils.toLowerCase(subject);

        assertEq(result, expected, "result differs from reference implementation");
        assertMemoryInvariants(result);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceToLowerCase(string memory subject) internal pure returns (string memory) {
        bytes memory buffer = bytes(subject);
        bytes memory result = new bytes(buffer.length);

        for (uint256 i = 0; i < buffer.length; ++i) {
            result[i] = toLowerCase(buffer[i]);
        }

        return string(result);
    }
}
