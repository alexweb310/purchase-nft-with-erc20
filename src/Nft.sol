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

    constructor(address _asset, uint256 _priceForNft) ERC721("Top Token", "TopTKN") Ownable(msg.sender) {
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
