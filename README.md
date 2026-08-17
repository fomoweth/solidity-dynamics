# solidity-dynamics

## Table of Contents

- [Overview](#overview)
    - [Repository Structure](#repository-structure)
    - [Features](#features)
- [Usage](#usage)
    - [Installation](#installation)
    - [Test](#test)
    - [Examples](#examples)
- [API Reference](#api-reference)
    - [BytesUtils.sol](#bytesutilssol)
    - [StringUtils.sol](#stringutilssol)

## Overview

### Repository Structure

All contracts are held within the `solidity-dynamics/src` folder.

```text
solidity-dynamics/
├── src/
│   ├── BytesUtils.sol
│   └── StringUtils.sol
├── test/
│   ├── bytes/
│   │   ├── .../
│   │   └── .../
│   ├── string/
│   │   ├── .../
│   │   └── .../
│   └── Base.t.sol
└── foundry.toml
```

### Features

## Usage

### Installation

Using [**Foundry**](https://www.getfoundry.sh/introduction/getting-started):

```sh
forge install fomoweth/solidity-dynamics
```

Using [**Git Submodules**](https://git-scm.com/docs/git-submodule):

```sh
git submodule add https://github.com/fomoweth/solidity-dynamics.git lib/solidity-dynamics
```

Add `solidity-dynamics/=lib/solidity-dynamics/src/` in `remappings.txt`.

```solidity
import {BytesUtils} from "solidity-dynamics/BytesUtils.sol";
import {StringUtils} from "solidity-dynamics/StringUtils.sol";

contract MyContract {}
```

### Test

```sh
# Run all tests
forge test

# Run all tests with detailed traces
forge test -vvv

# Run specific tests by path:
forge test --match-path test/StringUtils.toHexString.t.sol

# Run specific tests by contract:
forge test --match-contract StringUtilsToHexStringAddressTest

# Run specific tests by test name:
forge test --match-test test_toHexString_eip55Vectors

# Run specific tests by combined filters:
forge test --match-path test/StringUtils.toHexString.t.sol --match-contract StringUtilsToHexStringAddressTest
```

### Examples

Parsing the structured account ID of the ERC-7579 smart account using `split` and `join`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StringUtils} from "solidity-dynamics/StringUtils.sol";

library AccountIdLib {
    using StringUtils for string;
    using StringUtils for string[];

	/// @notice Returns the vendor name, account name, and semantic version as strings
	/// @param accountId The structured ID in the format "vendorname.accountname.semver"
	/// @return vendor The vendor name of the smart account
	/// @return name The account name of the smart account
	/// @return version The semantic version of the smart account
    function parse(string memory accountId)
        internal
        pure
        returns (string memory vendor, string memory name, string memory version)
    {
        string[] memory segments = accountId.split(".");
        require(segments.length > 2);

        require(bytes(vendor = segments[0]).length != 0);
        require(bytes(name = capitalize(segments[1])).length != 0);

        uint256 length = segments.length - 2;
        for (uint256 i = 0; i < length; ++i) {
            segments[i] = segments[i + 2];
        }

        assembly ("memory-safe") {
            mstore(segments, length)
        }

        require(bytes(version = segments.join(".")).length != 0);
    }

    function capitalize(string memory str) internal pure returns (string memory) {
        return string.concat(str.slice(0, 1).toUpperCase(), str.slice(1));
    }
}
```

_Parsing the structured account ID of the ERC-7579 smart account using `indexOf` and `slice`._

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

## API Reference

### BytesUtils.sol

### StringUtils.sol
