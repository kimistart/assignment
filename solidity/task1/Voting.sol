// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Voting {

    mapping(address => uint) candidateVotes;

    address[] private allCandidates;

    function vote(address candidate) external  {
        if(candidateVotes[candidate] == 0) {
            allCandidates.push(candidate);
        }
        candidateVotes[candidate]+=1;
    }

    function getVotes(address candidate) external view returns (uint) {
        return candidateVotes[candidate];
    }

    function resetVotes() external {
        for (uint i=0; i < allCandidates.length; i++) {
            candidateVotes[allCandidates[i]] = 0;
        }
    }
}