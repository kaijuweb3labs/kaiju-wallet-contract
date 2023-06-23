// SPDX-License-Identifier: GPL-3.0
/// @author: kaiju3d.com

pragma solidity ^0.8.12;


import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * A paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for the account-specific signature:
 * - the paymaster checks a signature to agree to PAY for GAS.
 * - the account checks a signature to prove identity and account ownership.
 */

contract KaijuVerifyingPaymaster is BasePaymaster {

    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;

    address public immutable verifyingSigner;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;

    uint256 private constant SIGNATURE_OFFSET = 84;

    constructor(IEntryPoint _entryPoint, address _verifyingSigner) BasePaymaster(_entryPoint) {
        verifyingSigner = _verifyingSigner;
    }

    mapping(address => uint256) public senderNonce;

    /**
     * @dev Copy directly the userOp from calldata up to (but not including) the paymasterAndData. This encoding depends on the ABI encoding of calldata, but is much lighter to copy than referencing each field separately.
     * @param userOp | User Operation
     */

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {

        bytes calldata pnd = userOp.paymasterAndData;

        assembly {
            let ofs := userOp
            let len := sub(sub(pnd.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    /**
     * @dev The hash we're going to sign off-chain (and validate on-chain). Method is called by 
     *      Off-chain Service - to sign the request.
     *      On-chain Service - from the validatePaymasterUserOp, to validate the signature.
     * @param userOp | User Operation
     * @param validUntil | Validate Period
     * @param validAfter | Validate Period
     * 
     * Note:    that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     *          which will carry the signature itself.
     */

    function getHash(UserOperation calldata userOp, uint48 validUntil, uint48 validAfter)
    public view returns (bytes32) {

        return keccak256(abi.encode(
                pack(userOp),
                block.chainid,
                address(this),
                senderNonce[userOp.getSender()],
                validUntil,
                validAfter
            ));
    }

    /**
     * @dev verify our external signer signed this request. The "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     * @param userOp | User Operation
     * @param requiredPreFund | To be Developed
     * @return context | 
     * @return validationData | Validated Data for the Paymaster
     * 
     * Note :   ECDSA library supports both 64 and 65-byte long signatures. Only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA".
     *          Don't revert on signature failure: return SIG_VALIDATION_FAILED
     *          No need for other on-chain validation: entire UserOp should have been checked by the external service prior to signing it.
     */

    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 /*userOpHash*/, uint256 requiredPreFund)
    internal override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);

        (uint48 validUntil, uint48 validAfter, bytes calldata signature) = parsePaymasterAndData(userOp.paymasterAndData);

        require(signature.length == 64 || signature.length == 65, "VerifyingPaymaster: invalid signature length in paymasterAndData");
        bytes32 hash = ECDSA.toEthSignedMessageHash(getHash(userOp, validUntil, validAfter));
        senderNonce[userOp.getSender()]++;

        if (verifyingSigner != ECDSA.recover(hash, signature)) {
            return ("",_packValidationData(true,validUntil,validAfter));
        }
        return ("",_packValidationData(false,validUntil,validAfter));
    }

    /**
     * @dev parse paymaster and data
     * @param paymasterAndData | paymaster and data
     */

    function parsePaymasterAndData(bytes calldata paymasterAndData) public pure returns(uint48 validUntil, uint48 validAfter, bytes calldata signature) {
        (validUntil, validAfter) = abi.decode(paymasterAndData[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET],(uint48, uint48));
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }
}