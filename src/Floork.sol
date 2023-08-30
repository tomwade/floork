// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Initializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import {IFLOOR} from './interfaces/IFLOOR.sol';

/**
 * Allows Floor holders that are wanting to exit their FloorDAO position to swap their
 * FLOOR token for a FLOORK token.
 *
 * This contract will act as the FLOORK ERC20 token.
 */
contract Floork is ERC20, Initializable, Ownable {
    /// Address of the FLOOR token address
    IFLOOR public floor;

    /// Boolean to show if the contract can be used
    bool public isActive;

    /// Timestamp before which token trades can be made
    uint public activationEndTime;

    /**
     * Defines our ERC20 token, sets up references and defines our initial supply.
     *
     * @param _floorToken The existing FLOOR token address
     */
    constructor(address _floorToken) ERC20('FloorDAO Fork', 'FLOORK') Ownable(msg.sender) {
        // Ensure that the provided FLOOR token is not a NULL address
        require(_floorToken != address(0), 'Floor token address cannot be zero');

        // Assign our FLOOR token address
        floor = IFLOOR(_floorToken);

        // Define our initial supply as zero
        _mint(msg.sender, 0);
    }

    /**
     * Sets up the contract by setting our trade end time and enables the contract swaps
     * to be interacted with for 7 days.
     */
    function initialize() public initializer onlyOwner {
        // Makes the contract active
        isActive = true;

        // Enables the contract swaps used for 7 days from call
        activationEndTime = block.timestamp + 7 days;
    }

    /**
     * Takes _x_ FLOOR tokens from the `msg.sender` and burns them. An equivalent number
     * of FLOORK tokens are then minted and sent to the `msg.sender`.
     *
     * @dev This function can only be called once the contract has been `initialized` and
     * it must be within the 7 day activation period.
     */
    function burnAndRedeem(uint floorAmount) external {
        // Ensures that called functions are only available when the contract has been
        // initialised and the active period is not over.
        require(isActive, 'Function is not active');
        require(block.timestamp <= activationEndTime, 'Active period is over');

        // Ensure that we have been provided with a non-zero number of tokens
        require(floorAmount != 0, 'Cannot redeem zero tokens');

        // Transfer the specified amount of floor tokens from the user to this contract
        floor.burnFrom(msg.sender, floorAmount);

        // Mint the equivalent amount of FLOORK tokens to the user, adjusting for
        // decimals since floor token is 9 decimals and FLOORK is 18 decimals.
        _mint(msg.sender, floorAmount * (10**9));
    }
}
