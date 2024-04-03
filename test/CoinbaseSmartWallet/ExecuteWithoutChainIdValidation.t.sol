// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmartWalletTestBase.sol";

contract TestExecuteWithoutChainIdValidation is SmartWalletTestBase {
    function setUp() public override {
        super.setUp();
        userOpNonce = account.REPLAYABLE_NONCE_KEY() << 64;
        userOpCalldata = abi.encodeWithSelector(CoinbaseSmartWallet.executeWithoutChainIdValidation.selector);
    }

    function test_revertsIfCallerNotEntryPoint() public {
        vm.expectRevert(MultiOwnable.Unauthorized.selector);
        account.executeWithoutChainIdValidation("");
    }

    function test_revertsIfWrongNonceKey() public {
        userOpNonce = 0;
        UserOperation memory userOp = _getUserOpWithSignature();
        vm.expectRevert();
        _sendUserOperation(userOp);
    }

    function test_canChangeOwnerWithoutChainId() public {
        address newOwner = address(6);
        assertFalse(account.isOwnerAddress(newOwner));

        userOpCalldata = abi.encodeWithSelector(
            CoinbaseSmartWallet.executeWithoutChainIdValidation.selector,
            abi.encodeWithSelector(MultiOwnable.addOwnerAddress.selector, newOwner)
        );
        _sendUserOperation(_getUserOpWithSignature());
        assertTrue(account.isOwnerAddress(newOwner));
    }

    function test_cannotCallExec() public {
        bytes memory restrictedSelectorCalldata = abi.encodeWithSelector(CoinbaseSmartWallet.execute.selector, "");
        vm.prank(address(entryPoint));
        vm.expectRevert(
            abi.encodeWithSelector(
                CoinbaseSmartWallet.SelectorNotAllowed.selector, CoinbaseSmartWallet.execute.selector
            )
        );
        account.executeWithoutChainIdValidation(restrictedSelectorCalldata);
    }

    function _sign(UserOperation memory userOp) internal view override returns (bytes memory signature) {
        bytes32 toSign = account.getUserOpHashWithoutChainId(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, toSign);
        signature = abi.encode(CoinbaseSmartWallet.SignatureWrapper(0, abi.encodePacked(r, s, v)));
    }
}
