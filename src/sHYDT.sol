// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./extensions/ERC20.sol";

import "./interfaces/IsHYDT.sol";

import "./utils/AccessControl.sol";

contract sHYDT is AccessControl, ERC20, IsHYDT {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant CALLER_ROLE = keccak256(abi.encodePacked("Caller"));

    /// @dev Initialization variables.
    address private immutable _initializer;
    bool private _isInitialized;

    /* ========== CONSTRUCTOR ========== */

    constructor()
        ERC20("Staked High Yield Dollar Stable Token", "sHYDT")
    {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     * @dev This function can only be called once.
     * @param earn_ The address of the `Earn` contract.
     */
    function initialize(address earn_) external {
        require(_msgSender() == _initializer, "sHYDT: caller is not the initializer");
        // TODO uncomment
        // require(!_isInitialized, "sHYDT: already initialized");

        require(earn_ != address(0), "sHYDT: invalid Earn address");
        _grantRole(CALLER_ROLE, earn_);
        // TODO future proofing needed?
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _isInitialized = true;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `Caller` role.
     */
    function mint(address to, uint256 amount) external override onlyRole(CALLER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }

    /**
     * @dev See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must have the `Caller` role.
     */
    function burn(uint256 amount) external override returns (bool) {
        address owner = _msgSender();
        _burn(owner, amount);
        return true;
    }

    /**
     * @dev Destorys `amount` tokens from `from` using the allowance
     * mechanism. `amount` is then deducted from the caller's allowance.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - the caller must have the `Caller` role.
     * - `from` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least `amount`.
     */
    function burnFrom(address from, uint256 amount) external override onlyRole(CALLER_ROLE) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _burn(from, amount);
        return true;
    }
}