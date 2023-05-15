// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./libraries/DataFetcher.sol";
import "./libraries/SafeETH.sol";

import "./utils/AccessControl.sol";

contract Reserve is AccessControl {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant CALLER_ROLE = keccak256(abi.encodePacked("Caller"));

    // TODO replace
    /// @notice The address of the Wrapped BNB token.
    address public constant WBNB = 0xa0Cb889707d426A7A386870A03bc70d1b0697598;

    // TODO replace
    /// @notice The address of the relevant stable token.
    address public constant USDT = 0x03A6a84cD762D9707A21605b548aaaB891562aAb;

    /// @dev Initialization variables.
    address private immutable _initializer;
    bool private _isInitialized;

    /* ========== EVENTS ========== */

    event In(address caller, uint256 amountBNB, uint256 totalReserveBNB, uint256 totalReserve);
    event Out(address caller, uint256 amountBNB, uint256 totalReserveBNB, uint256 totalReserve);

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     * @dev This function can only be called once.
     * @param control_ The address of the `Control` contract.
     */
    function initialize(address control_) external {
        require(_msgSender() == _initializer, "Reserve: caller is not the initializer");
        // TODO uncomment
        // require(!_isInitialized, "Reserve: already initialized");

        require(control_ != address(0), "Reserve: invalid Control address");
        _grantRole(CALLER_ROLE, control_);
        // TODO future proofing needed?
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _isInitialized = true;
    }

    /* ========== FUNCTIONS ========== */

    receive() external payable {
        uint256 totalReserveBNB = address(this).balance;
        uint256 totalReserve = DataFetcher.quote(totalReserveBNB, WBNB, USDT);

        emit In(_msgSender(), msg.value, totalReserveBNB, totalReserve);
    }

    /**
     * @notice Transfers BNB stored in this contract to the sender. Caller must have the `Caller` role.
     */
    function withdraw(uint256 amount) external onlyRole(CALLER_ROLE) {
        SafeETH.safeTransferETH(_msgSender(), amount);
        uint256 totalReserveBNB = address(this).balance;
        uint256 totalReserve = DataFetcher.quote(totalReserveBNB, WBNB, USDT);

        emit Out(_msgSender(), amount, totalReserveBNB, totalReserve);
    }
}