// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Token} from "./mocks/Token.sol";
import {Nft} from "../src/Nft.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NftTest is Test {
    using SafeERC20 for Token;

    Nft public nft;
    Token public asset;

    address user = makeAddr("user");

    event NftMinted(address indexed owner, uint256 indexed tokenId);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    error ZeroAddressToken();
    error ZeroPrice();
    error OwnableUnauthorizedAccount(address);

    function setUp() public {
        asset = new Token();
        nft = new Nft(address(asset), 100 * 1 ether);

        asset.mint(1000 ether);
        asset.safeTransfer(user, 100 ether);
    }

    modifier makePurchase() {
        uint256 balanceBeforeMint = nft.balanceOf(user);
        assertEq(balanceBeforeMint, 0);

        vm.startPrank(user);
        asset.approve(address(nft), 100 ether);

        vm.expectEmit(true, true, true, true);
        emit NftMinted(user, 0);

        nft.mint();
        vm.stopPrank();
        _;
    }

    function testCanNotCreateContractWithZeroValueParameters() public {
        vm.expectRevert(ZeroAddressToken.selector);
        new Nft(address(0), 100 * 1 ether);

        vm.expectRevert(ZeroPrice.selector);
        new Nft(address(asset), 0);
    }

    function testMint() public makePurchase {
        uint256 balanceAfter = nft.balanceOf(user);
        assertEq(balanceAfter, 1);
    }

    function testMintForContract() public {
        uint256 balanceBeforeMint = nft.balanceOf(address(this));
        assertEq(balanceBeforeMint, 0);

        asset.approve(address(nft), 100 ether);

        nft.mint();

        uint256 balanceAfterMint = nft.balanceOf(address(this));
        assertEq(balanceAfterMint, 1);
    }

    function testOwnerCanWithdraw() public makePurchase {
        uint256 balanceOwnerBefore = asset.balanceOf(address(this));
        assertEq(balanceOwnerBefore, 900 ether);

        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(address(this), 100 ether);

        nft.withdrawAsset(100 ether);

        uint256 balanceOwnerAfter = asset.balanceOf(address(this));
        assertEq(balanceOwnerAfter, 1000 ether);
    }

    function testUserThatIsNotOwnerCanNotWithdraw(address notOwner) public makePurchase {
        vm.assume(notOwner != address(this));

        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, notOwner));
        nft.withdrawAsset(100 ether);
    }

    function testCorrectTokenURI() public makePurchase {
        string memory tokenURI = nft.tokenURI(0);
        assertEq(tokenURI, "ipfs://.../0");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
