// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {Floork} from '../src/RageQuit.sol';
import {ERC20Mock} from './mocks/ERC20Mock.sol';

contract FloorkTest is Test {

    /// Our funding tokens
    ERC20Mock floor;
    Floork floork;

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
        vm.expectRevert('ERC20: burn amount exceeds balance');
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
        floork.initialize();
    }

    function test_CannotReinitializeAsOwner() public {
        floork.initialize();

        vm.expectRevert('Initializable: contract is already initialized');
        floork.initialize();
    }

    function test_CannotInitializeAsNonOwner(address caller) public {
        vm.assume(caller != address(this));

        vm.prank(caller);
        vm.expectRevert('Ownable: caller is not the owner');
        floork.initialize();
    }

    function test_CannotSendEthToContract(uint amount) public {
        vm.assume(amount != 0);

        (bool success,) = address(floork).call{value: amount}('');
        assertFalse(success);
    }

    function assumeFloorAmountRange(uint amount) internal pure {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint).max / (10 ** 9));
    }

    modifier mintFloorTokens(uint amount) {
        floor.mint(address(this), amount);
        _;
    }

}
