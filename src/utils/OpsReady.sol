// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "../libraries/SafeERC20.sol";
import "../interfaces/Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * make synchronous fee payments.
 *
 * NOTE: Modified to apply for the HYDT Protocol.
 */
abstract contract OpsReady {
    IOps public OPS;
    address internal _gelato;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // TODO change
    address internal constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev Transfers fee to gelato for synchronous fee payments.
     * @param _fee should be queried from IOps.getFeeDetails().
     * @param _feeToken should be queried from IOps.getFeeDetails().
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");

            require(success, "OpsReady: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails() internal view returns (uint256 fee, address feeToken) {
        (fee, feeToken) = OPS.getFeeDetails();
    }
}