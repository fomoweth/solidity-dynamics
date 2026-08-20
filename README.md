# solidity-dynamics

[![Test](https://github.com/fomoweth/solidity-dynamics/actions/workflows/test.yml/badge.svg)](https://github.com/fomoweth/solidity-dynamics/actions/workflows/test.yml)
[![Solidity](https://img.shields.io/badge/solidity-%3E%3D0.8.25-2b247c)](https://docs.soliditylang.org/en/v0.8.25)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Gas-efficient Solidity utility libraries for working with strings and dynamic byte arrays.

`solidity-dynamics` provides low-level utilities for converting, formatting, constructing, slicing, searching, and comparing strings and byte arrays. The implementation favors memory-efficient Yul and modern EVM primitives such as `MCOPY` while exposing conventional Solidity library APIs.

## Table of Contents

- [Overview](#overview)
  - [Features](#features)
  - [Design](#design)
  - [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Usage](#usage)
  - [String Utilities](#string-utilities)
  - [Byte Utilities](#byte-utilities)
  - [Advanced Examples](#advanced-examples)
- [Testing](#testing)
- [API Reference](#api-reference)
  - [StringUtils.sol](#stringutilssol)
  - [BytesUtils.sol](#bytesutilssol)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Overview

`solidity-dynamics` consists of two standalone utility libraries:

- [`StringUtils`](./src/StringUtils.sol) provides conversion, case formatting, construction, slicing, searching, and comparison utilities for Solidity strings.
- [`BytesUtils`](./src/BytesUtils.sol) provides construction, slicing, searching, and comparison utilities for dynamic byte arrays.

String offsets, lengths, and search indices are byte-based. Functions that perform ASCII case conversion operate only on ASCII letters unless documented otherwise.

### Features

- Decimal and hexadecimal conversion for integers, addresses, and byte arrays
- `camelCase`, `PascalCase`, `CONSTANT_CASE`, `snake_case`, and `kebab-case` formatting
- ASCII lowercase and uppercase conversion
- Concatenation, joining, splitting, replacement, repetition, and padding
- Byte-oriented slicing, truncation, and whitespace trimming
- Forward, backward, and multi-match substring searching
- Prefix, suffix, and containment checks
- Equality and lexicographical comparison
- Parallel string and dynamic byte-array APIs where operations are semantically equivalent
- Memory-safe assembly implementations with direct output construction
- Fuzz and differential testing with Foundry

### Design

The libraries operate on byte sequences rather than Unicode code points.

For `string` operations:

- offsets, lengths, and indices are expressed in bytes rather than Unicode characters;
- slicing may therefore split a multi-byte UTF-8 sequence;
- `toLowerCase` and `toUpperCase` modify ASCII letters only;
- `formatCase` accepts printable ASCII (`0x20` through `0x7e`), normalizes spaces, hyphens, and underscores as separators, and preserves other punctuation;
- whitespace trimming recognizes ASCII horizontal tab, line feed, vertical tab, form feed, carriage return, and space.

Functions that allocate output construct it directly at the free-memory pointer where practical. `truncate` is an exception: it shortens the original memory object in place and therefore aliases the input.

### Repository Structure

```text
solidity-dynamics/
├── src/
│   ├── BytesUtils.sol
│   └── StringUtils.sol
├── test/
│   ├── bytes/
│   │   ├── comparison/
│   │   ├── construction/
│   │   ├── searching/
│   │   └── slicing/
│   ├── string/
│   │   ├── comparison/
│   │   ├── construction/
│   │   ├── conversion/
│   │   ├── formatting/
│   │   ├── searching/
│   │   └── slicing/
│   └── Base.t.sol
└── foundry.toml
```

## Installation

> [!IMPORTANT]
> This library uses Cancun EVM features such as `MCOPY` and must be compiled for the Cancun EVM or later. When using Foundry, set `evm_version = "cancun"` or later.

To install with [Foundry](https://www.getfoundry.sh/introduction/installation):

```sh
forge install fomoweth/solidity-dynamics
```

Alternatively, to install as a [Git submodule](https://git-scm.com/docs/git-submodule):

```sh
git submodule add https://github.com/fomoweth/solidity-dynamics.git lib/solidity-dynamics
```

Add the following remapping:

```text
solidity-dynamics/=lib/solidity-dynamics/src/
```

Then import the libraries as needed:

```solidity
import {BytesUtils} from "solidity-dynamics/BytesUtils.sol";
import {StringUtils} from "solidity-dynamics/StringUtils.sol";
```

## Usage

### String Utilities

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StringUtils} from "solidity-dynamics/StringUtils.sol";

contract Example {
    using StringUtils for string;

    function capitalize(string memory subject) external pure returns (string memory) {
        return string.concat(subject.slice(0, 1).toUpperCase(), subject.slice(1));
    }

    function normalize(string memory subject) external pure returns (string memory) {
        return subject.trim().formatCase(StringUtils.CaseType.Camel);
    }
}
```

### Byte Utilities

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BytesUtils} from "solidity-dynamics/BytesUtils.sol";

contract Example {
    using BytesUtils for bytes;
    using BytesUtils for bytes[];

    function contains(bytes memory subject, bytes memory needle) external pure returns (bool) {
        return subject.contains(needle);
    }

    function concat(bytes[] memory segments) external pure returns (bytes memory) {
        return segments.concat();
    }

    function slice(bytes memory subject, uint256 offset, uint256 length) external pure returns (bytes memory) {
        return subject.slice(offset, length);
    }
}
```

### Advanced Examples

Parsing a structured ERC-7579 smart account ID using `split` and `join`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StringUtils} from "solidity-dynamics/StringUtils.sol";

library AccountIdLib {
    using StringUtils for string;
    using StringUtils for string[];

    /// @notice Returns the vendor name, account name, and semantic version.
    /// @param accountId The structured ID in the format `vendorname.accountname.semver`.
    /// @return vendor The vendor name.
    /// @return name The account name.
    /// @return version The semantic version.
    function parse(string memory accountId)
        internal
        pure
        returns (string memory vendor, string memory name, string memory version)
    {
        string[] memory segments = accountId.split(".");
        require(segments.length >= 3);

        require(bytes(vendor = segments[0]).length != 0);
        require(bytes(name = segments[1]).length != 0);

        unchecked {
            uint256 length = segments.length - 2;
            for (uint256 i = 0; i < length; ++i) {
                segments[i] = segments[i + 2];
            }
        }

        assembly ("memory-safe") {
            mstore(segments, length)
        }

        require(bytes(version = segments.join(".")).length != 0);
    }
}
```

Parsing a structured ERC-7579 smart account ID using `indexOf` and `slice`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {EIP712} from "solady/utils/EIP712.sol";
import {StringUtils} from "solidity-dynamics/StringUtils.sol";

contract ERC7579Account is EIP712 {
    using StringUtils for string;

    function accountId() public pure virtual returns (string memory) {
        return "fomoweth.vortex.0.0.1-alpha";
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name, string memory version)
    {
        string memory id = accountId();

        uint256 nameOffset = id.indexOf(".");
        require(nameOffset != type(uint256).max);

        uint256 versionOffset = id.indexOf(".", ++nameOffset);
        require(versionOffset != type(uint256).max);

        name = id.slice(nameOffset, versionOffset - nameOffset); // "vortex"
        name = string.concat(name.slice(0, 1).toUpperCase(), name.slice(1)); // "Vortex"
        version = id.slice(++versionOffset); // "0.0.1-alpha"
    }
}
```

## Testing

Run the complete test suite:

```sh
forge test
```

Run with detailed traces:

```sh
forge test -vvv
```

Run a specific test file:

```sh
forge test --match-path test/string/formatting/StringUtils.formatCase.t.sol
```

Run a specific test contract:

```sh
forge test --match-contract StringUtilsFormatCaseTest
```

Run a specific test:

```sh
forge test --match-test test_fuzz_formatCase_differential
```

Combine filters:

```sh
forge test \
    --match-contract StringUtilsFormatCaseTest \
    --match-test test_fuzz_formatCase_differential
```

## API Reference

The tables below summarize the available APIs. See the source-level NatSpec in [`StringUtils.sol`](./src/StringUtils.sol) and [`BytesUtils.sol`](./src/BytesUtils.sol) for detailed behavior and edge-case semantics.

### StringUtils.sol

#### Conversion

| Function                               | Description                                                                                                |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `toString(uint256)`                    | Converts an unsigned integer to its ASCII decimal representation.                                          |
| `toString(int256)`                     | Converts a signed integer to its ASCII decimal representation.                                             |
| `toHexString(uint256,uint256,bool)`    | Converts an unsigned integer to a fixed-width lowercase hexadecimal string with an optional `0x` prefix.   |
| `toHexString(uint256,uint256)`         | Converts an unsigned integer to a fixed-width lowercase hexadecimal string with the `0x` prefix.           |
| `toHexStringNoPrefix(uint256,uint256)` | Converts an unsigned integer to a fixed-width lowercase hexadecimal string without the `0x` prefix.        |
| `toHexString(uint256,bool)`            | Converts an unsigned integer to a minimal-width lowercase hexadecimal string with an optional `0x` prefix. |
| `toHexString(uint256)`                 | Converts an unsigned integer to a minimal-width lowercase hexadecimal string with the `0x` prefix.         |
| `toHexStringNoPrefix(uint256)`         | Converts an unsigned integer to a minimal-width lowercase hexadecimal string without the `0x` prefix.      |
| `toHexString(address,bool,bool)`       | Converts an address to hexadecimal with an optional `0x` prefix and optional EIP-55 checksum casing.       |
| `toHexString(address)`                 | Converts an address to lowercase hexadecimal with the `0x` prefix and without checksum casing.             |
| `toHexStringChecksummed(address)`      | Converts an address to hexadecimal with the `0x` prefix and EIP-55 checksum casing.                        |
| `toHexStringNoPrefix(address)`         | Converts an address to lowercase hexadecimal without the `0x` prefix or checksum casing.                   |
| `toHexString(bytes,bool)`              | Converts a byte array to lowercase hexadecimal with an optional `0x` prefix.                               |
| `toHexString(bytes)`                   | Converts a byte array to lowercase hexadecimal with the `0x` prefix.                                       |
| `toHexStringNoPrefix(bytes)`           | Converts a byte array to lowercase hexadecimal without the `0x` prefix.                                    |

#### Formatting

| Function                      | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| `formatCase(string,CaseType)` | Formats a string according to the specified case convention. |
| `toLowerCase(string)`         | Converts all ASCII letters in a string to lowercase.         |
| `toUpperCase(string)`         | Converts all ASCII letters in a string to uppercase.         |

Supported case conventions:

```solidity
enum CaseType {
    Camel,
    Pascal,
    Constant,
    Snake,
    Kebab
}
```

#### Construction

| Function                          | Description                                                                             |
| --------------------------------- | --------------------------------------------------------------------------------------- |
| `concat(string[])`                | Concatenates a sequence of strings.                                                     |
| `join(string[],string)`           | Joins a sequence of strings with a delimiter between adjacent elements.                 |
| `split(string,string)`            | Splits a string on non-overlapping occurrences of a delimiter.                          |
| `replace(string,string,string)`   | Replaces every non-overlapping occurrence of a substring within a string.               |
| `repeat(string,uint256)`          | Repeats a string a specified number of times.                                           |
| `padStart(string,string,uint256)` | Left-pads a string to a minimum byte length using cyclic repetitions of a fill string.  |
| `padEnd(string,string,uint256)`   | Right-pads a string to a minimum byte length using cyclic repetitions of a fill string. |

#### Slicing

| Function                        | Description                                                                      |
| ------------------------------- | -------------------------------------------------------------------------------- |
| `slice(string,uint256,uint256)` | Extracts a substring from a specified byte offset with a maximum byte length.    |
| `slice(string,uint256)`         | Extracts a substring from a specified byte offset through the end of the string. |
| `truncate(string,uint256)`      | Shortens a string in place to at most a specified number of bytes.               |
| `trim(string,bool,bool)`        | Removes ASCII whitespace from the selected ends of a string.                     |
| `trim(string)`                  | Removes leading and trailing ASCII whitespace from a string.                     |
| `trimStart(string)`             | Removes leading ASCII whitespace from a string.                                  |
| `trimEnd(string)`               | Removes trailing ASCII whitespace from a string.                                 |

#### Searching

| Function                             | Description                                                                                      |
| ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `indexOf(string,string,uint256)`     | Finds the byte index of the first occurrence of a substring at or after a specified byte offset. |
| `indexOf(string,string)`             | Finds the byte index of the first occurrence of a substring.                                     |
| `lastIndexOf(string,string,uint256)` | Finds the byte index of the last occurrence of a substring at or before a specified byte offset. |
| `lastIndexOf(string,string)`         | Finds the byte index of the last occurrence of a substring.                                      |
| `indicesOf(string,string)`           | Finds the byte indices of all non-overlapping occurrences of a substring.                        |
| `contains(string,string,uint256)`    | Determines whether a substring occurs at or after a specified byte offset.                       |
| `contains(string,string)`            | Determines whether a string contains a substring.                                                |
| `startsWith(string,string)`          | Determines whether a string begins with a substring.                                             |
| `endsWith(string,string)`            | Determines whether a string ends with a substring.                                               |

#### Comparison

| Function             | Description                                           |
| -------------------- | ----------------------------------------------------- |
| `eq(string,string)`  | Compares two strings for byte-for-byte equality.      |
| `cmp(string,string)` | Compares two strings lexicographically by byte value. |

### BytesUtils.sol

#### Construction

| Function                     | Description                                                                       |
| ---------------------------- | --------------------------------------------------------------------------------- |
| `concat(bytes[])`            | Concatenates a sequence of byte arrays.                                           |
| `join(bytes[],bytes)`        | Joins a sequence of byte arrays with a delimiter between adjacent elements.       |
| `split(bytes,bytes)`         | Splits a byte array on non-overlapping occurrences of a delimiter.                |
| `replace(bytes,bytes,bytes)` | Replaces every non-overlapping occurrence of a byte sequence within a byte array. |
| `repeat(bytes,uint256)`      | Repeats a byte array a specified number of times.                                 |

#### Slicing

| Function                       | Description                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| `slice(bytes,uint256,uint256)` | Extracts a byte array from a specified byte offset with a maximum byte length.        |
| `slice(bytes,uint256)`         | Extracts a byte array from a specified byte offset through the end of the byte array. |
| `truncate(bytes,uint256)`      | Shortens a byte array in place to at most a specified number of bytes.                |

#### Searching

| Function                           | Description                                                                                          |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `indexOf(bytes,bytes,uint256)`     | Finds the byte index of the first occurrence of a byte sequence at or after a specified byte offset. |
| `indexOf(bytes,bytes)`             | Finds the byte index of the first occurrence of a byte sequence.                                     |
| `lastIndexOf(bytes,bytes,uint256)` | Finds the byte index of the last occurrence of a byte sequence at or before a specified byte offset. |
| `lastIndexOf(bytes,bytes)`         | Finds the byte index of the last occurrence of a byte sequence.                                      |
| `indicesOf(bytes,bytes)`           | Finds the byte indices of all non-overlapping occurrences of a byte sequence.                        |
| `contains(bytes,bytes,uint256)`    | Determines whether a byte sequence occurs at or after a specified byte offset.                       |
| `contains(bytes,bytes)`            | Determines whether a byte array contains a byte sequence.                                            |
| `startsWith(bytes,bytes)`          | Determines whether a byte array begins with a byte sequence.                                         |
| `endsWith(bytes,bytes)`            | Determines whether a byte array ends with a byte sequence.                                           |

#### Comparison

| Function           | Description                                               |
| ------------------ | --------------------------------------------------------- |
| `eq(bytes,bytes)`  | Compares two byte arrays for byte-for-byte equality.      |
| `cmp(bytes,bytes)` | Compares two byte arrays lexicographically by byte value. |

## Acknowledgements

This project was inspired and informed by:

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) — [`Strings.sol`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol) and [`Bytes.sol`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Bytes.sol)
- [Solady](https://github.com/Vectorized/solady) — [`LibString.sol`](https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol) and [`LibBytes.sol`](https://github.com/Vectorized/solady/blob/main/src/utils/LibBytes.sol)

## License

Licensed under the [MIT License](./LICENSE).
