// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ConfirmationContract {
    /// The user's address who is signing the data
    address public signer;

    /// The data that will be displayed to the end user
    bytes public dataToConfirm;

    /// The EIP-712 domain separator
    bytes32 public DOMAIN_SEPARATOR;

    /// Struct to represent the data to be signed
    struct Confirmation {
        bytes dataToConfirm;
    }

    constructor(address _signer, bytes memory _message) {
    	// Set our contract variables
    	signer = _signer;
    	dataToConfirm = _message;

        // Initialize the domain separator with a unique value
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ConfirmationContract")),
                keccak256(bytes("1")), // Contract version
                block.chainid,
                address(this)
            )
        );
    }

    // Function to confirm data using a gasless signature
    function confirmData(bytes memory signature, bytes memory _dataToConfirm) external view returns (bool) {
    	require(msg.sender == signer, 'Invalid signer');

        Confirmation memory confirmation = Confirmation(_dataToConfirm);
        return verifySignature(signer, signature, confirmation);
    }

    // Function to verify a user's signature
    function verifySignature(address _signer, bytes memory signature, Confirmation memory confirmation) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    keccak256("Confirmation(bytes dataToConfirm)"),
                    confirmation.dataToConfirm
                ))
            )
        );
        return _signer == ecrecover(digest, uint8(signature[0]), bytes32(bytes20(_signer)), bytes32(bytes20(_signer)));
    }

}
