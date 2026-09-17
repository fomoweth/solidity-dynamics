# solidity-dynamics

[![Test](https://github.com/fomoweth/solidity-dynamics/actions/workflows/test.yml/badge.svg)](https://github.com/fomoweth/solidity-dynamics/actions/workflows/test.yml)
[![Docs](https://img.shields.io/badge/Docs-online-blue)](https://fomoweth.github.io/solidity-dynamics)
[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.25-2b247c)](https://docs.soliditylang.org/en/v0.8.25)
[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](https://opensource.org/licenses/MIT)

> Low-level Solidity utilities for string and bytes manipulation.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [String Utilities](#string-utilities)
  - [Bytes Utilities](#bytes-utilities)
  - [Advanced Examples](#advanced-examples)
- [Design Notes](#design-notes)
  - [Byte-Oriented Semantics](#byte-oriented-semantics)
  - [ASCII Semantics](#ascii-semantics)
  - [Memory Model](#memory-model)
  - [EVM Compatibility](#evm-compatibility)
- [API Reference](#api-reference)
- [Development](#development)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Overview

`solidity-dynamics` provides low-level utilities for working with `string` and `bytes` values in Solidity.

The library exposes two primary components:

- [StringUtils](src/StringUtils.sol) — String conversion, formatting, searching, slicing, comparison, and manipulation.
- [BytesUtils](src/BytesUtils.sol) — Dynamic byte-array operations with equivalent semantics where applicable.

The implementation uses byte-oriented operations, direct memory manipulation, and modern EVM primitives.

## Features

- **String conversion** — Decimal and hexadecimal formatting for integers, addresses, and byte arrays.
- **Case formatting** — `camelCase`, `PascalCase`, `CONSTANT_CASE`, `snake_case`, and `kebab-case`.
- **Construction** — Concatenation, joining, replacement, repetition, and padding.
- **Searching** — Forward, backward, and multi-match substring searches.
- **Splitting and slicing** — Delimiter-based splitting and byte-oriented slicing.
- **Manipulation** — Truncation, trimming, and other in-memory transformations.
- **Comparison** — Equality, prefix, suffix, containment, and lexicographical comparison.
- **Parallel APIs** — Equivalent operations for `string` and `bytes` where their semantics align.
- **Low-level implementation** — Direct memory construction, memory-safe assembly, and `MCOPY`-based copying.

## Requirements

- [Foundry](https://getfoundry.sh/)
- Solidity `^0.8.25`
- Cancun EVM or later

> [!IMPORTANT]
> `solidity-dynamics` uses Cancun EVM features such as `MCOPY` and must target the Cancun EVM or later.

## Installation

Install the library with Foundry:

```bash
forge install fomoweth/solidity-dynamics
```

Add the following remapping to `foundry.toml` or `remappings.txt`:

```text
solidity-dynamics/=lib/solidity-dynamics/src/
```

Import the utilities you need:

```solidity
import {StringUtils} from "solidity-dynamics/StringUtils.sol";
import {BytesUtils} from "solidity-dynamics/BytesUtils.sol";
```

## Usage

### String Utilities

Use `StringUtils` as an extension library for `string` values:

```solidity
using StringUtils for string;

string memory value = "  hello solidity  ";

string memory trimmed = value.trim(); // "hello solidity"
bool contains = value.contains("solidity"); // true
string memory sliced = value.slice(8, 8); // "solidity"
```

Convert common Solidity values to their string representations:

```solidity
string memory decimal = StringUtils.toString(12345); // "12345"
string memory hexadecimal = StringUtils.toHexString(0x1234); // "0x1234"
string memory self = StringUtils.toHexString(address(this));
```

Format strings into common ASCII case conventions:

```solidity
using StringUtils for string;

string memory value = "hello solidity";

string memory camel = value.formatCase(StringUtils.CaseType.Camel); // "helloSolidity"
string memory pascal = value.formatCase(StringUtils.CaseType.Pascal); // "HelloSolidity"
string memory const = value.formatCase(StringUtils.CaseType.Constant); // "HELLO_SOLIDITY"
string memory snake = value.formatCase(StringUtils.CaseType.Snake); // "hello_solidity"
string memory kebab = value.formatCase(StringUtils.CaseType.Kebab); // "hello-solidity"
```

### Bytes Utilities

Use `BytesUtils` as an extension library for dynamic byte arrays:

```solidity
using BytesUtils for bytes;

bytes memory value = hex"deadbeef";

bool contains = value.contains(hex"beef"); // true
bytes memory sliced = value.slice(0, 2); // hex"dead"
bytes memory repeated = value.repeat(2); // hex"deadbeefdeadbeef"
```

`BytesUtils` provides the corresponding low-level operations directly on dynamic byte arrays without requiring conversion to `string`.

### Advanced Examples

#### Token-Oriented

A structured ERC-7579 smart account ID can be parsed token-by-token using `split` and `join`:

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

        uint256 length = segments.length - 2;
        for (uint256 i = 0; i < length; ++i) {
            segments[i] = segments[i + 2];
        }

        assembly ("memory-safe") {
            mstore(segments, length)
        }

        require(bytes(version = segments.join(".")).length != 0);
    }
}
```

#### Offset-Oriented

The same structure can be parsed using byte offsets with `indexOf` and `slice`:

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

## Design Notes

### Byte-Oriented Semantics

`solidity-dynamics` treats Solidity strings as byte sequences rather than Unicode code points or grapheme clusters.

Indices, offsets, and lengths used by searching, slicing, and related operations refer to byte positions. As a result, slicing a UTF-8 encoded string at arbitrary offsets may split a multi-byte character and produce invalid UTF-8.

This behavior follows Solidity's underlying representation of `string` as a dynamically sized byte sequence and avoids the additional decoding required for Unicode-aware operations.

### ASCII Semantics

Case conversion and formatting operate on ASCII characters.

Functions such as `toLowerCase`, `toUpperCase`, and `formatCase` do not perform Unicode-aware or locale-sensitive case conversion. Non-ASCII bytes are not interpreted as Unicode characters.

Whitespace-sensitive operations such as `trim` use a defined set of ASCII whitespace characters rather than Unicode whitespace semantics.

### Memory Model

Most transformation operations allocate and return new memory values without modifying their inputs.

Some operations intentionally reuse existing memory when their semantics permit it. In particular, `truncate` shortens a dynamic memory value in place by updating its length, so the returned value aliases the same memory object as the input.

Callers should account for this behavior when retaining multiple references to the same memory value.

### EVM Compatibility

The implementation uses Cancun EVM features, including [`MCOPY` (EIP-5656)](https://eips.ethereum.org/EIPS/eip-5656), for direct memory-to-memory copying.

Projects consuming `solidity-dynamics` must compile for the Cancun EVM or later.

## API Reference

The complete API reference, including all functions, overloads, and NatSpec documentation, is available in the generated documentation:

[View the API documentation](https://fomoweth.github.io/solidity-dynamics)

Generate the documentation locally with:

```bash
forge doc
```

To generate and serve it locally:

```bash
forge doc --serve
```

## Development

Clone the repository and install its dependencies:

```bash
git clone https://github.com/fomoweth/solidity-dynamics.git
cd solidity-dynamics
forge install
```

Build the project:

```bash
forge build
```

Run the test suite:

```bash
forge test
```

Format the codebase:

```bash
forge fmt
```

## Acknowledgements

Parts of the library’s design and implementation were inspired by established Solidity utility libraries in the broader ecosystem.

- [`Strings.sol`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol) from [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [`Bytes.sol`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Bytes.sol) from [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [`LibString.sol`](https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol) from [Solady](https://github.com/Vectorized/solady)
- [`LibBytes.sol`](https://github.com/Vectorized/solady/blob/main/src/utils/LibBytes.sol) from [Solady](https://github.com/Vectorized/solady)

## License

This project is licensed under the [MIT License](LICENSE).
