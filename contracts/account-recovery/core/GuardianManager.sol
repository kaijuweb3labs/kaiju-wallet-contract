// SPDX-License-Identifier: GPL-3.0
/// @author kaiju3d.com

pragma solidity >=0.8.12 <0.9.0;

import "../storage/IGuardianStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@gnosis.pm/safe-contracts/contracts/Safe.sol";
import "./Authorized.sol";
import "./ModuleMetadata.sol";

contract GuardianManager is Authorized, ModuleMetadata {
    // The guardians storage
    IGuardianStorage internal immutable guardianStorage;

    event GuardianAdded(
        address indexed wallet,
        address indexed guardian,
        uint256 threshold
    );
    event GuardianRevoked(
        address indexed wallet,
        address indexed guardian,
        uint256 threshold
    );

    constructor(IGuardianStorage _guardianStorage) {
        guardianStorage = _guardianStorage;
    }

    /// @dev checks if valid signature to the provided signer, and if this signer is indeed a guardian, revert otherwise
    function validateGuardianSignature(
        address _wallet,
        bytes32 _signHash,
        address _signer,
        bytes memory _signature
    ) public view {
        require(isGuardian(_wallet, _signer), "KSM04 Signer not a guardian");
        require(
            SignatureChecker.isValidSignatureNow(
                _signer,
                _signHash,
                _signature
            ),
            "KSM04 Invalid guardian signature"
        );
    }

    /**
     * @notice Lets the owner add a guardian for its wallet.
     * @param _wallet The target wallet.
     * @param _guardian The guardian to add.
     * @param _threshold The new threshold that will be set after addition.
     */
    function addGuardianWithThreshold(
        address _wallet,
        address _guardian,
        uint256 _threshold
    ) external requireSenderIsWallet(_wallet) {
        guardianStorage.addGuardian(_wallet, _guardian);
        guardianStorage.changeThreshold(_wallet, _threshold);
        emit GuardianAdded(_wallet, _guardian, _threshold);
    }

    /**
     * @notice Lets the owner revoke a guardian from its wallet.
     * @param _wallet The target wallet.
     * @param _prevGuardian The previous guardian linking to the guardian in the linked list.
     * @param _guardian The guardian to revoke.
     * @param _threshold The new threshold that will be set after execution of revokation.
     */
    function revokeGuardianWithThreshold(
        address _wallet,
        address _prevGuardian,
        address _guardian,
        uint256 _threshold
    ) external requireSenderIsWallet(_wallet) {
        require(
            isGuardian(_wallet, _guardian),
            "KSM26 must be existing guardian"
        );
        uint256 _guardiansCount = guardianStorage.guardiansCount(_wallet);
        require(_guardiansCount - 1 >= _threshold, "KSM27 invalid threshold");
        guardianStorage.revokeGuardian(_wallet, _prevGuardian, _guardian);
        guardianStorage.changeThreshold(_wallet, _threshold);
        emit GuardianRevoked(_wallet, _guardian, _threshold);
    }

    /**
     * @notice Lets the owner change the guardian threshold required to initiate a recovery.
     * @param _wallet The target wallet.
     * @param _threshold The new threshold that will be set after execution of revokation.
     */
    function changeThreshold(
        address _wallet,
        uint256 _threshold
    ) external requireSenderIsWallet(_wallet) {
        guardianStorage.changeThreshold(_wallet, _threshold);
    }

    /**
     * @notice Checks if an address is a guardian for a wallet.
     * @param _wallet The target wallet.
     * @param _guardian The address to check.
     * @return _isGuardian `true` if the address is a guardian for the wallet otherwise `false`.
     */
    function isGuardian(
        address _wallet,
        address _guardian
    ) public view returns (bool _isGuardian) {
        return guardianStorage.isGuardian(_wallet, _guardian);
    }

    /**
     * @notice Counts the number of active guardians for a wallet.
     * @param _wallet The target wallet.
     * @return _count The number of active guardians for a wallet.
     */
    function guardiansCount(
        address _wallet
    ) public view returns (uint256 _count) {
        return guardianStorage.guardiansCount(_wallet);
    }

    /**
     * @dev Retrieves the wallet threshold count.
     * @param _wallet The target wallet.
     * @return _threshold Threshold count.
     */
    function threshold(
        address _wallet
    ) public view returns (uint256 _threshold) {
        return guardianStorage.threshold(_wallet);
    }

    /**
     * @notice Get the active guardians for a wallet.
     * @param _wallet The target wallet.
     * @return _guardians the active guardians for a wallet.
     */
    function getGuardians(
        address _wallet
    ) public view returns (address[] memory _guardians) {
        return guardianStorage.getGuardians(_wallet);
    }
}
