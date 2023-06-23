// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface INonceManager {
    /**
     * @notice Get the module nonce for a wallet.
     * @param _wallet The target wallet.
     * @return _nonce the nonce for this wallet.
     */
    function getNonce(address _wallet) external view returns (uint256 _nonce);

    function _incrementNonce(address _wallet) external;
}
