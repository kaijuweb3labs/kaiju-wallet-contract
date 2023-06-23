// SPDX-License-Identifier: LGPL-3.0-only
/// @author kaiju3d.com

pragma solidity >=0.7.0 <0.9.0;

contract ModuleMetadata {
    string public constant NAME = "Kaiju Social Recovery Module";
    string public constant VERSION = "0.0.1";
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256("ExecuteRecovery(address wallet,address[] newOwners,uint256 newThreshold,uint256 nonce)");
    bytes32 public constant EXECUTE_RECOVERY_TYPEHASH =
        0x124b64921a7c7e677c6cc3b132eaaa57130bc6fc05ab157f35fe5264a7c198d5;

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR_TYPEHASH,
                    keccak256(abi.encodePacked(NAME)),
                    keccak256(abi.encodePacked(VERSION)),
                    getChainId(),
                    this
                )
            );
    }
}
