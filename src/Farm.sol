// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./interfaces/IHYGT.sol";

import "./libraries/SafeERC20.sol";

import "./utils/AccessControl.sol";

contract Farm is AccessControl {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant GOVERNOR_ROLE = keccak256(abi.encodePacked("Governor"));

    // TODO replace
    uint256 private constant ONE_MONTH_TIME = 1800;
    // uint256 private constant ONE_MONTH_TIME = 2592000;

    /// @notice The address of the primary governance token.
    IHYGT public HYGT;

    /// @notice HYGT tokens created per block.
    uint256 public HYGTPerBlock;
    /// @notice The block number when HYGT mining starts.
    uint256 public startBlock;
    /// @notice Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @dev Initialization variables.
    address private immutable _initializer;
    bool private _isInitialized;

    /* ========== STORAGE ========== */

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        /// @notice The accumulated HYGT per share - magnified by 1e12.
        uint256 accHYGTPerShare;
    }

    /// @notice Pool info.
    PoolInfo[] public poolInfo;
    /// @notice User info for each corresponding pool.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /* ========== EVENTS ========== */

    event AddPool(uint256 indexed pid, address lpToken, string symbol, uint256 allocPoint);
    event UpdateAllocation(uint256 indexed pid, uint256 newAllocPoint, uint256 oldAllocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     * @dev This function can only be called once.
     * @param hygt_ The address of the `HYGT` contract.
     * @param lpTokens_ The addresses of the first 3 `LP Tokens` to add to the farming pool.
     * @param initialMintStartTime_ The unix timestamp at which initial minting will begin.
     */
    function initialize(address hygt_, address[3] memory lpTokens_, uint256 initialMintStartTime_) external {
        require(_msgSender() == _initializer, "Farm: caller is not the initializer");
        // TODO uncomment
        // require(!_isInitialized, "Farm: already initialized");

        require(hygt_ != address(0), "Farm: invalid HYGT address");
        // TODO uncomment
        // require(pairs_.length == 3, "Farm: invalid pairs");
        _grantRole(GOVERNOR_ROLE, _msgSender());
        // TODO future proofing needed?
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        HYGT = IHYGT(hygt_);

        HYGTPerBlock = 2 * 1e18;
        // TODO change averageBlockTime
        uint256 averageBlockTime = 12;
        uint256 dBlocks = ((initialMintStartTime_ + ONE_MONTH_TIME) - block.timestamp) / averageBlockTime;
        startBlock = block.number + dBlocks;
        totalAllocPoint = 1000;

        /// @dev Initial farm pools.
        // TODO remove this check
        if (poolInfo.length == 0) {
            _addPool(IERC20(lpTokens_[0]), 400, "HYDT-BNB", startBlock);   // HYDT-BNB Pair
            _addPool(IERC20(lpTokens_[1]), 400, "HYDT-USDT", startBlock);  // HYDT-USDT Pair
            _addPool(IERC20(lpTokens_[2]), 200, "HYDT-HYGT", startBlock);  // HYDT-HYGT Pair
        }

        _isInitialized = true;
    }

    // TODO remove this function
    // function test_startBlock(uint256 initialMintStartTime_) external {
    //     uint256 averageBlockTime = 12;
    //     uint256 dBlocks = ((initialMintStartTime_ + ONE_MONTH_TIME) - block.timestamp) / averageBlockTime;
    //     startBlock = block.number + dBlocks;
    //     poolInfo[0].lastRewardBlock = startBlock;
    //     poolInfo[0].lastRewardBlock = startBlock;
    //     poolInfo[0].lastRewardBlock = startBlock;
    // }

    // // TODO remove this function
    // function test_addresses(address HYGT_) external {
    //     HYGT = IHYGT(HYGT_);
    // }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Returns the number of pools.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Adds a new `LP Token` to the pool. Caller must have the `Governor` role. Assigns a unique id for the given `LP Token`.
     *
     * NOTE: The same `LP Token` must NOT be added more than once otherwise the reward calculation will be compromised.
     *
     * @param lpToken The address of the `LP Token`.
     * @param allocPoint The value for allocation points.
     * @param symbol The name for the pool.
     * @param withUpdate Whether or not to update reward variables for all pools. May cause high gas spending.
     */
    function addPool(IERC20 lpToken, uint256 allocPoint, string memory symbol, bool withUpdate) external onlyRole(GOVERNOR_ROLE) {
        if (withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += allocPoint;
        _addPool(lpToken, allocPoint, symbol, lastRewardBlock);
    }

    function _addPool(IERC20 lpToken, uint256 allocPoint, string memory symbol, uint256 lastRewardBlock) internal {
        PoolInfo memory pool;
        pool.lpToken = IERC20(lpToken);
        pool.allocPoint = allocPoint;
        pool.lastRewardBlock = lastRewardBlock;
        // pool.accHYGTPerShare = 0;
        poolInfo.push(pool);

        emit AddPool(poolInfo.length - 1, address(lpToken), symbol, allocPoint);
    }

    /**
     * @notice Updates the given pool's HYGT allocation point. Caller must have the `Governor` role.
     * @param pid The unique id of the pool.
     * @param allocPoint The new value for allocation points.
     * @param withUpdate Whether or not to update reward variables for all pools. May cause high gas spending.
     */
    function updateAllocation(uint256 pid, uint256 allocPoint, bool withUpdate) external onlyRole(GOVERNOR_ROLE) {
        if (withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = (totalAllocPoint - poolInfo[pid].allocPoint) + allocPoint;
        uint256 oldAllocPoint = poolInfo[pid].allocPoint;
        poolInfo[pid].allocPoint = allocPoint;

        emit UpdateAllocation(pid, allocPoint, oldAllocPoint);
    }

    /**
     * @notice Updates reward variables for all pools.
     *
     * NOTE: May cause high gas spending.
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

   

    /**
     * @notice Gets all pending `HYGT` for a given user.
     */
    function getPendingBatch(address user) external view returns (uint256) {
        uint256 totalPending;

        for (uint256 i = 0 ; i < poolInfo.length ; i++) {
            totalPending += getPending(i, user);
        }
        return totalPending;
    }

    /**
     * @notice Gets all pending `HYGT` in a given pool for a given user.
     */
    function getPending(uint256 pid, address user) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo memory userData = userInfo[pid][user];
        uint256 accHYGTPerShare = pool.accHYGTPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 numberOfBlocks = block.number - pool.lastRewardBlock;
            uint256 HYGTReward = (numberOfBlocks * HYGTPerBlock * pool.allocPoint) / totalAllocPoint;
            accHYGTPerShare += ((HYGTReward * 1e12) / lpSupply);
        }
        uint256 pending = ((userData.amount * accHYGTPerShare) / 1e12) - userData.rewardDebt;
        return pending;
    }

    /**
     * @notice Deposit `LP Tokens` to recieve rewards in `HYGT`.
     */

      /**
     * @notice Updates reward variables of the given pool to be up-to-date.
     * @param pid The unique id of the pool.
     */
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 numberOfBlocks = block.number - pool.lastRewardBlock;
        uint256 HYGTReward = (numberOfBlocks * HYGTPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accHYGTPerShare += ((HYGTReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 pid, uint256 amount) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage userData = userInfo[pid][_msgSender()];
        updatePool(pid);

        if (userData.amount > 0) {
            uint256 pending = ((userData.amount * pool.accHYGTPerShare) / 1e12) - userData.rewardDebt;

            if(pending > 0) {
                HYGT.mint(_msgSender(), pending);
            }
        }
        if (amount > 0) {
            SafeERC20.safeTransferFrom(pool.lpToken, _msgSender(), address(this), amount);
            userData.amount += amount;
        }
        userData.rewardDebt = (userData.amount * pool.accHYGTPerShare) / 1e12;

        emit Deposit(_msgSender(), pid, amount);
    }

    /**
     * @notice Withdraw a certain amount of `LP Tokens` from the given pool.
     */
    function withdraw(uint256 pid, uint256 amount) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage userData = userInfo[pid][_msgSender()];
        require(userData.amount >= amount, "Farm: not good");
        updatePool(pid);
        uint256 pending = ((userData.amount * pool.accHYGTPerShare) / 1e12) - userData.rewardDebt;

        if(pending > 0) {
            HYGT.mint(_msgSender(), pending);
        }
        if(amount > 0) {
            userData.amount -= amount;
            SafeERC20.safeTransfer(pool.lpToken, _msgSender(), amount);
        }
        userData.rewardDebt = (userData.amount * pool.accHYGTPerShare) / 1e12;

        emit Withdraw(_msgSender(), pid, amount);
    }

    /**
     * @notice Withdraw all `LP Tokens` from the given pool without caring about rewards.
     *
     * NOTE: Emergency only.
     */
    function emergencyWithdraw(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage userData = userInfo[pid][_msgSender()];
        SafeERC20.safeTransfer(pool.lpToken, _msgSender(), userData.amount);

        emit EmergencyWithdraw(_msgSender(), pid, userData.amount);

        userData.amount = 0;
        userData.rewardDebt = 0;
    }
}