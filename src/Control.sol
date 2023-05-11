// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./interfaces/IHYDT.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IReserve.sol";

import "./libraries/DataFetcher.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeETH.sol";

import "./utils/AccessControl.sol";
import "./utils/OpsReady.sol";

contract Control is AccessControl, OpsReady {

    /* ========== STATE VARIABLES ========== */

    bytes32 public constant GOVERNOR_ROLE = keccak256(abi.encodePacked("Governor"));
    bytes32 public constant CALLER_ROLE = keccak256(abi.encodePacked("Caller"));

    // TODO replace values and make both constant
    /// @dev Fixed time duration variables.
    uint128 private THREE_MONTHS_TIME = 5400; // 7776000
    uint128 private ONE_DAY_TIME = 60; // 86400

    // TODO replace
    /// @notice The address of the pancake router.
    IPancakeRouter02 public constant PANCAKE_ROUTER = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // TODO replace
    /// @notice The address of the Wrapped BNB token.
    address public  WBNB ;

    // TODO replace
    /// @notice The address of the relevant stable token.
    address public constant USDT = 0x0c48B9e41Fa2452158daB36096A5abf1C5Abf17C;

    // TODO replace values and make both constant
    /// @notice The total limit for initial minting in USD.
    uint128 public INITIAL_MINT_LIMIT = 0.1 * 1e18; // 30000000 * 1e18
    /// @notice the daily limit for initial minting in USD.
    uint128 public DAILY_INITIAL_MINT_LIMIT = 0.001 * 1e18; // 700000 * 1e18

    /// @dev Fixed price values.
    uint128 private constant PRICE_UPPER_BOUND = 1.02 * 1e18;
    uint128 private constant PRICE_LOWER_BOUND = 0.98 * 1e18;

    /// @notice The address of the primary stable token.
    IHYDT public HYDT;
    /// @notice The address of the BNB reserve.
    IReserve public RESERVE;

    /// @dev Storage of values for initial minting.
    Values private _initialMints;
    Values private _dailyInitialMints;

    /// @dev Dependencies for ops calls.
    uint256 public mintProgressCount;
    uint256 public redeemProgressCount;
    uint256 public lastExecutedMint;
    uint256 public lastExecutedRedeem;

    /// @notice The state of whether ops transaction fees will be paid by this contract or not. 
    bool public opsReadyState;

    /// @dev Initialization variables.
    address public immutable _initializer;
    bool private _isInitialized;

    /* ========== STORAGE ========== */

    struct Values {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }

    /* ========== EVENTS ========== */

    event UpdateOpsReadyState(bool newOpsReadyState);
    event InitialMint(address indexed user, uint256 amountBNB, uint256 amountHYDT, uint256 callingPrice);
    event Mint(address indexed caller, uint256 updatedPrice, uint256 amountHYDT, uint256 callingPrice);
    event Redeem(address indexed caller, uint256 amountHYDT, uint256 callingPrice);

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        _initializer = _msgSender();
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes external dependencies and state variables.
     * @dev This function can only be called once.
     * @param hydt_ The address of the `HYDT` contract.
     * @param reserve_ The address of the `Reserve` contract.
     * @param initialMintStartTime_ The unix timestamp at which initial minting will begin.
     */
    function initialize(/*address ops_, address taskCreator_,*/ address WBNB_, address hydt_, address reserve_, uint256 initialMintStartTime_) external {
        require(_msgSender() == _initializer, "Control: caller is not the initializer");
        // TODO uncomment
        require(!_isInitialized, "Control: already initialized");

        // require(ops_ != address(0), "Control: invalid Ops address");
        // require(taskCreator_ != address(0), "Control: invalid TaskCreator address");
        require(hydt_ != address(0), "Control: invalid HYDT address");
        require(reserve_ != address(0), "Control: invalid Reserve address");
        // OPS = IOps(ops_);
        // _gelato = IOps(ops_).gelato();
        // (address dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(taskCreator_);

        _grantRole(GOVERNOR_ROLE, _msgSender());
        _grantRole(CALLER_ROLE, _msgSender());
        // TODO future proofing needed?
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        WBNB= WBNB_;
        HYDT = IHYDT(hydt_);
        RESERVE = IReserve(reserve_);

        _initialMints.startTime = initialMintStartTime_;
        _dailyInitialMints.startTime = initialMintStartTime_;
        _initialMints.endTime = initialMintStartTime_ + THREE_MONTHS_TIME;
        _dailyInitialMints.endTime = initialMintStartTime_ + ONE_DAY_TIME;

        _delegateApprove(IERC20(hydt_), address(PANCAKE_ROUTER), true);
        _delegateApprove(IERC20(WBNB), address(PANCAKE_ROUTER), true);

        opsReadyState = true;

        _isInitialized = true;
    }

    // TODO remove this function
    // function test_initialMintStartTime(uint256 initialMintStartTime_) external {
    //     _initialMints.startTime = initialMintStartTime_;
    //     _dailyInitialMints.startTime = initialMintStartTime_;
    //     _initialMints.endTime = initialMintStartTime_ + THREE_MONTHS_TIME;
    //     _dailyInitialMints.endTime = initialMintStartTime_ + ONE_DAY_TIME;
    // }

    // // TODO remove this function
    // function test_oneDayTimeAndInitialMintStartTime(uint128 oneDayTime_) external {
    //     THREE_MONTHS_TIME = oneDayTime_ * 90;
    //     ONE_DAY_TIME = oneDayTime_;
    //     uint256 initialMintStartTime = block.timestamp;
    //     _initialMints.startTime = initialMintStartTime;
    //     _dailyInitialMints.startTime = initialMintStartTime;
    //     _initialMints.endTime = initialMintStartTime + THREE_MONTHS_TIME;
    //     _dailyInitialMints.endTime = initialMintStartTime + ONE_DAY_TIME;
    // }

    // TODO remove this function
    // function test_mintLimits(uint128 initialMintLimit_, uint128 dailyInitialMintLimit_) external {
    //     INITIAL_MINT_LIMIT = initialMintLimit_;
    //     DAILY_INITIAL_MINT_LIMIT = dailyInitialMintLimit_;
    // }

    /* ========== FUNCTIONS ========== */

    receive() external payable {

    }

    /**
     * @notice Updates the `opsReadyState`. Caller must have the `Governor` role.
     * @param newOpsReadyState The new state to assign to `opsReadyState`.
     */
    function updateOpsReadyState(bool newOpsReadyState) external onlyRole(GOVERNOR_ROLE) {
        require(opsReadyState != newOpsReadyState, "Control: OpsReadyState is already this state");
        opsReadyState = newOpsReadyState;

        emit UpdateOpsReadyState(newOpsReadyState);
    }

    /**
     * @notice Allows this contract to approve tokens being sent out. Caller must have the `Governor` role.
     * @param token The address of the token to approve.
     * @param guy The address of the spender.
     * @param isApproved The new state of the spender's allowance.
     */
    function delegateApprove(IERC20 token, address guy, bool isApproved) external onlyRole(GOVERNOR_ROLE) {
        _delegateApprove(token, guy, isApproved);
    }

    function _delegateApprove(IERC20 token, address guy, bool isApproved) internal {
        uint256 oldAllowance = token.allowance(address(this), guy);

        if (isApproved && oldAllowance != type(uint256).max) {
            if (oldAllowance < type(uint256).max && oldAllowance != 0) {
                uint256 wad = type(uint256).max - oldAllowance;
                SafeERC20.safeIncreaseAllowance(token, guy, wad);
            } else {
                uint256 wad = type(uint256).max;
                SafeERC20.safeApprove(IERC20(token), guy, wad);
            }
        } else if (!isApproved && oldAllowance != 0) {
            uint256 wad = 0;
            SafeERC20.safeApprove(IERC20(token), guy, wad);
        }
    }

    /**
     * @notice Gets total values for initial minting.
     * @return startTime The unix timestamp which denotes the start of initial minting.
     * @return endTime The unix timestamp which denotes the end of initial minting.
     * @return amountUSD The amount in USD that has been transacted via inital minting in total.
     */
    function getInitialMints() external view returns (uint256 startTime, uint256 endTime, uint256 amountUSD) {
        startTime = _initialMints.startTime;
        endTime = _initialMints.endTime;
        amountUSD = _initialMints.amount;
    }

    /**
     * @notice Gets daily values for initial minting.
     * @return startTime The unix timestamp which denotes the start of the day.
     * @return endTime The unix timestamp which denotes the end of the day.
     * @return amountUSD The amount in USD that has been transacted via inital minting in said day.
     */
    function getDailyInitialMints() external view returns (uint256 startTime, uint256 endTime, uint256 amountUSD) {
        startTime = _dailyInitialMints.startTime;
        endTime = _dailyInitialMints.endTime;
        amountUSD = _dailyInitialMints.amount;

        if (block.timestamp <= _initialMints.endTime && block.timestamp > _dailyInitialMints.endTime) {
            uint256 numberOfDays = (block.timestamp - _dailyInitialMints.startTime) / ONE_DAY_TIME;
            startTime = _dailyInitialMints.startTime + (numberOfDays * ONE_DAY_TIME);
            endTime = _dailyInitialMints.endTime + (numberOfDays * ONE_DAY_TIME);
            amountUSD = 0;
        }
    }

    /**
     * @notice Gets current HYDT price corresponding to the preferred pair.
     */
    function getCurrentPrice() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(HYDT);
        path[1] = WBNB;
        path[2] = USDT;
        uint256 amountIn = 1 * 1e18;
        uint256 price = DataFetcher.quoteRouted(amountIn, path);
        return price;
    }

    /**
     * @notice Used to mint HYDT in return for BNB. All transfers will be made at 1 HYDT per USD at current BNB/USD rates.
     */
    function initialMint() external payable {
        require(msg.value > 0, "Control: insufficient BNB amount");
        Values storage initialMints = _initialMints;
        Values storage dailyInitialMints = _dailyInitialMints;

        require(block.timestamp > _initialMints.startTime, "Control: initial mint not yet started");
        require(block.timestamp <= initialMints.endTime, "Control: initial mint ended");

        if (block.timestamp > dailyInitialMints.endTime) {
            uint256 numberOfDays = (block.timestamp - dailyInitialMints.startTime) / ONE_DAY_TIME;
            dailyInitialMints.startTime += numberOfDays * ONE_DAY_TIME;
            dailyInitialMints.endTime += numberOfDays * ONE_DAY_TIME;
            dailyInitialMints.amount = 0;
        }
        uint256 amountOut = DataFetcher.quote(msg.value, WBNB, USDT);

        require(
            INITIAL_MINT_LIMIT >=
            initialMints.amount + amountOut,
            "Control: invalid amount considering initial mint limit"
        );
        require(
            DAILY_INITIAL_MINT_LIMIT >=
            dailyInitialMints.amount + amountOut,
            "Control: invalid amount considering daily initial mint limit"
        );
        initialMints.amount += amountOut;
        dailyInitialMints.amount += amountOut;
        SafeETH.safeTransferETH(address(RESERVE), msg.value);
        HYDT.mint(_msgSender(), amountOut);

        emit InitialMint(_msgSender(), msg.value, amountOut, 1 * 1e18);
    }

    /**
     * @notice Called by ops to maintain peg. Caller must have the `Caller` role.
     * @param argument Denotes whether to mint or redeem.
     */
    function execute(uint8 argument) external onlyRole(CALLER_ROLE) {
        uint256 price = getCurrentPrice();

        if (argument == 0 && price > PRICE_UPPER_BOUND) {
            _mint(price);
        } else if (argument == 1 && price < PRICE_LOWER_BOUND) {
            _redeem();
        }

        if (opsReadyState) {
            (uint256 fee, address feeToken) = _getFeeDetails();
            RESERVE.withdraw(fee);
            _transfer(fee, feeToken);
        }
    }

    function _mint(uint256 price) internal {
        if (mintProgressCount < 0.1 * 1e18) {
            mintProgressCount += 1 * 1e18;
        }
        uint256 amountReserve = DataFetcher.quote(address(RESERVE).balance, WBNB, USDT);
        uint256 amountLiquidityHYDT = HYDT.balanceOf(
            DataFetcher.pairFor(
                address(HYDT),
                WBNB
            )
        );
 
        uint256 baseValue = (((price - (0.9 * 1e18)) ** 2) * amountReserve * (0.04 * 1e2)) / 1e38;
        uint256 firstValue = (baseValue * mintProgressCount) / 1e18;
        uint256 secondValue = ((0.0025 * 1e4) * amountLiquidityHYDT) / 1e4;
        uint256 amountMintHYDT = firstValue < secondValue ? firstValue : secondValue;

        HYDT.mint(address(this), amountMintHYDT);
        address[] memory path = new address[](2);
        path[0] = address(HYDT);
        path[1] = WBNB;
        uint256 amountOutMin = (PANCAKE_ROUTER.getAmountsOut(
            amountMintHYDT,
            path
        )[path.length - 1] * 97) / 100;
        PANCAKE_ROUTER.swapExactTokensForETH(
            amountMintHYDT,
            amountOutMin,
            path,
            address(RESERVE),
            block.timestamp + 300
        );

        uint256 oldPrice = price;
        price = getCurrentPrice();
        amountReserve = DataFetcher.quote(address(RESERVE).balance, WBNB, USDT);
        baseValue = (((price - (0.9 * 1e18)) ** 2) * amountReserve * (0.04 * 1e2)) / 1e38;
        uint256 reduction = (amountMintHYDT * 1e18) / baseValue;
        mintProgressCount = reduction > mintProgressCount ? 0 : mintProgressCount - reduction;

        lastExecutedMint = block.timestamp;

        emit Mint(_msgSender(), price, amountMintHYDT, oldPrice);
    }

    function _redeem() internal {
        uint256 price = getCurrentPrice();
        if (redeemProgressCount < 0.1 * 1e18) {
            redeemProgressCount += 1 * 1e18;
        }
        uint256 amountReserve = DataFetcher.quote(address(RESERVE).balance, WBNB, USDT);
        uint256 amountLiquidity = DataFetcher.quote(
            IERC20(WBNB).balanceOf(
                DataFetcher.pairFor(
                    address(HYDT),
                    WBNB
                )
            ),
            WBNB,
            USDT
        );

        uint256 baseValue = ((((1.1 * 1e18) - getCurrentPrice()) ** 2) * amountReserve * (0.004 * 1e3)) / 1e39;
        uint256 firstValue = (baseValue * redeemProgressCount) / 1e18;
        uint256 secondValue = ((0.0025 * 1e4) * amountLiquidity) / 1e4;
        uint256 amountRedeem = firstValue < secondValue ? firstValue : secondValue;
        uint256 amountRedeemBNB = DataFetcher.quote(amountRedeem, USDT, WBNB);

        RESERVE.withdraw(amountRedeemBNB);
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(HYDT);
        uint256 amountOutMin = (PANCAKE_ROUTER.getAmountsOut(
            amountRedeemBNB,
            path
        )[path.length - 1] * 97) / 100;
        uint256[] memory amounts = PANCAKE_ROUTER.swapExactETHForTokens{value: amountRedeemBNB}(
            amountOutMin,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 amountBurnHYDT = amounts[path.length - 1];
        HYDT.burn(amountBurnHYDT);

        // uint256 oldPrice = price;
        // price = getCurrentPrice();
        amountReserve = DataFetcher.quote(address(RESERVE).balance, WBNB, USDT);
        baseValue = ((((1.1 * 1e18) - getCurrentPrice()) ** 2) * amountReserve * (0.004 * 1e3)) / 1e39;
        uint256 reduction = (amountRedeem * 1e18) / baseValue;
        redeemProgressCount = reduction > redeemProgressCount ? 0 : redeemProgressCount - reduction;

        lastExecutedRedeem = block.timestamp;

        emit Redeem(_msgSender(), amountBurnHYDT, price);
    }
}