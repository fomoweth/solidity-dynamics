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
```

### Examples

## API Reference

### BytesUtils.sol

### StringUtils.sol
