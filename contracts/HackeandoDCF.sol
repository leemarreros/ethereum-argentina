// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Libreria {
    address[256] public owners;
    address libreria;

    function initWallet(address[] memory _owners) public {
        for (uint256 i; i < _owners.length; i++) {
            owners[i] = _owners[i];
        }
    }
    // otros metodos
}

contract Wallet {
    address[256] public owners;
    address libreria;

    constructor(address[] memory _owners, address _libreria) {
        libreria = _libreria;
        (bool success, ) = _libreria.delegatecall(
            abi.encodeWithSignature("initWallet(address[])", _owners)
        );
        require(success);
    }

    fallback() external {
        // ...
        libreria.delegatecall(msg.data);
    }

    function execute() public {
        /*...*/
    }
}

contract CalculateCalldata {
    function calculateEncoding(
        address[] memory _owners
    ) public pure returns (bytes memory) {
        return abi.encodeWithSignature("initWallet(address[])", _owners);
    }
}
