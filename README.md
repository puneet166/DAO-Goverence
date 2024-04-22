## Following the steps to deploy and use the smart contract -
### Setup -
1. Deploy GovToken smart contract. ``` govToken = new GovToken();```
2. Call the mint fun of GovToken to mint the tokens ```govToken.mint(USER, INITIAL_SUPPLY);```
3. Do the delegation to allow the vote ourselves or anybody. ```  govToken.delegate(USER);```
4. Deploy the TimeLock smart contract using the parameters - 
    *  MIN_DELAY - Min Delay in between pass/queues the purposal to execute the purposal.( This time in block ,1 mean 1 block if block time is 12 sec , 1 mean 12 sec).
    * proposers - Array of addresses who will purpose the purposal.
    * executors - Array of adresses who are going to excute the passed/queues purposals.
    * USER - This is Admin address who will control the entire timelock smart contract.
```timeLock = new TimeLock(MIN_DELAY, proposers, executors, USER); // everyone can propose and execute```
5. Deploy the Goverence smart contract using the parameters -
    * govToken - Address of govToken which use for voting.
    * timeLock- TimeLock smart contract address.

    ``` governor = new MyGovernor(govToken, timeLock);```

6. Grant the roles/set the roles in TimeLock -
    1. Set the purposerRole -
        * Get the bytes32 for the proposerRole using this fun -``` timeLock.PROPOSER_ROLE()``` 
        * Assign proposerRole to the governor address using this fun - ```timeLock.grantRole(proposerRole, address(governor));```
        * Get the bytes32 for the executorRole using this fun - ```timeLock.EXECUTOR_ROLE();```
        * Assign executorRole to the zero address so anyone can excute the purposal using this fun - ```timeLock.grantRole(executorRole, address(0)); // anyone can execute```
        * Get the bytes32 for the DEFAULT_ADMIN_ROLE using this fun -``` timeLock.DEFAULT_ADMIN_ROLE();```
        * Remove the default admin role => no more admin using this fun - ```timeLock.revokeRole(adminRole, USER); ```
    
7. Deploy Box / callable smart contract from goverence after purposal sucessfull - ```box = new Box(address(this));```.
8. Transfer the ownership of Box smart contract to the TimeLock, TimeLock smart contract will the owner of Box smart contract or timeLock owns the DAO and DAO owns the timeLock ,timeLock ultimately controls the box ```box.transferOwnership(address(timeLock));```

### Test the Goverence -
1. Propose the purposal for the voters ```uint256 proposalId = governor.propose(targets, values, calldatas, description);``` with the following params -

* targets - Target address or Box smart contract adress in the form of array ["0xaddress"].
* values - This value represent ETH (native currency value). if your target smart contract function is payable then pass the value in ETH/native currency otherwise leave is 0 in form of array - [0].
* calldatas - Target function's calldatas , Get the function's call data using this url - ```https://calldata.netlify.app/?source=post_page-----a49d166556b9--------------------------------```
or like this -  ``` bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);```
* description - any description which will helpful and useful in further . for ex- ```        string memory description = "store 888 in the box";```

2. After propose the purposal , let have check the status of the purposal with the following func and params - ```governor.state(proposalId)```
* proposalId - get the proposalId in logs of ```governor.propose(targets, values, calldatas, description);```.
* Proposal state code - ```Proposal state : 0/Pending, 1/Active, 2/Cancelled, 3/Defeated, 4/Succeeded, 5/Queued, 6/Expired, 7/Executed```

3. Once ```governor.state(proposalId)``` is return 1,  that mean purposal is in active phase and ready to vote.its totally depend time VOTING_DELAY which place in goverence smart contract.

4. Let's do the votes using ``` governor.castVoteWithReason(proposalId, voteWay, reason);``` with the following params -

* proposalId - Get the proposalId from the logs of using this fn - ```propose```.
* voteWay/VoteType - VoteType should be in 0, 1, 2 -  ```// support => VoteType : 0/Against, 1/For, 2/Abstain```.
* reason - use any reason in string ex - "888 is froggy!".

5. Once VOTING_PERIOD is over the status of the purposal will have 4 from 1 in Succeeded mode -

6. Then excute the ```queue function``` to go to the purposal from Succeeded to queue that mean ready for excute after MIN_DELAY passed. 

7. To execute the ```queue function``` with the following parameters -
 
 * targets - same like above in propose
 * values- same params like above in propose
 * calldatas - same params like above in propose
 * descriptionHash - This params you will get from ```https://calldata.netlify.app/?source=post_page-----a49d166556b9--------------------------------```
 *    ```governor.queue(targets, values, calldatas, descriptionHash);```

8. You will get the status of purposal using ``governor.state(proposalId))``.this time return value should be 5 in 5/Queued.
9. Now time to excute the purposal - Make sure to excute the purposal (anybody can excute the purposal)also make sure time in timelock must be passed . if yes you can or anybody can execute the purposal if not wait for timlock MIN_DELAY to pass. 

10. Once MIN_DELAY completed in timelock smart contract to execute the purposal usng below params```governor.execute(targets, values, calldatas, descriptionHash);``` -
 * targets - same like above in propose
 * values- same params like above in propose
 * calldatas - same params like above in propose
 * descriptionHash - This params you will get from ```https://calldata.netlify.app/?source=post_page-----a49d166556b9--------------------------------```
 *    ```governor.queue(targets, values, calldatas, descriptionHash);```



 Finaly - you purposal sucessfully executed . now you can check the upate value of BOX.sol file smart contract.
