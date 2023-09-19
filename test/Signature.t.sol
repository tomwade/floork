// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {ConfirmationContract} from '../src/Signature.sol';

contract ConfirmationContractTest is Test {

    /// Set our contract to test
    ConfirmationContract signature;

    /// Set our expected caller
    address CALLER;
    uint256 internal signerPrivateKey;
    bytes MESSAGE = 'Message to be signed';

    constructor() {
    	// Deploy our signature contract
        signature = new ConfirmationContract(CALLER, MESSAGE);

        // Generate a user from the private key
        signerPrivateKey = 0xabc123;
        CALLER = vm.addr(signerPrivateKey);
    }

    function test_CanSignFromAcceptedAddress() public {
    	string memory nonce = 'QSfd8gQE4WYzO29';

    	// https://book.getfoundry.sh/cheatcodes/sign
        vm.startPrank(CALLER);
        bytes32 digest = _toEthSignedMessageHash(keccak256(abi.encodePacked(CALLER, uint(0), nonce)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        bytes memory _signature = abi.encodePacked(r, s, v); // note the order here is different from line above.

        signature.confirmData(_signature, MESSAGE);
        vm.stopPrank();
    }

    function test_CannotSignFromUnknownAddress(uint256 unknownPrivateKey) public {
    	vm.assume(unknownPrivateKey != 0);
    	vm.assume(unknownPrivateKey != signerPrivateKey);

    	address unknown = vm.addr(unknownPrivateKey);
		string memory nonce = 'QSfd8gQE4WYzO29';

    	vm.startPrank(unknown);

        bytes32 digest = _toEthSignedMessageHash(keccak256(abi.encodePacked(unknown, uint(0), nonce)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(unknownPrivateKey, digest);
        bytes memory _signature = abi.encodePacked(r, s, v);

    	vm.expectRevert();
    	signature.confirmData(_signature, MESSAGE);

    	vm.stopPrank();
    }

    function _toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}
