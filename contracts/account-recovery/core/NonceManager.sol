// SPDX-License-Identifier: GPL-3.0
/// @author kaiju3d.com

pragma solidity >=0.8.12 <0.9.0;

contract NonceManager {
    mapping(address => uint256) internal walletsNonces;

    /**
     * @notice Get the module nonce for a wallet.
     * @param _wallet The target wallet.
     * @return _nonce the nonce for this wallet.
     */
    function getNonce(address _wallet) public view returns (uint256 _nonce) {
        return walletsNonces[_wallet];
    }

    function incrementNonce(address _wallet) internal {
        walletsNonces[_wallet]++;
    }
}
