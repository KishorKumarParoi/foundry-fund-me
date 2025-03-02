## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

##### Step by step instructions and notes

### Foundry Fund-Me Project

- start with “forge init” and test with command “forge test”
- run “forge compile” and try to understand the error
- forge doesn’t automatic compile “AggregatorV3Interface” as it doesn’t support it
- run “forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 —no-commit”
- install latest smartcontractkit/chainlink-brownie-contracts version
- remappings: add this code to your foundry.toml file

```solidity
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
]
```

- now run “forge build” to check if code is all ok
- write FundMe.sol like this

```solidity
// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.19;
// 2. Imports

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();   // convention of writing error variable like this

/**
 * @title A sample Funding Contract
 * @author Kishor Paroi
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address public immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /**
     * Getter Functions
     */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

```

- write FundMe.t.sol test like this

```solidity
contract FundmeTest is Test {
    uint256 number = 1;
    FundMe fundme;

    function setUp() external {
        number = 100;
        fundme = new FundMe(address(0));
    }

    function testDemo() public view {
        // us -> FundMeTest -> FundMe
        console.log("Hello World");
        console.log("Number is: ", number);
        assertEq(number, 100);
        assertEq(fundme.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundme.i_owner());
        console.log(msg.sender);
        assertEq(fundme.i_owner(), address(this)); // owner of this contract basically FundMeTes
        // that'w why we are calling address(this)
        // assertEq(fundme.i_owner(), msg.sender); will show error
    }

}

run forge test
```

- write DeployFundMe.s.sol script

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";

contract DeployFundMe is Script {
    function run() external {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(address(0));
        console.log("FundMe address: ", address(fundMe));
        vm.stopBroadcast();
    }
}
```

- now let’s time for testing. There are four kind of test basically for blockchain i.e unit, integration, fork, staging
- **Fork Testing**: Testing on a forked mainnet or testnet to simulate real-world conditions and interactions with live contracts.
- **Unit Testing**: Testing individual functions or components in isolation to ensure they work as expected.
- **Integration Testing**: Testing the interaction between multiple components or contracts to ensure they work together correctly.
- **Stage Testing**: Testing the entire application in a staging environment that closely resembles the production environment to catch any issues before deployment.
- now add SEPOLIA_RPC_URL from alchemy to .env and command “source .env” and check if either it is accessible by echo $SEPOLIA_RPC_URL command
- run “forge test --match-test testPriceFeedVersionIsAccurate -vvvv” and you can see like this

```solidity
[FAIL: EvmError: Revert] testPriceFeedVersionIsAccurate() (gas: 7666)
Traces:
  [947981] FundmeTest::setUp()
    ├─ [887068] → new FundMe@0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
    │   └─ ← [Return] 4417 bytes of code
    └─ ← [Stop]

  [7666] FundmeTest::testPriceFeedVersionIsAccurate()
    ├─ [2633] FundMe::getVersion() [staticcall]
    │   ├─ [0] 0x0000000000000000000000000000000000000000::version() [staticcall]
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Revert] EvmError: Revert
```

- notice that here is EVMError which occured due to blank chain, when we ran the code it spins a blank chain by commanding anvil but can’t get through the version so get reverted. If we ran this command on real environment like “Sepolia Testnet” by providing —fork-url (fork-testing) to the command like this

```solidity
(base) ➜  foundry-fund-me git:(main) ✗ forge test --match-test testPriceFeedVersionIsAccurate -vvvv --fork-url $SEPOLIA_RPC_URL
[⠊] Compiling...
[⠒] Compiling 1 files with Solc 0.8.19
[⠑] Solc 0.8.19 finished in 534.54ms
Compiler run successful!

Ran 1 test for test/FundeMeTest.t.sol:FundmeTest
[PASS] testPriceFeedVersionIsAccurate() (gas: 19958)
Logs:
  Price Feed Version:  4

Traces:
  [19958] FundmeTest::testPriceFeedVersionIsAccurate()
    ├─ [7949] FundMe::getVersion() [staticcall]
    │   ├─ [2459] MockV3Aggregator::version() [staticcall]
    │   │   └─ ← [Return] 4
    │   └─ ← [Return] 4
    ├─ [0] console::log("Price Feed Version: ", 4) [staticcall]
    │   └─ ← [Stop]
    ├─ [0] VM::assertEq(4, 4) [staticcall]
    │   └─ ← [Return]
    └─ ← [Stop]

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 6.24s (1.13s CPU time)

Ran 1 test suite in 7.89s (6.24s CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

- if you got error then create a  **Mock AggregatorV3Interface like this**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    uint256 public mockVersion;

    constructor(uint256 _version) {
        mockVersion = _version;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "Mock V3 Aggregator";
    }

    function version() external view override returns (uint256) {
        return mockVersion;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, 0, 0, 0, _roundId);
    }

    function latestRoundData()
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 0, 0, 0, 0);
    }
}
```

- update the FundMeTest.sol code with this

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";

contract FundmeTest is Test {
    uint256 number = 1;
    FundMe fundme;
    MockV3Aggregator mockV3Aggregator;

    function setUp() external {
        number = 100;
        mockV3Aggregator = new MockV3Aggregator(4); // Initialize with version 4
        fundme = new FundMe(address(mockV3Aggregator));
    }

    function testDemo() public view {
        console.log("Hello World");
        console.log("Number is: ", number);
        assertEq(number, 100);
        assertEq(fundme.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        console.log("Owner: ", fundme.i_owner());
        console.log("msg.sender: ", msg.sender);
        console.log("Address: ", address(this));
        assertEq(fundme.i_owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        console.log("Price Feed Version: ", version);
        assertEq(version, 4);
    }
}
```

- then ran “forge test --match-test testPriceFeedVersionIsAccurate -vvvv “
- hope everything will be okay
