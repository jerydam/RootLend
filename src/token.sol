// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Root is ERC20, Ownable {
 
 
    constructor(address _initialowner) ERC20("Root", "NXF") Ownable(_initialowner) {
        _mint(_initialowner, 1000000 ether);
        
        _mint(0xE122199bB9617d8B0e814aC903042990155015b4, 1000000 ether);
    }

    function mint(address _to, uint amount) public onlyOwner  {
        _mint(_to, amount);
        
    }


}