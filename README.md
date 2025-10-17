## Purchase NFT with ERC20

***In this article I teach you how to create an NFT that can be minted by paying with an ERC20 token.***

You will need to have Foundry installed (instructions below).
```shell
# Download foundry installer `foundryup`
curl -L https://foundry.paradigm.xyz | bash
# Install forge, cast, anvil, chisel
foundryup
# Install the latest nightly release
foundryup -i nightly
```

For more details, visit: https://getfoundry.sh/

First, open the terminal and type `forge init`. This will initialize a new Foundry project and once that's done, run the command `forge intsall OpenZeppelin/openzeppelin-contracts` to install the Open Zeppelin dependencies that we will make use of in this project.  
Next, delete the default `Counter` files in the `script`, `src` and `test` folders and create a file named `Nft.sol`. Open the newly created file in your code editor.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;
```
The first line of the file should contain a comment representing the linces. Below that, use the `pragma` keyword to specify which compiler version should be used for this file. Keep in mind that version pragma does not change the version of the compiler. It does not enable or disable features of the compiler either. It only instructs the compiler to check if its version matches the one required by the pragma, and if it does not, the compiler will issue an error.

```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
```
Now, we will bring the dependencies we need into scope:

- ERC721 - our NFT contract will inherit from this
- IERC20 - interface to tranfer the ERC20 token
- Ownable - gain access to the `onlyOwner` modifier to protect certain functions that should only be called by authorized addresses
- SafeERC20 - library that enables us to handle more implementations of ERC20 (some tokens revert on failure, others do not return a boolean at all)

Now we can start writing the main contract
