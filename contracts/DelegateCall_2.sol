// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Logica {
    address public owner;
    uint256 public limit;

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }

    function changeLimit(uint256 _limit) public {
        limit = _limit;
    }
}

contract Proxy {
    uint256 public limit; // slot 1 en Logica. ERROR
    address public owner; // slot 0 en Logica. ERROR

    function newOwner(address _target) public {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("changeOwner(address)", msg.sender)
        );
        require(success);
    }

    function newLimit(address _target) public {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("changeLimit(uint256)", 1000)
        );
        require(success);
    }
}
