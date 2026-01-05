// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BeggingContract {

    address payable private owner;

    address[] private allDonors;

    mapping (address => uint) juanzeng;

    //捐赠时间
    uint public donationStartTime;
    uint public donationEndTime;

    event Donation(address from,uint amount);

    constructor (uint _startTime,uint _endTime) {
        owner = payable (msg.sender);

        require(_endTime > _startTime,"time error");

        donationStartTime = _startTime;
        donationEndTime = _endTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"only owner can withdraw");
        _;
    }

    modifier onlyDuringDonationPeriod() {
        require(block.timestamp >= donationStartTime && block.timestamp <= donationEndTime,
        "only allowed during the specified time period");
        _;
    }

    //向合约发送以太币，记录捐赠信息
    function donate() payable external onlyDuringDonationPeriod {
        juanzeng[msg.sender] += msg.value;

        if(juanzeng[msg.sender] == msg.value) {
            allDonors.push(msg.sender);
        }

        emit Donation(msg.sender,msg.value);
    }

    //合约所有者提取所有资金
    function withdraw() external onlyOwner{
       uint max = address(this).balance;
       require(max > 0,"no funds to withdraw");
       owner.transfer(max);
    }

    //查询某个地址的捐赠金额
    function getDonation(address add) external view returns(uint) {
        return juanzeng[add];
    }

    //显示前三个地址
    function sort() public view returns(address[] memory) {
        address[] memory donors = allDonors;
        uint len = allDonors.length;
        //前三名
        address[3] memory topAddresses;
        uint[3] memory topAmounts;

        for (uint i=0;i<len;i++) {
            address donor = donors[i];
            uint amount = juanzeng[donor];

            if(amount > topAmounts[0]) {
                topAmounts[2] = topAmounts[1];
                topAddresses[2] = topAddresses[1];

                topAmounts[1] = topAmounts[0];
                topAddresses[1] = topAddresses[0];

                topAmounts[0] = amount;
                topAddresses[0] = donor;
            } else if(amount > topAmounts[1]) {
                topAmounts[2] = topAmounts[1];
                topAddresses[2] = topAddresses[1];

                topAmounts[1] = amount;
                topAddresses[1] = donor; 
            } else if(amount > topAmounts[2]) {
                topAmounts[2] = amount;
                topAddresses[2] = donor;
            }
        }

        address[] memory top3Donors = new address[](3);
        top3Donors[0] = topAddresses[0];
        top3Donors[1] = topAddresses[1];
        top3Donors[2] = topAddresses[2];

        return top3Donors;
    }
}