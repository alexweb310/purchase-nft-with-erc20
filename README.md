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

```solidity
contract Nft is ERC721, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public immutable priceForNft;
    uint256 public totalSupply;
}
```

We declare of `Nft` contract and inherit from the `ERC721` and `Ownable` contracts that we imported above.

On the first line of the contract, the line `using SafeERC20 for IERC20;` allows us to attach member functions from the `SafeERC20` library to our IERC20 variable.

We then proceed to declare 3 state variables, `asset` being the ERC20 token that will be paid in order to mint an NFT, `priceForNft` will be the price for minting 1 NFT, and `totalSupply` will be used both for keeping track of the total of NFTs minted, as well as the ids for the individual mints.

```solidity
event NftMinted(address indexed owner, uint256 indexed tokenId);
event FundsWithdrawn(address indexed owner, uint256 amount);

error ZeroAddressToken();
error ZeroPrice();
```

Next, we declare 2 events, `NftMinted` and `FundsWithdrawn` that will each be emitted from a function we will write below. We also declare 2 custom errors, `ZeroAddressToken()` and `ZeroPrice()` to help with validating the inputs for the functions.

```solidity
constructor(address _asset, uint256 _priceForNft) 
    ERC721("Top Token", "TopTKN") 
    Ownable(msg.sender)
    {
        require(_asset != address(0), ZeroAddressToken());
        require(_priceForNft != 0, ZeroPrice());

        asset = IERC20(_asset);
        priceForNft = _priceForNft;
    }
```

Lets move on to the `constructor` now. It has 2 parameters, `_asset` and `_priceForNft`, which we validate to make sure are not of value zero. We also make use of the 2 errors defined above. As you can see, we invoke the constructors of the `ERC721` and `Ownable` contracts that our `Nft` contract inherited from. We pass hardcoded values for the name and symbol of the NFT in this case. As for the owner, we passed the `msg.sender` address, which means the owner will be the address that deploys this contract.

```solidity
function mint() external {
    asset.safeTransferFrom(msg.sender, address(this), priceForNft);
    uint256 _totalSupply = totalSupply;

    totalSupply++;
    emit NftMinted(msg.sender, _totalSupply);

    _safeMint(msg.sender, _totalSupply);
}
```

Now lets start writing our functions. We'll start with the `mint()` funcion, which, as the name suggests, allows a user to mint an NFT for himself. As you can see on the first line of the function, we use the `safeTransferFrom` function to transfer the ERC20 token from the user to the contract. This means that before the `mint()` function is called, the user has to have already approved the `Nft` contract to transfer some if the user's tokens (at least "priceForNft" amount of tokens).  
We then cache the totalSupply in the `_totalSupply` variable. We then increment the `totalSupply`, emit the `NftMinted` event and call the `_safeMint` function to mint the NFT for the user. Note that we pass the `_totalSupply` as an argument, so the first tokenId will be `0`.  

Note that, `_safeMint` will check if the receiver is a contract, and if it is, will make sure that it can handle NFTs by calling a special function on the receiver contract and expecting it to return a certain value.

```solidity
function withdrawAsset(uint256 amount) external onlyOwner {
    asset.safeTransfer(msg.sender, amount);
    emit FundsWithdrawn(msg.sender, amount);
}
```
Now we will take care of the `withdrawAsset` function which allows the owner of the contract to retrieve the ERC20 tokens that the user paid to mint their NFTs. Note that only the owner of the contract can call this function, since we annotated it with the `onlyOwner` modifier.  
The function itself if pretty simple, the owner transfer an amount of tokens from the contract to himself (obviously, the amount has to be less than or equal to the total amount of tokens the contract has). It also emits the `FundsWithdrawn` event.

```solidity
function _baseURI() internal pure override returns (string memory) {
    return "ipfs://.../";
}
```
For the last function of our contract, we are going to override the `_baseURI()` function from the Open Zeppelin ERC721 implementation. We make it return an `ipfs` hash (of course, in this case it's just a placeholder). When someone calls the ERC721 function `tokenURI(uint256 tokenId)` (with a `tokenId` that exists), the `tokenURI` function will concatenate the return value of `_baseURI()` and append the `tokenId` to URI.

And that's pretty much it! Below, you can see the entire contract. I recommend that you check out the tests as well (see the `test` folder, there is 100% coverage).

```solidity
// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Nft is ERC721, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public immutable priceForNft;
    uint256 public totalSupply;

    event NftMinted(address indexed owner, uint256 indexed tokenId);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    error ZeroAddressToken();
    error ZeroPrice();

    constructor(address _asset, uint256 _priceForNft)
        ERC721("Top Token", "TopTKN")
        Ownable(msg.sender)
    {
        require(_asset != address(0), ZeroAddressToken());
        require(_priceForNft != 0, ZeroPrice());

        asset = IERC20(_asset);
        priceForNft = _priceForNft;
    }

    function mint() external {
        asset.safeTransferFrom(msg.sender, address(this), priceForNft);
        uint256 _totalSupply = totalSupply;

        totalSupply++;
        emit NftMinted(msg.sender, _totalSupply);

        _safeMint(msg.sender, _totalSupply);
    }

    function withdrawAsset(uint256 amount) external onlyOwner {
        asset.safeTransfer(msg.sender, amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://.../";
    }
}

```