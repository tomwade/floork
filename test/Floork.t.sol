// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {Floork} from '../src/Floork.sol';
import {ERC20Mock} from './mocks/ERC20Mock.sol';

contract FloorkTest is Test {

    /// Our funding tokens
    ERC20Mock floor;
    Floork floork;

    /// Expected OZ errors
    error AlreadyInitialized();
    error ERC20InsufficientBalance(address, uint, uint);
    error OwnableUnauthorizedAccount(address);

    constructor() {
        // Create 2 tokens that will fund our {Floork} contract
        floor = new ERC20Mock();
        floork = new Floork(address(floor));

        // Update our FLOOR token to be 9 decimals
        floor.setDecimals(9);
    }

    function test_CanBurnAndRedeemAfterStart(uint amount, uint time) public mintFloorTokens(amount) {
        // Ensure we don't send a zero token value
        assumeFloorAmountRange(amount);

        // Ensure we set the time within the activation window
        vm.assume(time <= 7 days);

        // Initialise our contract and then skip forward a set amount of time
        floork.initialize();
        vm.warp(block.timestamp + time);

        // Approve our tokens
        floor.approve(address(floork), amount);

        // When we try and call the `burnAndRedeem` function we should receive the same amount
        // of tokens in return.
        floork.burnAndRedeem(amount);

        // We should now hold 0 FLOOR tokens and `amount` of FLOORK tokens, with the FLOORK
        // amount multiplied by 9 decimals to accomodate accuracy conversion to 18 decimal).
        assertEq(floor.balanceOf(address(this)), 0);
        assertEq(floork.balanceOf(address(this)), amount * (10 ** 9));

        // We want to confirm that the `floork` contract holds no FLOOR, as it should have been
        // burnt. This will also be reflected in the change of total supply, which as we are
        // using a mock will want to be zero.
        assertEq(floor.totalSupply(), 0);
        assertEq(floor.balanceOf(address(floork)), 0);

        // The total supply of the FLOORK token should be the same as the initial `amount` as
        // it is minted on demand. The FLOORK contract should also not hold any tokens of
        // itself. We do, however, need to multiply the amount by 9 decimals to accomodate the
        // token decimal accuracy conversion.
        assertEq(floork.totalSupply(), amount * (10 ** 9));
        assertEq(floork.balanceOf(address(floork)), 0);
    }

    function test_CannotBurnAndRedeemBeforeStart(uint amount) public mintFloorTokens(amount) {
        // Ensure we don't send a zero token value
        assumeFloorAmountRange(amount);

        // Approve our tokens
        floor.approve(address(floork), amount);

        // When we try and call the `burnAndRedeem` function we should get an error to show
        // that the contract and activation period has not yet be initialised.
        vm.expectRevert('Function is not active');
        floork.burnAndRedeem(amount);
    }

    function test_CannotBurnAndRedeemAfterActivationPeriod(uint amount) public mintFloorTokens(amount) {
        // Ensure we don't send a zero token value
        assumeFloorAmountRange(amount);

        // Initialise our contract and then skip forward 7 days, as the activation period
        // will have then ended.
        floork.initialize();
        vm.warp(block.timestamp + 7 days + 1);

        // Approve our tokens
        floor.approve(address(floork), amount);

        // When we try and call the `burnAndRedeem` function we should get an error to show
        // that the activation period is over.
        vm.expectRevert('Active period is over');
        floork.burnAndRedeem(amount);
    }

    function test_CannotBurnAndRedeemMoreThanBalance(uint amount) public mintFloorTokens(amount) {
        // Ensure we don't send a zero token value
        assumeFloorAmountRange(amount);

        // Initialise our contract
        floork.initialize();

        // Approve our tokens
        floor.approve(address(floork), amount);

        // When we try and call the `burnAndRedeem` function we should get an error as we
        // don't have sufficient balanace.
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, address(this), amount, amount + 1));
        floork.burnAndRedeem(amount + 1);
    }

    function test_CannotBurnAndRedeemZeroTokens() public {
        // Initialise our contract
        floork.initialize();

        // Trying to redeem a zero value will result in revert
        vm.expectRevert('Cannot redeem zero tokens');
        floork.burnAndRedeem(0);
    }

    function test_CannotMintTokensAsOwner(uint amount) public {
        // @dev Cannot call `mint` as the function does not exist on contract
        // vm.expectRevert('error code 3');
        // floork.mint(address(this), amount);
    }

    function test_CanInitializeAsOwner() public {
        // Before initialisation, we should see that the contract is not active
        assertFalse(floork.isActive());
        assertEq(floork.activationEndTime(), 0);

        // We can then initialise the contract, which will activate the functionality
        floork.initialize();
        assertTrue(floork.isActive());
        assertEq(floork.activationEndTime(), block.timestamp + 7 days);
    }

    function test_CannotReinitializeAsOwner() public {
        floork.initialize();

        // When we try to initialize another time, we should expect a revert
        vm.expectRevert(AlreadyInitialized.selector);
        floork.initialize();
    }

    function test_CannotInitializeAsNonOwner(address caller) public {
        // Ensure that the caller is not this test address, as it's the owner
        vm.assume(caller != address(this));

        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, caller));
        floork.initialize();
    }

    function test_CannotSendEthToContract(uint amount) public {
        // Any amount of ETH sent should be reverted
        (bool success,) = address(floork).call{value: amount}('');
        assertFalse(success);
    }

    function assumeFloorAmountRange(uint amount) internal pure {
        // Sets a possible amount value of 1 to the an amount that can be converted to
        // 18 decimal and still be within the uint max range. 
        vm.assume(amount > 0);
        vm.assume(amount < type(uint).max / (10 ** 9));
    }

    modifier mintFloorTokens(uint amount) {
        // Mint FLOOR tokens to our test contract
        floor.mint(address(this), amount);

        // Ensure we have the expected amount
        assertEq(floor.balanceOf(address(this)), amount);

        _;
    }

}
