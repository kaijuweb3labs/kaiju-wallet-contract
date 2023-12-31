// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./NewSafeStorage.sol";
import "./IOldSafeStorage.sol";
/**
 * @title Migration - Migrates a Safe contract from 1.3.0 to 1.2.0
 * @author Richard Meissner - @rmeissner
 */
contract Migration is NewSafeStorage {
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    address public immutable migrationSingleton;
    address public immutable safe120Singleton;

    constructor(address targetSingleton,address _migrationSingleton) {
        // Singleton address cannot be zero address.
        require(targetSingleton != address(0), "Invalid singleton address provided");
        safe120Singleton = targetSingleton;
        migrationSingleton = _migrationSingleton;
    }

    event ChangedMasterCopy(address singleton);

    /**
     * @notice Migrates the Safe to the Singleton contract at `migrationSingleton`.
     * @dev This can only be called via a delegatecall.
     */
    function migrate() public {
        require(address(this) != migrationSingleton, "Migration should only be called via delegatecall");
        uint256 tt =  IOldSafeStorage(address(this)).getThreshold();
        singleton = safe120Singleton;
        mainOwner = IOldSafeStorage(address(this)).getOwners()[0];
        threshold = tt;
        _deprecatedDomainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        emit ChangedMasterCopy(singleton);
    }
}