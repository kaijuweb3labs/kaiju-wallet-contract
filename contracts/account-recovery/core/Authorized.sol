// SPDX-License-Identifier: LGPL-3.0-only
/// @author kaiju3d.com

pragma solidity >=0.7.0 <0.9.0;

contract Authorized {
    /**
     * @notice Throws if the sender is not the module itself or the owner of the target wallet.
     */
    modifier requireSenderIsWallet(address _wallet) {
        require(msg.sender == _wallet, "KSM01 unauthorized");
        _;
    }
}
