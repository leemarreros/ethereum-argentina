// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Proxy {
    // unstructured storage
    // No es parte del storage layout
    // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    fallback() external {
        address imp = getImplementation();
        (bool success, ) = imp.delegatecall(msg.data);
        require(success);
    }

    // assembly para leer el slot
    function getValueAtSlot(uint256 slot) public view returns (uint256) {
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    //////////////////////////////////////////////////////////////////////
    // assembly para guardar el address de la implementation sin colisión
    function setImplementation(address impAddress) public {
        assembly {
            sstore(IMPLEMENTATION_SLOT, impAddress)
        }
    }

    function getImplementation() public view returns (address impAddress) {
        assembly {
            impAddress := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Logica1 {
    uint256 amount;

    function operate() public {
        amount += 10;
    }

    function calculateEncoding() public pure returns (bytes memory) {
        return abi.encodeWithSignature("operate()");
    }
}

contract Logica2 {
    uint256 amount;
    uint256 amount2;

    function operate() public {
        amount *= 2;
    }

    function setAmount2() public {
        amount2 = 2023;
    }

    function calculateEncoding() public pure returns (bytes memory) {
        return abi.encodeWithSignature("setAmount2()");
    }
}
