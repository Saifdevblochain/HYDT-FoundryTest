// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./interfaces/IHYDT.sol";
import "./interfaces/IHYGT.sol";
import "./interfaces/IsHYDT.sol";

import "./libraries/SafeERC20.sol";

import "./utils/AccessControl.sol";

contract Earn is AccessControl {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant GOVERNOR_ROLE = keccak256(abi.encodePacked("Governor"));

    // TODO replace
    /// @dev Fixed time duration variables.
    uint128 private constant ONE_MONTH_TIME = 1800; // 2592000
    uint128 private constant ONE_DAY_TIME = 60; // 86400

    /// @notice The address of the primary stable token.
    IHYDT public HYDT;
    /// @notice The address of the primary governance token.
    IHYGT public HYGT;
    /// @notice The address of the staking certificate token.
    IsHYDT public sHYDT;
    /// @notice The address of the secondary funds collection wallet.
    address public TREASURY;

    /// @notice Fee that is moved to the treasury on every deposit - magnified by 1e1.
    uint256 public depositFee;
    /// @notice Percentage daily payouts (principal + yield) - magnified by 1e18.
    uint256[] public dailyPayouts;
    /// @notice Percentage yearly yields - magnified by 1e18.
    uint256[] public yearlyYields;
    /// @notice Duration applied to each corresponding yield - in seconds.
    uint256[] public lockPeriods;

    /// @notice HYGT tokens created per second.
    uint256 public HYGTPerSecond;
    /// @notice The time when HYGT mining starts.
    uint256 public startTime;
    /// @notice Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @dev Initialization variables.
    address public immutable _initializer;
    bool private _isInitialized;

    /* ========== STORAGE ========== */

    struct Staking {
        uint256 index;
        bool status;
        uint256 amount;
        uint8 stakeType;
        uint256 startTime;
        uint256 endTime;
        uint256 lastClaimTime;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint8 stakeType;
        uint256 allocPoint;
        uint256 stakeSupply;
        /// @dev The accumulated HYGT per share - magnified by 1e12.
        uint256 accHYGTPerShare;
        uint256 lastRewardTime;
    }

    struct PoolShare {
        uint256 stakeSupply;
        /// @dev The accumulated HYGT per share - magnified by 1e12.
        uint256 accHYGTPerShare;
        uint256 lastRewardTime;
    }

    /// @notice Pool info.
    PoolInfo[] public poolInfo;
    /// @notice Pool shares.
    mapping (uint256 => PoolShare[]) public poolShares;
    /// @notice User stakings.
    mapping (address => mapping (uint256 => Staking)) public getStakings;
    /// @notice Number of stakings for each user.
    mapping (address => uint256) public getStakingLengths;

    /* ========== EVENTS ========== */

    event UpdateAllocationWithUpdate(uint256 indexed stakeType, uint256 newAllocPoint, uint256 oldAllocPoint);
    event Stake(
        address indexed user,
        uint256 index,
        uint256 amount,
        uint8 stakeType,
        uint256 startTime,
        uint256 endTime
    );
    event Payout(address indexed user, uint256 index, uint256 payout);
    event Unstake(address indexed user, uint256 index, uint256 amount, uint256 activeDeposits);

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     * @dev This function can only be called once.
     * @param hydt_ The address of the `HYDT` contract.
     * @param hygt_ The address of the `HYGT` contract.
     * @param shydt_ The address of the `sHYDT` contract.
     * @param treasury_ The address of the `Treasury` wallet.
     * @param initialMintStartTime_ The unix timestamp at which initial minting will begin.
     */
    function initialize(address hydt_, address hygt_, address shydt_, address treasury_, uint256 initialMintStartTime_) external {
        require(_msgSender() == _initializer, "Earn: caller is not the initializer");
        // TODO uncomment
        // require(!_isInitialized, "Earn: already initialized");

        require(hydt_ != address(0), "Earn: invalid HYDT address");
        require(hygt_ != address(0), "Earn: invalid HYGT address");
        require(shydt_ != address(0), "Earn: invalid sHYDT address");
        require(treasury_ != address(0), "Earn: invalid Treasury address");
        _grantRole(GOVERNOR_ROLE, _msgSender());
        // TODO future proofing needed?
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        HYDT = IHYDT(hydt_);
        HYGT = IHYGT(hygt_);
        sHYDT = IsHYDT(shydt_);
        TREASURY = treasury_;

        depositFee = 15;
        dailyPayouts = [1.156 * 1e18, 0.611 * 1e18, 0.356 * 1e18];
        yearlyYields = [16 * 1e18, 20 * 1e18, 30 * 1e18];
        // TODO replace
        lockPeriods = [5400, 10800, 21900];
        // lockPeriods = [7776000, 15552000, 31536000];

        // TODO change HYGTPerSecond
        HYGTPerSecond = 0.166666666666666667 * 1e18; // 0.666666666666666667 * 1e18;
        startTime = initialMintStartTime_ + ONE_MONTH_TIME;
        totalAllocPoint = 1000;

        /// @dev Staking pools.
        // TODO remove this check
        if (poolInfo.length == 0) {
            _addPool(0, 100, startTime);   // 104%
            _addPool(1, 300, startTime);   // 110%
            _addPool(2, 600, startTime);   // 130%
        }

        _isInitialized = true;
    }

    // TODO remove this function
    // function test_startTime(uint256 initialMintStartTime_) external {
    //     startTime = initialMintStartTime_;
    //     poolInfo[0].lastRewardTime = startTime;
    //     poolInfo[0].lastRewardTime = startTime;
    //     poolInfo[0].lastRewardTime = startTime;
    // }

    // // TODO remove this function
    // function test_addresses(address HYDT_, address HYGT_, address sHYDT_, address treasury_) external {
    //     HYDT = IHYDT(HYDT_);
    //     HYGT = IHYGT(HYGT_);
    //     sHYDT = IsHYDT(sHYDT_);
    //     TREASURY = treasury_;
    // }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Returns the number of pools.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function _addPool(uint8 stakeType, uint256 allocPoint, uint256 lastRewardTime) internal {
        PoolInfo memory pool;
        pool.stakeType = stakeType;
        pool.allocPoint = allocPoint;
        // pool.stakeSupply = 0;
        // pool.accHYGTPerShare = 0;
        pool.lastRewardTime = lastRewardTime;
        poolInfo.push(pool);
    }

    /**
     * @notice Updates the given pool's HYGT allocation point. Caller must have the `Governor` role.
     *
     * NOTE: May cause high gas spending.
     *
     * @param stakeType The unique id of the pool.
     * @param allocPoint The new value for allocation points.
     */
    function updateAllocationWithUpdate(uint8 stakeType, uint256 allocPoint) public onlyRole(GOVERNOR_ROLE) {
        massUpdatePools();
        totalAllocPoint = (totalAllocPoint - poolInfo[stakeType].allocPoint) + allocPoint;
        uint256 oldAllocPoint = poolInfo[stakeType].allocPoint;
        poolInfo[stakeType].allocPoint = allocPoint;

        emit UpdateAllocationWithUpdate(stakeType, allocPoint, oldAllocPoint);
    }

    /**
     * @notice Updates reward variables for all pools.
     *
     * NOTE: May cause high gas spending.
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint8 stakeType = 0; stakeType < length; ++stakeType) {
            updatePool(stakeType);
        }
    }

    /**
     * @notice Updates reward variables of the given pool to be up-to-date.
     * @param stakeType The unique id of the pool.
     */
    function updatePool(uint8 stakeType) public {
        PoolInfo storage pool = poolInfo[stakeType];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 stakeSupply = pool.stakeSupply;
        if (stakeSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            poolShares[stakeType].push(PoolShare(stakeSupply, pool.accHYGTPerShare, block.timestamp));
            return;
        }
        uint256 numberOfSeconds = block.timestamp - pool.lastRewardTime;
        uint256 HYGTReward = (numberOfSeconds * HYGTPerSecond * pool.allocPoint) / totalAllocPoint;
        pool.accHYGTPerShare += (HYGTReward * 1e12) / stakeSupply;
        pool.lastRewardTime = block.timestamp;

        PoolShare memory share;
        share.stakeSupply = stakeSupply;
        share.accHYGTPerShare = pool.accHYGTPerShare;
        share.lastRewardTime = block.timestamp;
        poolShares[stakeType].push(share);
    }

    function binarySearchShare(address user, uint256 index) internal view returns (PoolShare memory) {
        Staking memory staking = getStakings[user][index];
        PoolShare[] memory shares = poolShares[staking.stakeType];
        uint256 endTime = block.timestamp > staking.endTime ? staking.endTime : block.timestamp;
        if (endTime < shares[0].lastRewardTime) {
            return shares[0];
        } else if (endTime >= shares[shares.length - 1].lastRewardTime) {
            return shares[shares.length - 1];
        }
        uint256 low = 0;
        uint256 high = shares.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;

            if (shares[mid].lastRewardTime < endTime) {
                low = mid + 1;
            } else if (shares[mid].lastRewardTime == endTime) {
                return shares[mid];
            } else {
                high = mid;
            }
        }
        return shares[low - 1];
    }

    /**
     * @notice Gets all pending `HYGT` for a given user.
     */
    function getPendingBatch(address user) external view returns (uint256) {
        uint256 totalPending;

        for (uint256 i = 0 ; i < getStakingLengths[user] ; i++) {
            totalPending += getPending(user, i);
        }
        return totalPending;
    }

    /**
     * @notice Gets all pending `HYGT` in a given pool for a given user.
     */
    function getPendingType(address user, uint8 stakeType) external view returns (uint256) {
        uint256 totalPending;

        for (uint256 i = 0 ; i < getStakingLengths[user] ; i++) {
            if (getStakings[user][i].stakeType == stakeType) {
                totalPending += getPending(user, i);
            }
        }
        return totalPending;
    }

    /**
     * @notice Gets the pending `HYGT` for a given user's specific stake index.
     */
     
    function getPending(address user, uint256 index) public view returns (uint256) {
        uint256 pending;
        Staking memory staking = getStakings[user][index];
        PoolInfo memory pool = poolInfo[staking.stakeType];

        if (staking.status) {
            if (block.timestamp >= staking.endTime) {
                PoolShare memory share = binarySearchShare(user, index);
                pool.stakeSupply = share.stakeSupply;
                pool.accHYGTPerShare = share.accHYGTPerShare;
                pool.lastRewardTime = share.lastRewardTime;
            }
            if (block.timestamp > pool.lastRewardTime && pool.stakeSupply != 0) {
                uint256 endTime = block.timestamp > staking.endTime ? staking.endTime : block.timestamp;
                uint256 numberOfSeconds = endTime - pool.lastRewardTime; // 1683711049 - 1683711049
                                    // 3,709*          0.166666666666666667 * 1e18    //100     1000
                uint256 HYGTReward = (numberOfSeconds * HYGTPerSecond * pool.allocPoint) / totalAllocPoint; // 91.66666666666666685
                              // 0+ 61.8166666666666667903 / 98.5    
                pool.accHYGTPerShare += (HYGTReward * 1e12) / pool.stakeSupply; //0.6275803722504230130994923857868
            }           // 98.5         *       0.6275803722504230130994923857868
            pending = ((staking.amount * pool.accHYGTPerShare) / 1e12) - staking.rewardDebt;  // 97.872419627749576986900507614213
            //19.000000000000000018  // retest this value using 9.85 amount
            // my res from test is 76883333333328950000
        }
        return pending;
    }

    /**
     * @notice Gets the `HYDT` payout for the current day for a given user for all stakes.
     */
    function getDailyPayoutBatch(address user) external view returns (uint256) {
        uint256 totalDailyPayout;

        for (uint256 i = 0 ; i < getStakingLengths[user] ; i++) {
            Staking memory staking = getStakings[user][i];

            if (staking.status) {
                if (block.timestamp < staking.endTime) {
                    uint256 ratio = dailyPayouts[staking.stakeType];
                    uint256 dailyPayout = ((staking.amount * ratio) / 1e2) / 1e18;
                    totalDailyPayout += dailyPayout;
                }
            }
        }
        return totalDailyPayout;
    }

    /**
     * @notice Gets the total `HYDT` payout for a given user.
     */
    function getPayoutBatch(address user) external view returns (uint256) {
        uint256 totalPayout;

        for (uint256 i = 0 ; i < getStakingLengths[user] ; i++) {
            totalPayout += getPayout(user, i);
        }
        return totalPayout;
    }

    /**
     * @notice Gets the total `HYDT` payout in a given pool for a given user.
     */
    function getPayoutType(address user, uint8 stakeType) external view returns (uint256) {
        uint256 totalPayout;

        for (uint256 i = 0 ; i < getStakingLengths[user] ; i++) {
            if (getStakings[user][i].stakeType == stakeType) {
                totalPayout += getPayout(user, i);
            }
        }
        return totalPayout;
    }

    /**
     * @notice Gets the `HYDT` payout for a given user's specific stake index.
     */
    function getPayout(address user, uint256 index) public view returns (uint256) {
        uint256 payout;
        Staking memory staking = getStakings[user][index];

        if (staking.status) {
                            // 1683634003     1683639503
            uint256 endTime = block.timestamp > staking.endTime ? staking.endTime : block.timestamp;
            uint256 numberOfDays = (endTime - staking.lastClaimTime) / ONE_DAY_TIME; //60
                // 5500
                // 91
            if (numberOfDays > 0) {
                uint256 ratio = dailyPayouts[staking.stakeType]; // 1.156 * 1e18
                uint256 payoutPerDay = ((staking.amount * ratio) / 1e2) / 1e18;
                payout = payoutPerDay * numberOfDays;
            }
        }
        return payout;
    }

    /**
     * @notice Deposit `HYDT` to recieve rewards in both `HYDT` and `HYGT`. Assigns a unique index for the given deposit.
     */
    function stake(uint256 amount, uint8 stakeType) external {
        require(amount > 0, "Earn: insufficient amount");
        require(stakeType <= 2, "Earn: invalid stake type");
        uint256 fee = (amount * depositFee) / 1000;
        uint256 amountWithFee = amount - fee;
        SafeERC20.safeTransferFrom(HYDT, _msgSender(), TREASURY, fee);
        HYDT.burnFrom(_msgSender(), amountWithFee);
        sHYDT.mint(address(this), amountWithFee);

        PoolInfo storage pool = poolInfo[stakeType];
        updatePool(stakeType);
        pool.stakeSupply += amountWithFee;

        Staking memory staking;
        staking.index = getStakingLengths[_msgSender()]; // 0
        staking.status = true; 
        staking.amount = amountWithFee; /// 98500000000000000000
        staking.stakeType = stakeType; // 0
        staking.startTime = block.timestamp; // 1683705649
        staking.endTime = block.timestamp + lockPeriods[stakeType]; // 1683711049
        staking.lastClaimTime = block.timestamp; //1683705649
        staking.rewardDebt = (amountWithFee * pool.accHYGTPerShare) / 1e12;  // 0

        getStakings[_msgSender()][staking.index] = staking;
        getStakingLengths[_msgSender()]++;
        // uint256 activeDeposits = sHYDT.balanceOf(address(this));

        emit Stake(_msgSender(), staking.index, staking.amount, staking.stakeType, staking.startTime, staking.endTime);
    }

    /**
     * @notice Withdraw `HYDT` deposits and rewards given the unique index for a given user. 
     */
    function claimPayout(uint256 index) external {
        Staking storage staking = getStakings[_msgSender()][index];
        PoolInfo storage pool = poolInfo[staking.stakeType];

        require(staking.status, "Earn: invalid staking");
        uint256 amountMint = getPayout(_msgSender(), index);
        updatePool(staking.stakeType);
        uint256 pending = getPending(_msgSender(), index);

        if (block.timestamp < staking.endTime) {
            require(amountMint > 0 || pending > 0, "Earn: no amount to withdraw");
            uint256 endTime = block.timestamp > staking.endTime ? staking.endTime : block.timestamp;
            uint256 numberOfDays = (endTime - staking.lastClaimTime) / ONE_DAY_TIME;
            staking.lastClaimTime = staking.lastClaimTime + (numberOfDays * ONE_DAY_TIME);

            staking.rewardDebt = (staking.amount * pool.accHYGTPerShare) / 1e12;

            emit Payout(_msgSender(), staking.index, amountMint);
        } else {
            uint256 stakingIndex = staking.index;
            uint256 stakingAmount = staking.amount;
            delete getStakings[_msgSender()][index];
            sHYDT.burn(stakingAmount);

            pool.stakeSupply -= stakingAmount;
            uint256 activeDeposits = sHYDT.balanceOf(address(this));

            emit Unstake(_msgSender(), stakingIndex, stakingAmount, activeDeposits);
        }

        if (amountMint > 0) {
            HYDT.mint(_msgSender(), amountMint);
        }
        if (pending > 0) {
            HYGT.mint(_msgSender(), pending);
        }
    }
}