// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StringUtils} from "src/StringUtils.sol";
import {StringUtilsTest} from "test/Base.t.sol";

contract StringUtilsFormatCaseTest is StringUtilsTest {
    // ─────────────────────────────────────────────────────────────────────────────
    //  Unit
    // ─────────────────────────────────────────────────────────────────────────────

    function test_formatCase_fromCamel() public pure {
        assertFormatCases({
            subject: "camelCase",
            camel: "camelCase",
            pascal: "CamelCase",
            const: "CAMEL_CASE",
            snake: "camel_case",
            kebab: "camel-case"
        });
    }

    function test_formatCase_fromPascal() public pure {
        assertFormatCases({
            subject: "PascalCase",
            camel: "pascalCase",
            pascal: "PascalCase",
            const: "PASCAL_CASE",
            snake: "pascal_case",
            kebab: "pascal-case"
        });
    }

    function test_formatCase_fromConstant() public pure {
        assertFormatCases({
            subject: "CONSTANT_CASE",
            camel: "constantCase",
            pascal: "ConstantCase",
            const: "CONSTANT_CASE",
            snake: "constant_case",
            kebab: "constant-case"
        });
    }

    function test_formatCase_fromSnake() public pure {
        assertFormatCases({
            subject: "snake_case",
            camel: "snakeCase",
            pascal: "SnakeCase",
            const: "SNAKE_CASE",
            snake: "snake_case",
            kebab: "snake-case"
        });
    }

    function test_formatCase_fromKebab() public pure {
        assertFormatCases({
            subject: "kebab-case",
            camel: "kebabCase",
            pascal: "KebabCase",
            const: "KEBAB_CASE",
            snake: "kebab_case",
            kebab: "kebab-case"
        });
    }

    function test_formatCase_oneWord() public pure {
        assertFormatCases({
            subject: "hello", camel: "hello", pascal: "Hello", const: "HELLO", snake: "hello", kebab: "hello"
        });
        assertFormatCases({
            subject: "Hello", camel: "hello", pascal: "Hello", const: "HELLO", snake: "hello", kebab: "hello"
        });
        assertFormatCases({
            subject: "HELLO", camel: "hello", pascal: "Hello", const: "HELLO", snake: "hello", kebab: "hello"
        });
    }

    function test_formatCase_twoWords() public pure {
        assertFormatCases({
            subject: "hello world",
            camel: "helloWorld",
            pascal: "HelloWorld",
            const: "HELLO_WORLD",
            snake: "hello_world",
            kebab: "hello-world"
        });
        assertFormatCases({
            subject: "Hello World",
            camel: "helloWorld",
            pascal: "HelloWorld",
            const: "HELLO_WORLD",
            snake: "hello_world",
            kebab: "hello-world"
        });
        assertFormatCases({
            subject: "HELLO WORLD",
            camel: "helloWorld",
            pascal: "HelloWorld",
            const: "HELLO_WORLD",
            snake: "hello_world",
            kebab: "hello-world"
        });
    }

    function test_formatCase_threeWords() public pure {
        assertFormatCases({
            subject: "hello world solidity",
            camel: "helloWorldSolidity",
            pascal: "HelloWorldSolidity",
            const: "HELLO_WORLD_SOLIDITY",
            snake: "hello_world_solidity",
            kebab: "hello-world-solidity"
        });
        assertFormatCases({
            subject: "Hello World Solidity",
            camel: "helloWorldSolidity",
            pascal: "HelloWorldSolidity",
            const: "HELLO_WORLD_SOLIDITY",
            snake: "hello_world_solidity",
            kebab: "hello-world-solidity"
        });
        assertFormatCases({
            subject: "HELLO WORLD SOLIDITY",
            camel: "helloWorldSolidity",
            pascal: "HelloWorldSolidity",
            const: "HELLO_WORLD_SOLIDITY",
            snake: "hello_world_solidity",
            kebab: "hello-world-solidity"
        });
    }

    function test_formatCase_withAcronym() public pure {
        assertFormatCases({
            subject: "ETHERSCAN_API_KEY",
            camel: "etherscanApiKey",
            pascal: "EtherscanApiKey",
            const: "ETHERSCAN_API_KEY",
            snake: "etherscan_api_key",
            kebab: "etherscan-api-key"
        });
        assertFormatCases({
            subject: "JSON-RPC Provider",
            camel: "jsonRpcProvider",
            pascal: "JsonRpcProvider",
            const: "JSON_RPC_PROVIDER",
            snake: "json_rpc_provider",
            kebab: "json-rpc-provider"
        });
        assertFormatCases({
            subject: "ERC1967PROXY",
            camel: "erc1967Proxy",
            pascal: "Erc1967Proxy",
            const: "ERC1967_PROXY",
            snake: "erc1967_proxy",
            kebab: "erc1967-proxy"
        });
        assertFormatCases({
            subject: "UUPSProxy",
            camel: "uupsProxy",
            pascal: "UupsProxy",
            const: "UUPS_PROXY",
            snake: "uups_proxy",
            kebab: "uups-proxy"
        });
        assertFormatCases({
            subject: "fooBAR", camel: "fooBar", pascal: "FooBar", const: "FOO_BAR", snake: "foo_bar", kebab: "foo-bar"
        });
        assertFormatCases({
            subject: "fooBarBAZ",
            camel: "fooBarBaz",
            pascal: "FooBarBaz",
            const: "FOO_BAR_BAZ",
            snake: "foo_bar_baz",
            kebab: "foo-bar-baz"
        });
    }

    function test_formatCase_withDigits() public pure {
        assertFormatCases({
            subject: "web3 ecosystem",
            camel: "web3Ecosystem",
            pascal: "Web3Ecosystem",
            const: "WEB3_ECOSYSTEM",
            snake: "web3_ecosystem",
            kebab: "web3-ecosystem"
        });
        assertFormatCases({
            subject: "Web3 Ecosystem",
            camel: "web3Ecosystem",
            pascal: "Web3Ecosystem",
            const: "WEB3_ECOSYSTEM",
            snake: "web3_ecosystem",
            kebab: "web3-ecosystem"
        });
        assertFormatCases({
            subject: "WEB3 ECOSYSTEM",
            camel: "web3Ecosystem",
            pascal: "Web3Ecosystem",
            const: "WEB3_ECOSYSTEM",
            snake: "web3_ecosystem",
            kebab: "web3-ecosystem"
        });
        assertFormatCases({
            subject: "IERC20Permit",
            camel: "ierc20Permit",
            pascal: "Ierc20Permit",
            const: "IERC20_PERMIT",
            snake: "ierc20_permit",
            kebab: "ierc20-permit"
        });
        assertFormatCases({
            subject: "foo2bar",
            camel: "foo2Bar",
            pascal: "Foo2Bar",
            const: "FOO2_BAR",
            snake: "foo2_bar",
            kebab: "foo2-bar"
        });
        assertFormatCases({
            subject: "version2Beta",
            camel: "version2Beta",
            pascal: "Version2Beta",
            const: "VERSION2_BETA",
            snake: "version2_beta",
            kebab: "version2-beta"
        });
        assertFormatCases({
            subject: "v0.0.1-alpha",
            camel: "v0.0.1Alpha",
            pascal: "V0.0.1Alpha",
            const: "V0.0.1_ALPHA",
            snake: "v0.0.1_alpha",
            kebab: "v0.0.1-alpha"
        });
    }

    function test_formatCase_allDigits() public pure {
        assertFormatCases({
            subject: "01234556789",
            camel: "01234556789",
            pascal: "01234556789",
            const: "01234556789",
            snake: "01234556789",
            kebab: "01234556789"
        });
        assertFormatCases({
            subject: "01234", camel: "01234", pascal: "01234", const: "01234", snake: "01234", kebab: "01234"
        });
        assertFormatCases({
            subject: "56789", camel: "56789", pascal: "56789", const: "56789", snake: "56789", kebab: "56789"
        });
        assertFormatCases({
            subject: "0.8.25", camel: "0.8.25", pascal: "0.8.25", const: "0.8.25", snake: "0.8.25", kebab: "0.8.25"
        });
        assertFormatCases({
            subject: "^0.8.25",
            camel: "^0.8.25",
            pascal: "^0.8.25",
            const: "^0.8.25",
            snake: "^0.8.25",
            kebab: "^0.8.25"
        });
    }

    function test_formatCase_suppressSeparatorBeforeDigit() public pure {
        assertFormatCases({
            subject: "ERC 20 Permit Token",
            camel: "erc20PermitToken",
            pascal: "Erc20PermitToken",
            const: "ERC20_PERMIT_TOKEN",
            snake: "erc20_permit_token",
            kebab: "erc20-permit-token"
        });
        assertFormatCases({
            subject: "erc 20 permit token",
            camel: "erc20PermitToken",
            pascal: "Erc20PermitToken",
            const: "ERC20_PERMIT_TOKEN",
            snake: "erc20_permit_token",
            kebab: "erc20-permit-token"
        });
        assertFormatCases({
            subject: "Erc 20 Permit Token",
            camel: "erc20PermitToken",
            pascal: "Erc20PermitToken",
            const: "ERC20_PERMIT_TOKEN",
            snake: "erc20_permit_token",
            kebab: "erc20-permit-token"
        });
        assertFormatCases({
            subject: "ERC 20 PERMIT TOKEN",
            camel: "erc20PermitToken",
            pascal: "Erc20PermitToken",
            const: "ERC20_PERMIT_TOKEN",
            snake: "erc20_permit_token",
            kebab: "erc20-permit-token"
        });
    }

    function test_formatCase_withSeparators() public pure {
        assertFormatCases({
            subject: "fooBar FOO_Bar-baz",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
    }

    function test_formatCase_leadingSeparators() public pure {
        assertFormatCases({
            subject: " fooBar FOO_Bar-baz",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
        assertFormatCases({
            subject: "_fooBar FOO_Bar-baz",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
        assertFormatCases({
            subject: "-fooBar FOO_Bar-baz",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
    }

    function test_formatCase_trailingSeparators() public pure {
        assertFormatCases({
            subject: "fooBar FOO_Bar-baz ",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
        assertFormatCases({
            subject: "fooBar FOO_Bar-baz_",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
        assertFormatCases({
            subject: "fooBar FOO_Bar-baz-",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
    }

    function test_formatCase_collapseMultipleSeparators() public pure {
        assertFormatCases({
            subject: "fooBar  FOO__Bar--baz  ",
            camel: "fooBarFooBarBaz",
            pascal: "FooBarFooBarBaz",
            const: "FOO_BAR_FOO_BAR_BAZ",
            snake: "foo_bar_foo_bar_baz",
            kebab: "foo-bar-foo-bar-baz"
        });
        assertFormatCases({
            subject: "  __init__  ", camel: "init", pascal: "Init", const: "INIT", snake: "init", kebab: "init"
        });
        assertFormatCases({
            subject: " --- skip next --- ",
            camel: "skipNext",
            pascal: "SkipNext",
            const: "SKIP_NEXT",
            snake: "skip_next",
            kebab: "skip-next"
        });
        assertFormatCases({
            subject: " _- supported-separators -_ ",
            camel: "supportedSeparators",
            pascal: "SupportedSeparators",
            const: "SUPPORTED_SEPARATORS",
            snake: "supported_separators",
            kebab: "supported-separators"
        });
    }

    function test_formatCase_allSeparators() public pure {
        assertFormatCases({subject: "  ", camel: "", pascal: "", const: "", snake: "", kebab: ""});
        assertFormatCases({subject: "--", camel: "", pascal: "", const: "", snake: "", kebab: ""});
        assertFormatCases({subject: "__", camel: "", pascal: "", const: "", snake: "", kebab: ""});
        assertFormatCases({subject: " _-_-_ ", camel: "", pascal: "", const: "", snake: "", kebab: ""});
        assertFormatCases({subject: "  -_ _- ", camel: "", pascal: "", const: "", snake: "", kebab: ""});
    }

    function test_formatCase_withPunctuations() public pure {
        assertFormatCases({
            subject: "foo.BAR",
            camel: "foo.Bar",
            pascal: "Foo.Bar",
            const: "FOO.BAR",
            snake: "foo.bar",
            kebab: "foo.bar"
        });
        assertFormatCases({
            subject: "foo@BAR",
            camel: "foo@Bar",
            pascal: "Foo@Bar",
            const: "FOO@BAR",
            snake: "foo@bar",
            kebab: "foo@bar"
        });
        assertFormatCases({
            subject: "foo.barBaz",
            camel: "foo.BarBaz",
            pascal: "Foo.BarBaz",
            const: "FOO.BAR_BAZ",
            snake: "foo.bar_baz",
            kebab: "foo.bar-baz"
        });
        assertFormatCases({
            subject: "foo/barBaz",
            camel: "foo/BarBaz",
            pascal: "Foo/BarBaz",
            const: "FOO/BAR_BAZ",
            snake: "foo/bar_baz",
            kebab: "foo/bar-baz"
        });
    }

    function test_formatCase_punctuationIsPreservedBoundary() public pure {
        assertFormatCases({
            subject: "foo.BAR",
            camel: "foo.Bar",
            pascal: "Foo.Bar",
            const: "FOO.BAR",
            snake: "foo.bar",
            kebab: "foo.bar"
        });
        assertFormatCases({
            subject: "foo@BAR",
            camel: "foo@Bar",
            pascal: "Foo@Bar",
            const: "FOO@BAR",
            snake: "foo@bar",
            kebab: "foo@bar"
        });
        assertFormatCases({
            subject: "foo+BAR",
            camel: "foo+Bar",
            pascal: "Foo+Bar",
            const: "FOO+BAR",
            snake: "foo+bar",
            kebab: "foo+bar"
        });
        assertFormatCases({
            subject: "foo/barBaz",
            camel: "foo/BarBaz",
            pascal: "Foo/BarBaz",
            const: "FOO/BAR_BAZ",
            snake: "foo/bar_baz",
            kebab: "foo/bar-baz"
        });
    }

    function test_formatCase_consecutivePunctuation() public pure {
        assertFormatCases({
            subject: "foo..BAR",
            camel: "foo..Bar",
            pascal: "Foo..Bar",
            const: "FOO..BAR",
            snake: "foo..bar",
            kebab: "foo..bar"
        });
        assertFormatCases({
            subject: "foo/@BAR",
            camel: "foo/@Bar",
            pascal: "Foo/@Bar",
            const: "FOO/@BAR",
            snake: "foo/@bar",
            kebab: "foo/@bar"
        });
    }

    function test_formatCase_leadingPunctuation() public pure {
        assertFormatCases({subject: ".foo", camel: ".Foo", pascal: ".Foo", const: ".FOO", snake: ".foo", kebab: ".foo"});
        assertFormatCases({subject: "@BAR", camel: "@Bar", pascal: "@Bar", const: "@BAR", snake: "@bar", kebab: "@bar"});
    }

    function test_formatCase_trailingPunctuation() public pure {
        assertFormatCases({subject: "foo.", camel: "foo.", pascal: "Foo.", const: "FOO.", snake: "foo.", kebab: "foo."});
        assertFormatCases({subject: "BAR@", camel: "bar@", pascal: "Bar@", const: "BAR@", snake: "bar@", kebab: "bar@"});
    }

    function test_formatCase_punctuationAdjacentToSeparators() public pure {
        assertFormatCases({
            subject: "foo_.BAR",
            camel: "foo.Bar",
            pascal: "Foo.Bar",
            const: "FOO.BAR",
            snake: "foo.bar",
            kebab: "foo.bar"
        });
        assertFormatCases({
            subject: "foo-_BAR", camel: "fooBar", pascal: "FooBar", const: "FOO_BAR", snake: "foo_bar", kebab: "foo-bar"
        });

        // Preserved punctuation already constitutes a boundary, so a normalized
        // separator immediately following it should not add another boundary.
        assertFormatCases({
            subject: "foo._BAR",
            camel: "foo.Bar",
            pascal: "Foo.Bar",
            const: "FOO.BAR",
            snake: "foo.bar",
            kebab: "foo.bar"
        });
        assertFormatCases({
            subject: "foo.-BAR",
            camel: "foo.Bar",
            pascal: "Foo.Bar",
            const: "FOO.BAR",
            snake: "foo.bar",
            kebab: "foo.bar"
        });
    }

    function test_formatCase_punctuationBeforeAcronym() public pure {
        assertFormatCases({subject: "$BAR", camel: "$Bar", pascal: "$Bar", const: "$BAR", snake: "$bar", kebab: "$bar"});
        assertFormatCases({subject: "$BAZ", camel: "$Baz", pascal: "$Baz", const: "$BAZ", snake: "$baz", kebab: "$baz"});
        assertFormatCases({
            subject: "$FRZZ", camel: "$Frzz", pascal: "$Frzz", const: "$FRZZ", snake: "$frzz", kebab: "$frzz"
        });
    }

    function test_formatCase_punctuationBeforeMixedCaseAcronym() public pure {
        assertFormatCases({subject: "$Foo", camel: "$Foo", pascal: "$Foo", const: "$FOO", snake: "$foo", kebab: "$foo"});
        assertFormatCases({
            subject: "$FOOBar",
            camel: "$FooBar",
            pascal: "$FooBar",
            const: "$FOO_BAR",
            snake: "$foo_bar",
            kebab: "$foo-bar"
        });
        assertFormatCases({
            subject: "$fooBAR",
            camel: "$FooBar",
            pascal: "$FooBar",
            const: "$FOO_BAR",
            snake: "$foo_bar",
            kebab: "$foo-bar"
        });
    }

    function test_formatCase_punctuationBeforeNumericWord() public pure {
        assertFormatCases({
            subject: "$3BAR", camel: "$3Bar", pascal: "$3Bar", const: "$3_BAR", snake: "$3_bar", kebab: "$3-bar"
        });
        assertFormatCases({
            subject: "$3bar", camel: "$3Bar", pascal: "$3Bar", const: "$3_BAR", snake: "$3_bar", kebab: "$3-bar"
        });
    }

    function test_formatCase_printableAsciiBoundaries() public pure {
        assertFormatCases({subject: " ", camel: "", pascal: "", const: "", snake: "", kebab: ""});
        assertFormatCases({subject: "~", camel: "~", pascal: "~", const: "~", snake: "~", kebab: "~"});
        assertFormatCases({
            subject: "!foo~BAR",
            camel: "!Foo~Bar",
            pascal: "!Foo~Bar",
            const: "!FOO~BAR",
            snake: "!foo~bar",
            kebab: "!foo~bar"
        });
    }

    function test_formatCase_singleChar() public pure {
        assertFormatCases({subject: "a", camel: "a", pascal: "A", const: "A", snake: "a", kebab: "a"});
        assertFormatCases({subject: "A", camel: "a", pascal: "A", const: "A", snake: "a", kebab: "a"});
    }

    function test_formatCase_emptyString() public pure {
        assertFormatCases({subject: "", camel: "", pascal: "", const: "", snake: "", kebab: ""});
    }

    function test_formatCase_acceptsEveryPrintableAsciiChar() public pure {
        for (uint256 i = 0x20; i <= 0x7e; ++i) {
            string memory subject = singleByte(i);

            formatCamelCase(subject);
            formatPascalCase(subject);
            formatConstantCase(subject);
            formatSnakeCase(subject);
            formatKebabCase(subject);
        }
    }

    function test_formatCase_revertsWithNonPrintableAscii() public {
        vm.expectRevert(StringUtils.InvalidFormatChar.selector);
        formatCamelCase(string(hex"1f"));

        vm.expectRevert(StringUtils.InvalidFormatChar.selector);
        formatCamelCase(string(hex"7f"));

        vm.expectRevert(StringUtils.InvalidFormatChar.selector);
        formatCamelCase(string(abi.encodePacked(hex"80")));

        vm.expectRevert(StringUtils.InvalidFormatChar.selector);
        formatCamelCase("\n");
    }

    function test_formatCase_camelCanonicalIsIdentity() public pure {
        assertEq(formatCamelCase("camelCase"), "camelCase");
        assertEq(formatCamelCase("foo2Bar"), "foo2Bar");
        assertEq(formatCamelCase("uupsProxy"), "uupsProxy");
        assertEq(formatCamelCase("foo.Bar"), "foo.Bar");
    }

    function test_formatCase_pascalCanonicalIsIdentity() public pure {
        assertEq(formatPascalCase("PascalCase"), "PascalCase");
        assertEq(formatPascalCase("Foo2Bar"), "Foo2Bar");
        assertEq(formatPascalCase("UupsProxy"), "UupsProxy");
        assertEq(formatPascalCase("Foo.Bar"), "Foo.Bar");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Fuzz
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_formatCase_revertsWithInvalidChar(bytes1 char) public {
        vm.assume(!isPrintable(char));

        vm.expectRevert(StringUtils.InvalidFormatChar.selector);
        formatCamelCase(string(abi.encodePacked(char)));
    }

    function test_fuzz_formatCase_outputRemainsPrintableAscii(string memory subject) public pure {
        subject = boundAscii(subject);

        StringUtils.CaseType[5] memory cases = caseTypesFixed();

        for (uint256 i = 0; i < cases.length; ++i) {
            bytes memory result = bytes(StringUtils.formatCase(subject, cases[i]));

            for (uint256 j = 0; j < result.length; ++j) {
                assertTrue(isPrintable(result[j]), "formatted output contains non-printable ASCII byte");
            }
        }
    }

    function test_fuzz_formatCase_separatedCasesAreIdempotent(string memory subject) public pure {
        subject = boundAscii(subject);

        StringUtils.CaseType[5] memory cases = caseTypesFixed();

        for (uint256 i = 2; i < cases.length; ++i) {
            string memory once = StringUtils.formatCase(subject, cases[i]);
            string memory twice = StringUtils.formatCase(once, cases[i]);

            assertEq(twice, once, string.concat("formatting is not idempotent for `", asString(cases[i]), "`"));
            assertMemoryInvariants(once);
            assertMemoryInvariants(twice);
        }
    }

    function test_fuzz_formatCase_agreeOnSeparatedCases(string memory subject) public pure {
        subject = boundAscii(subject);

        string memory snake = formatSnakeCase(subject);
        string memory kebab = formatKebabCase(subject);
        string memory const = formatConstantCase(subject);

        assertEq(vm.replace(snake, "_", "-"), kebab);
        assertEq(vm.toLowercase(const), snake);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Differential
    // ─────────────────────────────────────────────────────────────────────────────

    function test_fuzz_formatCase_differential(string memory subject) public pure {
        subject = boundAscii(subject);

        StringUtils.CaseType[5] memory cases = caseTypesFixed();

        for (uint256 i = 0; i < cases.length; ++i) {
            string memory expected = referenceFormatCase(subject, cases[i]);
            string memory result = StringUtils.formatCase(subject, cases[i]);

            assertEq(result, expected, "result differs from reference implementation");
            assertMemoryInvariants(result);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Reference implementation
    // ─────────────────────────────────────────────────────────────────────────────

    function referenceFormatCase(string memory subject, StringUtils.CaseType caseType)
        internal
        pure
        returns (string memory)
    {
        bytes memory input = bytes(subject);
        bytes memory output = new bytes(input.length * 2);
        uint256 length = 0;

        bytes1 separator;
        if (caseType == StringUtils.CaseType.Constant || caseType == StringUtils.CaseType.Snake) {
            separator = "_";
        } else if (caseType == StringUtils.CaseType.Kebab) {
            separator = "-";
        }

        bool usesSeparator = separator != bytes1(0);
        bool capitalizeNext = caseType == StringUtils.CaseType.Pascal;

        for (uint256 i = 0; i < input.length; ++i) {
            bytes1 char = input[i];
            assertTrue(isPrintable(char), "reference input contains non-printable ASCII byte");

            bytes1 next = i + 1 < input.length ? input[i + 1] : bytes1(0);
            bytes1 prev = length != 0 ? output[length - 1] : bytes1(0);
            bytes1 prevSource = i != 0 ? input[i - 1] : bytes1(0);

            if (isSeparator(char)) {
                if (length == 0) continue;

                if (usesSeparator) {
                    for (uint256 o = i + 1; o < input.length; ++o) {
                        next = input[o];
                        if (!isSeparator(next)) break;
                    }

                    if (isAlphanumeric(prev) && !isNumeric(next)) {
                        output[length++] = separator;
                    }
                } else {
                    capitalizeNext = true;
                }

                continue;
            }

            if (!isAlphanumeric(char)) {
                if (usesSeparator && length != 0 && output[length - 1] == separator) {
                    --length;
                }

                output[length++] = char;
                if (!usesSeparator) capitalizeNext = true;

                continue;
            }

            if (usesSeparator) {
                bool insertBoundary = false;

                if (i != 0 && isAlphanumeric(prevSource)) {
                    if (isUpperCase(char)) {
                        insertBoundary = isLowerCase(prevSource) || isLowerCase(next)
                            || (isUpperCase(next) && !isUpperCase(prevSource));
                    }

                    if (!isNumeric(char) && isNumeric(prevSource)) {
                        insertBoundary = true;
                    }
                }

                if (insertBoundary && length != 0 && output[length - 1] != separator) {
                    output[length++] = separator;
                }

                if (caseType == StringUtils.CaseType.Constant) {
                    char = toUpperCase(char);
                } else {
                    char = toLowerCase(char);
                }
            } else {
                if (isNumeric(prev) || capitalizeNext) {
                    if (isLowerCase(char)) char = toUpperCase(char);
                    if (!isNumeric(char)) capitalizeNext = false;
                } else if (isUpperCase(char)) {
                    if (caseType == StringUtils.CaseType.Camel) {
                        bool shouldLowercase = length == 0;

                        if (i != 0 && isAlphanumeric(prevSource) && isUpperCase(prevSource) && !isLowerCase(next)) {
                            shouldLowercase = true;
                        }

                        if (shouldLowercase) char = toLowerCase(char);
                    } else {
                        if (i != 0 && isUpperCase(prevSource) && !isLowerCase(next)) {
                            char = toLowerCase(char);
                        }
                    }
                }
            }

            output[length++] = char;
        }

        while (length != 0 && usesSeparator && output[length - 1] == separator) {
            --length;
        }

        assembly ("memory-safe") {
            mstore(output, length)
        }

        return string(output);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ─────────────────────────────────────────────────────────────────────────────

    function assertFormatCase(string memory result, string memory expected, string memory message) internal pure {
        assertEq(result, expected, string.concat("formatCase: ", message));
        assertMemoryInvariants(result);
    }

    function assertFormatCases(
        string memory subject,
        string memory camel,
        string memory pascal,
        string memory const,
        string memory snake,
        string memory kebab
    ) internal pure {
        assertFormatCase(
            formatCamelCase(subject), camel, string.concat("incorrect Camel case output for `", subject, "`")
        );
        assertFormatCase(
            formatPascalCase(subject), pascal, string.concat("incorrect Pascal case output for `", subject, "`")
        );
        assertFormatCase(
            formatConstantCase(subject), const, string.concat("incorrect Constant case output for `", subject, "`")
        );
        assertFormatCase(
            formatSnakeCase(subject), snake, string.concat("incorrect snake_case output for `", subject, "`")
        );
        assertFormatCase(
            formatKebabCase(subject), kebab, string.concat("incorrect kebab-case output for `", subject, "`")
        );
    }

    function formatCamelCase(string memory subject) internal pure returns (string memory) {
        return StringUtils.formatCase(subject, StringUtils.CaseType.Camel);
    }

    function formatPascalCase(string memory subject) internal pure returns (string memory) {
        return StringUtils.formatCase(subject, StringUtils.CaseType.Pascal);
    }

    function formatConstantCase(string memory subject) internal pure returns (string memory) {
        return StringUtils.formatCase(subject, StringUtils.CaseType.Constant);
    }

    function formatSnakeCase(string memory subject) internal pure returns (string memory) {
        return StringUtils.formatCase(subject, StringUtils.CaseType.Snake);
    }

    function formatKebabCase(string memory subject) internal pure returns (string memory) {
        return StringUtils.formatCase(subject, StringUtils.CaseType.Kebab);
    }

    function caseTypesFixed() internal pure returns (StringUtils.CaseType[5] memory) {
        return [
            StringUtils.CaseType.Camel,
            StringUtils.CaseType.Pascal,
            StringUtils.CaseType.Constant,
            StringUtils.CaseType.Snake,
            StringUtils.CaseType.Kebab
        ];
    }

    function asCaseType(uint8 v) internal pure returns (StringUtils.CaseType) {
        vm.assume(v <= uint8(type(StringUtils.CaseType).max));
        return StringUtils.CaseType(v);
    }

    function asString(StringUtils.CaseType caseType) internal pure returns (string memory) {
        if (caseType == StringUtils.CaseType.Camel) return "Camel case";
        if (caseType == StringUtils.CaseType.Pascal) return "Pascal case";
        if (caseType == StringUtils.CaseType.Constant) return "Constant case";
        if (caseType == StringUtils.CaseType.Snake) return "Snake case";
        return "Kebab case";
    }
}
