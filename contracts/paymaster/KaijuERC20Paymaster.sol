// SPDX-License-Identifier: GPL-3.0
/// @author: kaiju3d.com

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "../erc20/KaijuArcadeToken.sol";

/**
 * A  paymaster that gets KaijuArcadeToken ERC20 token to pay for gas.
 * Also, the exchange rate & cost_of_post can be changed by an editor_role
 */

contract KaijuERC20Paymaster is BasePaymaster, AccessControl {
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    uint256 public COST_OF_POST = 15000;
    uint256 public ratio = 100;
    address public immutable theFactory;
    address public erc20token;

    constructor(
        address accountFactory,
        IEntryPoint _entryPoint,
        address tokenContractAddress
    ) BasePaymaster(_entryPoint) {
        theFactory = accountFactory;
        erc20token = tokenContractAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EDITOR_ROLE, msg.sender);
    }

    /**
     * @dev Set editor role to an address
     * @param to | The address gets granted the editor role
     */
    function setEditorRole(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(EDITOR_ROLE, to);
    }

    /**
     * @dev Change eth to token ration
     * @param newRatio | new eth to token ration
     */
    function changeRatio(uint256 newRatio) public onlyRole(EDITOR_ROLE) {
        ratio = newRatio;
    }

    /**
     * @dev Change cost of postOp
     * @param newCost | new postOp cost
     */
    function changeCostOfPostOp(uint256 newCost) public onlyRole(EDITOR_ROLE) {
        COST_OF_POST = newCost;
    }

    /**
     * @dev Get the value of tokens equal to an eth value
     * @param valueEth | eth value of a token
     */
    function getTokenValueOfEth(
        uint256 valueEth
    ) internal view virtual returns (uint256 valueToken) {
        return valueEth / ratio;
    }

    /**
     * @dev verify the userOp sender has enough token to pay transaction fees
     * @param userOp | User Operation
     * @param requiredPreFund | To be Developed
     * @return context |
     * @return validationData | Validated Data for the Paymaster
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        uint256 tokenPrefund = getTokenValueOfEth(requiredPreFund);
        require(
            userOp.verificationGasLimit > COST_OF_POST,
            "Paymaster: gas too low for postOp"
        );
        uint256 userTokenBalance = KaijuArcadeToken(erc20token).balanceOf(
            userOp.sender
        );

        if (userOp.initCode.length != 0) {
            _validateConstructor(userOp);
            require(
                userTokenBalance >= tokenPrefund,
                "Paymaster: no balance (pre-create)"
            );
        } else {
            require(userTokenBalance >= tokenPrefund, "Paymaster: no balance");
        }
        return (abi.encode(userOp.sender), 0);
    }

    /**
     * @dev verify account factory of the userOp
     * @param userOp | User Operation
     */
    function _validateConstructor(
        UserOperation calldata userOp
    ) internal view virtual {
        address factory = address(bytes20(userOp.initCode[0:20]));
        require(factory == theFactory, "Paymaster: wrong account factory");
    }

    /**
     * @dev transfer the relevent token amount from sender to paymaster tokens
     * @param mode | Result of the Opcode
     * @param context | encoded Sender address and Metadata URL
     * @param actualGasCost | Gas cost of the Transaction
     */
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        (mode);
        address sender = abi.decode(context, (address));
        uint256 charge = getTokenValueOfEth(actualGasCost + COST_OF_POST);
        KaijuArcadeToken(erc20token).transfer(sender, charge);
    }
}
