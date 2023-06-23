// SPDX-License-Identifier: GPL-3.0
/// @author kaiju3d.com

pragma solidity >=0.8.12 <0.9.0;

import "../storage/IGuardianStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@gnosis.pm/safe-contracts/contracts/Safe.sol";
import "./Authorized.sol";
import "./ModuleMetadata.sol";

contract RecoveryRequestManager is Authorized, ModuleMetadata {
    struct RecoveryRequest {
        uint256 guardiansApprovalCount;
        uint256 newThreshold;
        uint64 executeAfter;
        address[] newOwners;
    }
    event RecoveryExecuted(
        address indexed wallet,
        address[] indexed newOwners,
        uint256 newThreshold,
        uint256 nonce,
        uint64 executeAfter,
        uint256 guardiansApprovalCount
    );
    event RecoveryFinalized(
        address indexed wallet,
        address[] indexed newOwners,
        uint256 newThreshold,
        uint256 nonce
    );

    event RecoveryCanceled(address indexed wallet, uint256 nonce);

    mapping(address => RecoveryRequest) internal recoveryRequests;
    mapping(bytes32 => mapping(address => bool)) internal confirmedHashes;

    // Recovery period
    uint256 internal immutable recoveryPeriod;

    constructor(uint256 _recoveryPeriod) {
        recoveryPeriod = _recoveryPeriod;
    }

    /**
     * @notice Throws if there is no ongoing recovery request.
     */
    modifier whenRecovery(address _wallet) {
        require(
            recoveryRequests[_wallet].executeAfter > 0,
            "KSM02 no ongoing recovery"
        );
        _;
    }

    /**
     * @notice Throws if there is an ongoing recovery request.
     */
    modifier whenNotRecovery(address _wallet) {
        require(
            recoveryRequests[_wallet].executeAfter == 0,
            "KSM03 ongoing recovery"
        );
        _;
    }

    /// @dev Returns the bytes that are hashed to be signed by guardians.
    function encodeRecoveryData(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 recoveryHash = keccak256(
            abi.encode(
                EXECUTE_RECOVERY_TYPEHASH,
                _wallet,
                keccak256(abi.encodePacked(_newOwners)),
                _newThreshold,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator(),
                recoveryHash
            );
    }

    /// @dev Generates the recovery hash that should be signed by the guardian to authorize a recovery
    function getRecoveryHash(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        uint256 _nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                encodeRecoveryData(_wallet, _newOwners, _newThreshold, _nonce)
            );
    }

    function confirmRecoveryRequest(bytes32 recoveryHash) internal {
        confirmedHashes[recoveryHash][msg.sender] = true;
    }

    function hasConfirmedHashForGuardian(
        bytes32 recoveryHash,
        address _guardian
    ) internal view returns (bool) {
        return confirmedHashes[recoveryHash][_guardian];
    }

    function checkAndReplaceRecovery(
        address _wallet,
        uint256 _approvalCount,
        uint256 _nonce
    ) internal {
        // If an ongoing recovery exists, replace only if more guardians than the previous guardians have approved this replacement
        RecoveryRequest storage request = recoveryRequests[_wallet];
        if (request.executeAfter > 0) {
            require(
                _approvalCount > request.guardiansApprovalCount,
                "KSM19 not enough approvals for replacement"
            );
            delete recoveryRequests[_wallet];
            emit RecoveryCanceled(_wallet, _nonce - 1);
        }
    }

    function setRecoveryRequest(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        uint256 _approvalCount
    ) internal {
        uint64 executeAfter = uint64(block.timestamp + recoveryPeriod);
        recoveryRequests[_wallet] = RecoveryRequest(
            _approvalCount,
            _newThreshold,
            executeAfter,
            _newOwners
        );
    }

    function removeRecoveryRequest(address _wallet) internal {
        delete recoveryRequests[_wallet];
    }

    /**
     * @notice Retrieves the wallet's current ongoing recovery request.
     * @param _wallet The target wallet.
     * @return request The wallet's current recovery request
     */
    function getRecoveryRequest(
        address _wallet
    ) public view returns (RecoveryRequest memory request) {
        return recoveryRequests[_wallet];
    }
}
