// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IRouter {
    function WETH() external view returns (address);
    function factory() external view returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FrogsInu is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address payable;

    address public constant zeroAddr = address(0);

    IRouter public immutable router;
    address public swapPair;

    bool private swapping;

    address public marketing;

    uint256 private supply = 420 * 1e3 * 1e9 * 1e9;

    uint256 public fee = 7;
    uint256 private startBlock;
    bool private starting;
    uint256 private maxBuy = supply;

    uint256 private transferFeeAt = supply * 5 / 10000; // 0.05%

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) private isBlackList;

    constructor(IRouter router_, address marketing_) ERC20("Frogs Inu", "FrogS") {
        router = router_;
        swapPair = IFactory(router.factory()).createPair(address(this), router.WETH());
        marketing = marketing_;

        excludeFromFee(marketing, true);
        excludeFromFee(owner(), true);
        excludeFromFee(address(this), true);

        _approve(address(this), address(router), ~uint256(0));

        _mint(owner(), supply);
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function excludeFromFee(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFee[account] = isExcluded;
    }

    function _firstBlocksProcess(address from, address to) private {
        require(!isBlackList[from] && !isBlackList[to], "blacklist");
        if (startBlock == 0 && to == swapPair) {
            starting = true;
            fee = 15;
            startBlock = block.number;
            maxBuy = supply / 100;
            return;
        } else if (starting == true && block.number <= (startBlock + 2)) {
            fee = 7;
        } else if (starting == true && block.number > (startBlock + 3)) {
            fee = 7;
            starting = false;
            maxBuy = supply;
        }
        if(starting == true && from == swapPair && block.number <= (startBlock + 1)) {
            isBlackList[to] = true;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != zeroAddr, "ERC20: transfer from the zero address");
        require(to != zeroAddr, "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        _firstBlocksProcess(from, to);

        uint256 feeInContract = balanceOf(address(this));
        bool canSwap = feeInContract >= transferFeeAt;
        if (
            canSwap &&
            from != swapPair &&
            !swapping &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            swapping = true;
            _swapAndTransferFee(feeInContract);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 feeAmount = 0;
            if(from == swapPair) {
                require(amount <= maxBuy, "can not buy");
                feeAmount = amount.mul(fee).div(100);
            } else if(to == swapPair) {
                feeAmount = amount.mul(fee).div(100);
            }

            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                amount = amount.sub(feeAmount);
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapAndTransferFee(uint256 feeAmount) private {
        _swapForETH(feeAmount);
        uint256 ethAmount = address(this).balance;

        payable(marketing).sendValue(ethAmount);
    }

    function _swapForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}