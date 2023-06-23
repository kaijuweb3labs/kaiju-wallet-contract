// SPDX-License-Identifier: GPL-3.0
/// @author kaiju3d.com

pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@gnosis.pm/safe-contracts/contracts/Safe.sol";
import "./storage/IGuardianStorage.sol";
import "./core/GuardianManager.sol";
import "./core/NonceManager.sol";
import "./core/RecoveryRequestManager.sol";

contract KaijuAccountRecoveryModule is
    GuardianManager,
    NonceManager,
    RecoveryRequestManager
{
    address internal constant SENTINEL_OWNERS = address(0x1);

    struct SignatureData {
        address signer;
        bytes signature;
    }

    constructor(
        IGuardianStorage _guardianStorage,
        uint256 _recoveryPeriod
    )
        GuardianManager(_guardianStorage)
        RecoveryRequestManager(_recoveryPeriod)
    {}

    /**
     * @notice Guardian should call this method to accept recovery request.
     * @param _wallet recovery wallet.
     * @param _newOwners new owner's of wallet.
     * @param _newThreshold The new owner threshold for safe transaction.
     * @param _execute Recovery process will execute if this parameter true and threshold is satisfied
     */
    function confirmRecovery(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        bool _execute
    ) external {
        require(isGuardian(_wallet, msg.sender), "KSM05 sender not a guardian");
        require(_newOwners.length > 0, "KSM06 owners cannot be empty");
        require(
            _newThreshold > 0 && _newOwners.length >= _newThreshold,
            "KSM07 invalid new threshold"
        );

        uint256 _nonce = getNonce(_wallet);
        bytes32 recoveryHash = keccak256(
            encodeRecoveryData(_wallet, _newOwners, _newThreshold, _nonce)
        );
        confirmedHashes[recoveryHash][msg.sender] = true;

        if (!_execute) return;
        uint256 guardiansThreshold = threshold(_wallet);
        uint256 _approvalCount = getRecoveryApprovals(
            _wallet,
            _newOwners,
            _newThreshold
        );
        require(
            _approvalCount >= guardiansThreshold,
            "KSM08 confirmed signatures less than threshold"
        );
        _executeRecovery(_wallet, _newOwners, _newThreshold, _approvalCount);
    }

    /**
     * @notice Accept all guardian recovery requests at once
     * @param _wallet recovery wallet.
     * @param _newOwners new owner's of wallet.
     * @param _newThreshold The new owner threshold for safe transaction.
     * @param _signatures The guardians signatures.
     * @param _execute Recovery process will execute if this parameter true and threshold is satisfied
     */
    function multiConfirmRecovery(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        SignatureData[] memory _signatures,
        bool _execute
    ) external {
        require(_newOwners.length > 0, "KSM09 owners cannot be empty");
        require(
            _newThreshold > 0 && _newOwners.length >= _newThreshold,
            "KSM10 invalid new threshold"
        );
        require(_signatures.length > 0, "KSM11 empty signatures");
        uint256 guardiansThreshold = threshold(_wallet);
        require(guardiansThreshold > 0, "KSM12 empty guardians");
        //
        uint256 _nonce = getNonce(_wallet);
        bytes32 recoveryHash = keccak256(
            encodeRecoveryData(_wallet, _newOwners, _newThreshold, _nonce)
        );
        address lastSigner = address(0);
        for (uint256 i = 0; i < _signatures.length; i++) {
            SignatureData memory value = _signatures[i];
            if (value.signature.length == 0) {
                require(
                    isGuardian(_wallet, msg.sender),
                    "KSM13 sender not a guardian"
                );
                require(
                    msg.sender == value.signer,
                    "KSM14 null signature should have the signer as the sender"
                );
            } else {
                validateGuardianSignature(
                    _wallet,
                    recoveryHash,
                    value.signer,
                    value.signature
                );
            }
            require(
                value.signer > lastSigner,
                "KSM15 duplicate signers/invalid ordering"
            );
            confirmRecoveryRequest(recoveryHash);
            lastSigner = value.signer;
        }
        //
        if (!_execute) return;
        uint256 _approvalCount = getRecoveryApprovals(
            _wallet,
            _newOwners,
            _newThreshold
        );
        require(
            _approvalCount >= guardiansThreshold,
            "KSM16 confirmed signatures less than threshold"
        );
        _executeRecovery(_wallet, _newOwners, _newThreshold, _approvalCount);
    }

    function executeRecovery(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold
    ) external {
        uint256 guardiansThreshold = threshold(_wallet);
        require(guardiansThreshold > 0, "KSM17 empty guardians");
        //
        uint256 _approvalCount = getRecoveryApprovals(
            _wallet,
            _newOwners,
            _newThreshold
        );
        require(
            _approvalCount >= guardiansThreshold,
            "KSM18 confirmed signatures less than threshold"
        );
        _executeRecovery(_wallet, _newOwners, _newThreshold, _approvalCount);
    }

    /**
     * @notice Owner can call this method to cancel ongoing recovery request
     * @param _wallet wallet to recover
     */
    function cancelRecovery(
        address _wallet
    ) external requireSenderIsWallet(_wallet) whenRecovery(_wallet) {
        removeRecoveryRequest(_wallet);
        emit RecoveryCanceled(_wallet, getNonce(_wallet) - 1);
    }

    /**
     * @notice This method will call when recovery request threshold satisfied
     * @param _wallet The target wallet.
     * @param _newOwners The new owners' addressess.
     * @param _newThreshold The new threshold for the safe.
     * @param _approvalCount The collected (confirmed) guardians signatures for this recovery operation.
     */
    function _executeRecovery(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold,
        uint256 _approvalCount
    ) internal {
        uint256 _nonce = getNonce(_wallet);

        checkAndReplaceRecovery(_wallet, _approvalCount, _nonce);

        uint64 executeAfter = uint64(block.timestamp + recoveryPeriod);
        setRecoveryRequest(_wallet, _newOwners, _newThreshold, _approvalCount);
        incrementNonce(_wallet);
        emit RecoveryExecuted(
            _wallet,
            _newOwners,
            _newThreshold,
            _nonce,
            executeAfter,
            _approvalCount
        );
    }

    /**
     * @notice Public method to finalize recovery request after recovery period
     * @param _wallet The target wallet.
     */
    function finalizeRecovery(address _wallet) external whenRecovery(_wallet) {
        RecoveryRequest memory request = getRecoveryRequest(_wallet);
        require(
            uint64(block.timestamp) >= request.executeAfter,
            "KSM20 recovery period still pending"
        );
        address[] memory newOwners = request.newOwners;
        uint256 newThreshold = request.newThreshold;
        removeRecoveryRequest(_wallet);

        Safe safe = Safe(payable(_wallet));
        address[] memory owners = safe.getOwners();

        for (uint256 i = (owners.length - 1); i > 0; --i) {
            bool success = safe.execTransactionFromModule({
                to: _wallet,
                value: 0,
                data: abi.encodeCall(
                    OwnerManager.removeOwner,
                    (owners[i - 1], owners[i], 1)
                ),
                operation: Enum.Operation.Call
            });
            if (!success) {
                revert("KSM21 owner removal failed");
            }
        }

        for (uint256 i = 0; i < newOwners.length; i++) {
            require(
                !isGuardian(_wallet, newOwners[i]),
                "KSM22 new owner cannot be guardian"
            );
            bool success;
            if (i == 0) {
                if (newOwners[i] == owners[i]) continue;
                success = safe.execTransactionFromModule({
                    to: _wallet,
                    value: 0,
                    data: abi.encodeCall(
                        OwnerManager.swapOwner,
                        (SENTINEL_OWNERS, owners[i], newOwners[i])
                    ),
                    operation: Enum.Operation.Call
                });
                if (!success) {
                    revert("KSM23 owner replacement failed");
                }
                continue;
            }
            success = safe.execTransactionFromModule({
                to: _wallet,
                value: 0,
                data: abi.encodeCall(
                    OwnerManager.addOwnerWithThreshold,
                    (newOwners[i], 1)
                ),
                operation: Enum.Operation.Call
            });
            if (!success) {
                revert("KSM24 owner addition failed");
            }
        }

        if (newThreshold > 1) {
            bool success = safe.execTransactionFromModule({
                to: _wallet,
                value: 0,
                data: abi.encodeCall(
                    OwnerManager.changeThreshold,
                    (newThreshold)
                ),
                operation: Enum.Operation.Call
            });
            if (!success) {
                revert("KSM25 change threshold failed");
            }
        }

        emit RecoveryFinalized(
            _wallet,
            newOwners,
            newThreshold,
            getNonce(_wallet) - 1
        );
    }

    /**
     * @notice Get recovery approval count
     * @param _wallet recovery wallet.
     * @param _newOwners new owner's of wallet.
     * @param _newThreshold The new owner threshold for safe transaction.
     * @return approvalCount The wallet's current recovery request
     */
    function getRecoveryApprovals(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _newThreshold
    ) public view returns (uint256 approvalCount) {
        uint256 _nonce = getNonce(_wallet);
        bytes32 recoveryHash = keccak256(
            encodeRecoveryData(_wallet, _newOwners, _newThreshold, _nonce)
        );
        address[] memory guardians = getGuardians(_wallet);
        approvalCount = 0;
        for (uint256 i = 0; i < guardians.length; i++) {
            if (hasConfirmedHashForGuardian(recoveryHash, guardians[i])) {
                approvalCount++;
            }
        }
    }

    /**
     * @notice Get guardian approval state
     * @param _guardian The guardian.
     * @param _wallet recovery wallet.
     * @param _newOwners new owner's of wallet.
     * @param _newThreshold The new owner threshold for safe transaction.
     * @return approvalCount The wallet's current recovery request
     */
    function hasGuardianApproved(
        address _wallet,
        address _guardian,
        address[] calldata _newOwners,
        uint256 _newThreshold
    ) public view returns (bool) {
        uint256 _nonce = getNonce(_wallet);
        bytes32 recoveryHash = keccak256(
            encodeRecoveryData(_wallet, _newOwners, _newThreshold, _nonce)
        );
        return hasConfirmedHashForGuardian(recoveryHash, _guardian);
    }
}
