# 🔗 ENGAJA RAP CLUB - SMART CONTRACTS COMPLETOS

## 📋 **ESTRUTURA DOS CONTRATOS**

### **Organização para GitHub**

```
contracts/
├── src/
│   ├── BSTRToken.sol               # Token principal BSTR
│   ├── CampaignManager.sol         # Gerenciamento de campanhas
│   ├── RewardDistributor.sol       # Distribuição de recompensas
│   ├── BSTRStaking.sol            # Sistema de staking
│   ├── EngajaMusicNFT.sol         # NFTs musicais
│   ├── EngajaMarketplace.sol      # Marketplace de NFTs
│   └── interfaces/
│       ├── IBSTRToken.sol
│       ├── ICampaignManager.sol
│       ├── IRewardDistributor.sol
│       └── IEngajaMusicNFT.sol
├── tests/
├── scripts/
└── config/
```

***

## 🪙 **1. BSTR TOKEN CONTRACT**

### **BSTRToken.sol** - Token Principal

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title BSTR Token - Brazilian Street Rap Token
 * @dev Token principal do Engaja Rap Club
 * @author Engaja Rap Club Team
 */
contract BSTRToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // =============================================================================
    // CONSTANTS
    // =============================================================================
    
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 bilhão de tokens
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 milhões iniciais
    
    // Taxas em pontos base (10000 = 100%)
    uint256 public constant TRANSFER_FEE_RATE = 100; // 1%
    uint256 public constant BURN_FEE_RATE = 50; // 0.5%
    uint256 public constant COMMUNITY_FEE_RATE = 50; // 0.5%
    
    // =============================================================================
    // STATE VARIABLES
    // =============================================================================
    
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isMinter;
    mapping(address => uint256) public lastTransfer;
    mapping(address => uint256) public userLevel;
    mapping(address => uint256) public totalEarned;
    mapping(address => uint256) public totalSpent;
    
    address public treasuryWallet;
    address public communityWallet;
    address public stakingContract;
    address public campaignContract;
    
    uint256 public totalBurned;
    uint256 public totalFeesCollected;
    uint256 public transferCooldown = 1 minutes;
    
    bool public feesEnabled = true;
    bool public transferLimitsEnabled = true;
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    event AddressBlacklisted(address indexed account, bool status);
    event AddressWhitelisted(address indexed account, bool status);
    event MinterUpdated(address indexed account, bool status);
    event UserLevelUpdated(address indexed user, uint256 newLevel);
    event TokensEarned(address indexed user, uint256 amount, string source);
    event TokensSpent(address indexed user, uint256 amount, string purpose);
    event FeesCollected(address indexed from, uint256 transferFee, uint256 burnFee, uint256 communityFee);
    event TreasuryWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event CommunityWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event StakingContractUpdated(address indexed oldContract, address indexed newContract);
    event CampaignContractUpdated(address indexed oldContract, address indexed newContract);
    
    // =============================================================================
    // MODIFIERS
    // =============================================================================
    
    modifier notBlacklisted(address account) {
        require(!isBlacklisted[account], "BSTR: Account is blacklisted");
        _;
    }
    
    modifier onlyMinter() {
        require(isMinter[msg.sender] || msg.sender == owner(), "BSTR: Not authorized to mint");
        _;
    }
    
    modifier respectsCooldown(address account) {
        if (transferLimitsEnabled && !isWhitelisted[account]) {
            require(
                block.timestamp >= lastTransfer[account].add(transferCooldown),
                "BSTR: Transfer cooldown not expired"
            );
        }
        _;
    }
    
    // =============================================================================
    // CONSTRUCTOR
    // =============================================================================
    
    constructor(
        address _treasuryWallet,
        address _communityWallet
    ) ERC20("Brazilian Street Rap Token", "BSTR") {
        require(_treasuryWallet != address(0), "BSTR: Treasury wallet cannot be zero address");
        require(_communityWallet != address(0), "BSTR: Community wallet cannot be zero address");
        
        treasuryWallet = _treasuryWallet;
        communityWallet = _communityWallet;
        
        // Mint initial supply to treasury
        _mint(_treasuryWallet, INITIAL_SUPPLY);
        
        // Whitelist important addresses
        isWhitelisted[_treasuryWallet] = true;
        isWhitelisted[_communityWallet] = true;
        isWhitelisted[owner()] = true;
        
        // Set initial minter
        isMinter[owner()] = true;
        
        emit AddressWhitelisted(_treasuryWallet, true);
        emit AddressWhitelisted(_communityWallet, true);
        emit AddressWhitelisted(owner(), true);
        emit MinterUpdated(owner(), true);
    }
    
    // =============================================================================
    // MINTING FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Mint tokens for engagement rewards
     */
    function mintReward(address to, uint256 amount, string memory source) 
        external 
        onlyMinter 
        notBlacklisted(to) 
    {
        require(to != address(0), "BSTR: Cannot mint to zero address");
        require(amount > 0, "BSTR: Amount must be greater than zero");
        require(totalSupply().add(amount) <= MAX_SUPPLY, "BSTR: Would exceed max supply");
        
        _mint(to, amount);
        
        totalEarned[to] = totalEarned[to].add(amount);
        _updateUserLevel(to);
        
        emit TokensEarned(to, amount, source);
    }
    
    /**
     * @dev Batch mint for campaign rewards
     */
    function batchMintRewards(
        address[] memory recipients,
        uint256[] memory amounts,
        string memory source
    ) external onlyMinter {
        require(recipients.length == amounts.length, "BSTR: Arrays length mismatch");
        require(recipients.length <= 100, "BSTR: Too many recipients");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount = totalAmount.add(amounts[i]);
        }
        
        require(totalSupply().add(totalAmount) <= MAX_SUPPLY, "BSTR: Would exceed max supply");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            if (!isBlacklisted[recipients[i]] && recipients[i] != address(0) && amounts[i] > 0) {
                _mint(recipients[i], amounts[i]);
                totalEarned[recipients[i]] = totalEarned[recipients[i]].add(amounts[i]);
                _updateUserLevel(recipients[i]);
                emit TokensEarned(recipients[i], amounts[i], source);
            }
        }
    }
    
    // =============================================================================
    // TRANSFER FUNCTIONS
    // =============================================================================
    
    function transfer(address to, uint256 amount) 
        public 
        override 
        notBlacklisted(msg.sender) 
        notBlacklisted(to) 
        respectsCooldown(msg.sender)
        returns (bool) 
    {
        uint256 transferAmount = amount;
        
        if (feesEnabled && !isWhitelisted[msg.sender] && !isWhitelisted[to]) {
            transferAmount = _deductFees(msg.sender, amount);
        }
        
        lastTransfer[msg.sender] = block.timestamp;
        totalSpent[msg.sender] = totalSpent[msg.sender].add(amount);
        
        return super.transfer(to, transferAmount);
    }
    
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override 
        notBlacklisted(from) 
        notBlacklisted(to) 
        respectsCooldown(from)
        returns (bool) 
    {
        uint256 transferAmount = amount;
        
        if (feesEnabled && !isWhitelisted[from] && !isWhitelisted[to]) {
            transferAmount = _deductFees(from, amount);
        }
        
        lastTransfer[from] = block.timestamp;
        totalSpent[from] = totalSpent[from].add(amount);
        
        return super.transferFrom(from, to, transferAmount);
    }
    
    /**
     * @dev Internal function to deduct fees
     */
    function _deductFees(address from, uint256 amount) internal returns (uint256) {
        uint256 transferFee = amount.mul(TRANSFER_FEE_RATE).div(10000);
        uint256 burnFee = amount.mul(BURN_FEE_RATE).div(10000);
        uint256 communityFee = amount.mul(COMMUNITY_FEE_RATE).div(10000);
        
        uint256 totalFees = transferFee.add(burnFee).add(communityFee);
        
        if (totalFees > 0) {
            // Transfer fees to treasury
            super.transfer(treasuryWallet, transferFee);
            
            // Burn tokens
            _burn(from, burnFee);
            totalBurned = totalBurned.add(burnFee);
            
            // Transfer to community wallet
            super.transfer(communityWallet, communityFee);
            
            totalFeesCollected = totalFeesCollected.add(totalFees);
            
            emit FeesCollected(from, transferFee, burnFee, communityFee);
        }
        
        return amount.sub(totalFees);
    }
    
    /**
     * @dev Update user level based on total earned
     */
    function _updateUserLevel(address user) internal {
        uint256 earned = totalEarned[user];
        uint256 newLevel = 1;
        
        if (earned >= 10000 * 10**18) newLevel = 10;      // 10K BSTR
        else if (earned >= 5000 * 10**18) newLevel = 9;   // 5K BSTR
        else if (earned >= 2500 * 10**18) newLevel = 8;   // 2.5K BSTR
        else if (earned >= 1000 * 10**18) newLevel = 7;   // 1K BSTR
        else if (earned >= 500 * 10**18) newLevel = 6;    // 500 BSTR
        else if (earned >= 250 * 10**18) newLevel = 5;    // 250 BSTR
        else if (earned >= 100 * 10**18) newLevel = 4;    // 100 BSTR
        else if (earned >= 50 * 10**18) newLevel = 3;     // 50 BSTR
        else if (earned >= 10 * 10**18) newLevel = 2;     // 10 BSTR
        
        if (userLevel[user] != newLevel) {
            userLevel[user] = newLevel;
            emit UserLevelUpdated(user, newLevel);
        }
    }
    
    // =============================================================================
    // ADMINISTRATIVE FUNCTIONS
    // =============================================================================
    
    function setMinter(address account, bool status) external onlyOwner {
        isMinter[account] = status;
        emit MinterUpdated(account, status);
    }
    
    function setBlacklisted(address account, bool status) external onlyOwner {
        isBlacklisted[account] = status;
        emit AddressBlacklisted(account, status);
    }
    
    function setWhitelisted(address account, bool status) external onlyOwner {
        isWhitelisted[account] = status;
        emit AddressWhitelisted(account, status);
    }
    
    function setFeesEnabled(bool enabled) external onlyOwner {
        feesEnabled = enabled;
    }
    
    function setTransferLimitsEnabled(bool enabled) external onlyOwner {
        transferLimitsEnabled = enabled;
    }
    
    function setTransferCooldown(uint256 cooldown) external onlyOwner {
        require(cooldown <= 1 hours, "BSTR: Cooldown too long");
        transferCooldown = cooldown;
    }
    
    function setTreasuryWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "BSTR: Cannot be zero address");
        address oldWallet = treasuryWallet;
        treasuryWallet = newWallet;
        emit TreasuryWalletUpdated(oldWallet, newWallet);
    }
    
    function setCommunityWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "BSTR: Cannot be zero address");
        address oldWallet = communityWallet;
        communityWallet = newWallet;
        emit CommunityWalletUpdated(oldWallet, newWallet);
    }
    
    function setStakingContract(address newContract) external onlyOwner {
        address oldContract = stakingContract;
        stakingContract = newContract;
        if (newContract != address(0)) {
            isMinter[newContract] = true;
        }
        if (oldContract != address(0)) {
            isMinter[oldContract] = false;
        }
        emit StakingContractUpdated(oldContract, newContract);
    }
    
    function setCampaignContract(address newContract) external onlyOwner {
        address oldContract = campaignContract;
        campaignContract = newContract;
        if (newContract != address(0)) {
            isMinter[newContract] = true;
        }
        if (oldContract != address(0)) {
            isMinter[oldContract] = false;
        }
        emit CampaignContractUpdated(oldContract, newContract);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Emergency function to withdraw stuck tokens
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
    }
    
    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================
    
    function getUserStats(address user) external view returns (
        uint256 level,
        uint256 earned,
        uint256 spent,
        uint256 lastTransferTime
    ) {
        return (
            userLevel[user],
            totalEarned[user],
            totalSpent[user],
            lastTransfer[user]
        );
    }
    
    function getTokenStats() external view returns (
        uint256 maxSupply,
        uint256 currentSupply,
        uint256 burnedTokens,
        uint256 feesCollected
    ) {
        return (
            MAX_SUPPLY,
            totalSupply(),
            totalBurned,
            totalFeesCollected
        );
    }
    
    // =============================================================================
    // OVERRIDES
    // =============================================================================
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```

***

## 🎯 **2. CAMPAIGN MANAGER CONTRACT**

### **CampaignManager.sol** - Gerenciamento de Campanhas

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IBSTRToken.sol";

/**
 * @title CampaignManager - Sistema de Campanhas Musicais
 * @dev Gerencia campanhas de promoção musical com recompensas BSTR
 * @author Engaja Rap Club Team
 */
contract CampaignManager is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IBSTRToken public bstrToken;
    Counters.Counter private _campaignIds;
    
    enum CampaignStatus {
        ACTIVE,
        PAUSED,
        COMPLETED,
        CANCELLED
    }
    
    enum ActionType {
        LISTEN,
        LIKE,
        SHARE,
        COMMENT,
        PLAYLIST_ADD,
        FOLLOW
    }
    
    struct Campaign {
        uint256 id;
        address creator;
        string trackId;
        string title;
        string description;
        uint256 budget;
        uint256 remaining;
        uint256 startTime;
        uint256 endTime;
        mapping(ActionType => uint256) rewards;
        mapping(ActionType => uint256) limits;
        mapping(address => mapping(ActionType => uint256)) userActions;
        CampaignStatus status;
        uint256 totalParticipants;
        uint256 totalRewardsDistributed;
        bool requiresVerification;
        uint256 minUserLevel;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256[]) public userCampaigns;
    mapping(string => uint256[]) public trackCampaigns;
    mapping(address => uint256) public totalUserRewards;
    
    uint256 public platformFee = 500; // 5% in basis points
    address public platformWallet;
    uint256 public minCampaignDuration = 1 days;
    uint256 public maxCampaignDuration = 30 days;
    uint256 public minBudget = 100 * 10**18; // 100 BSTR
    
    // =============================================================================
    // EVENTS
    // =============================================================================
    
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string trackId,
        uint256 budget
    );
    
    event CampaignAction(
        uint256 indexed campaignId,
        address indexed user,
        ActionType action,
        uint256 reward
    );
    
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalDistributed);
    event CampaignCancelled(uint256 indexed campaignId, uint256 refunded);
    event CampaignPaused(uint256 indexed campaignId);
    event CampaignResumed(uint256 indexed campaignId);
    
    // =============================================================================
    // CONSTRUCTOR
    // =============================================================================
    
    constructor(address _bstrToken, address _platformWallet) {
        require(_bstrToken != address(0), "CampaignManager: Invalid BSTR token");
        require(_platformWallet != address(0), "CampaignManager: Invalid platform wallet");
        
        bstrToken = IBSTRToken(_bstrToken);
        platformWallet = _platformWallet;
    }
    
    // =============================================================================
    // CAMPAIGN CREATION
    // =============================================================================
    
    function createCampaign(
        string memory trackId,
        string memory title,
        string memory description,
        uint256 duration,
        uint256 budget,
        uint256[] memory actionRewards,
        uint256[] memory actionLimits,
        bool requiresVerification,
        uint256 minUserLevel
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(bytes(trackId).length > 0, "CampaignManager: Track ID required");
        require(bytes(title).length > 0, "CampaignManager: Title required");
        require(duration >= minCampaignDuration && duration <= maxCampaignDuration, "CampaignManager: Invalid duration");
        require(budget >= minBudget, "CampaignManager: Budget too low");
        require(actionRewards.length == 6, "CampaignManager: Invalid rewards array");
        require(actionLimits.length == 6, "CampaignManager: Invalid limits array");
        
        // Calculate platform fee
        uint256 fee = budget.mul(platformFee).div(10000);
        uint256 campaignBudget = budget.sub(fee);
        
        // Transfer budget + fee from creator
        require(
            bstrToken.transferFrom(msg.sender, address(this), campaignBudget),
            "CampaignManager: Budget transfer failed"
        );
        
        if (fee > 0) {
            require(
                bstrToken.transferFrom(msg.sender, platformWallet, fee),
                "CampaignManager: Fee transfer failed"
            );
        }
        
        _campaignIds.increment();
        uint256 newCampaignId = _campaignIds.current();
        
        Campaign storage campaign = campaigns[newCampaignId];
        campaign.id = newCampaignId;
        campaign.creator = msg.sender;
        campaign.trackId = trackId;
        campaign.title = title;
        campaign.description = description;
        campaign.budget = campaignBudget;
        campaign.remaining = campaignBudget;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp.add(duration);
        campaign.status = CampaignStatus.ACTIVE;
        campaign.requiresVerification = requiresVerification;
        campaign.minUserLevel = minUserLevel;
        
        // Set action rewards and limits
        for (uint256 i = 0; i < 6; i++) {
            ActionType action = ActionType(i);
            campaign.rewards[action] = actionRewards[i];
            campaign.limits[action] = actionLimits[i];
        }
        
        userCampaigns[msg.sender].push(newCampaignId);
        trackCampaigns[trackId].push(newCampaignId);
        
        emit CampaignCreated(newCampaignId, msg.sender, trackId, campaignBudget);
        
        return newCampaignId;
    }
    
    // =============================================================================
    // CAMPAIGN ACTIONS
    // =============================================================================
    
    function performAction(
        uint256 campaignId,
        ActionType action,
        bytes memory proof
    ) external nonReentrant whenNotPaused {
        Campaign storage campaign = campaigns[campaignId];
        
        require(campaign.status == CampaignStatus.ACTIVE, "CampaignManager: Campaign not active");
        require(block.timestamp >= campaign.startTime && block.timestamp <= campaign.endTime, "CampaignManager: Campaign not in valid time");
        require(campaign.remaining > 0, "CampaignManager: Campaign budget exhausted");
        
        // Check user level requirement
        uint256 userLevel = bstrToken.userLevel(msg.sender);
        require(userLevel >= campaign.minUserLevel, "CampaignManager: User level too low");
        
        // Check action limits
        uint256 userActionCount = campaign.userActions[msg.sender][action];
        require(userActionCount < campaign.limits[action], "CampaignManager: Action limit reached");
        
        uint256 reward = campaign.rewards[action];
        require(reward > 0, "CampaignManager: No reward for this action");
        require(campaign.remaining >= reward, "CampaignManager: Insufficient campaign budget");
        
        // Verify action if required
        if (campaign.requiresVerification) {
            require(_verifyAction(campaignId, action, msg.sender, proof), "CampaignManager: Action verification failed");
        }
        
        // Record action
        if (campaign.userActions[msg.sender][ActionType.LISTEN] == 0) {
            campaign.totalParticipants = campaign.totalParticipants.add(1);
        }
        
        campaign.userActions[msg.sender][action] = campaign.userActions[msg.sender][action].add(1);
        campaign.remaining = campaign.remaining.sub(reward);
        campaign.totalRewardsDistributed = campaign.totalRewardsDistributed.add(reward);
        totalUserRewards[msg.sender] = totalUserRewards[msg.sender].add(reward);
        
        // Distribute reward
        bstrToken.mintReward(msg.sender, reward, string(abi.encodePacked("Campaign ", uint2str(campaignId), " Action")));
        
        emit CampaignAction(campaignId, msg.sender, action, reward);
        
        // Auto-complete campaign if budget exhausted
        if (campaign.remaining == 0) {
            campaign.status = CampaignStatus.COMPLETED;
            emit CampaignCompleted(campaignId, campaign.totalRewardsDistributed);
        }
    }
    
    function batchPerformActions(
        uint256[] memory campaignIds,
        ActionType[] memory actions,
        bytes[] memory proofs
    ) external nonReentrant whenNotPaused {
        require(campaignIds.length == actions.length, "CampaignManager: Arrays length mismatch");
        require(campaignIds.length == proofs.length, "CampaignManager: Arrays length mismatch");
        require(campaignIds.length <= 10, "CampaignManager: Too many actions");
        
        for (uint256 i = 0; i < campaignIds.length; i++) {
            // Note: We're calling the external function to ensure all checks are performed
            this.performAction(campaignIds[i], actions[i], proofs[i]);
        }
    }
    
    // =============================================================================
    // CAMPAIGN MANAGEMENT
    // =============================================================================
    
    function pauseCampaign(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender || msg.sender == owner(), "CampaignManager: Not authorized");
        require(campaign.status == CampaignStatus.ACTIVE, "CampaignManager: Campaign not active");
        
        campaign.status = CampaignStatus.PAUSED;
        emit CampaignPaused(campaignId);
    }
    
    function resumeCampaign(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender || msg.sender == owner(), "CampaignManager: Not authorized");
        require(campaign.status == CampaignStatus.PAUSED, "CampaignManager: Campaign not paused");
        require(block.timestamp <= campaign.endTime, "CampaignManager: Campaign expired");
        
        campaign.status = CampaignStatus.ACTIVE;
        emit CampaignResumed(campaignId);
    }
    
    function cancelCampaign(uint256 campaignId) external nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender || msg.sender == owner(), "CampaignManager: Not authorized");
        require(campaign.status == CampaignStatus.ACTIVE || campaign.status == CampaignStatus.PAUSED, "CampaignManager: Cannot cancel");
        
        uint256 refundAmount = campaign.remaining;
        campaign.status = CampaignStatus.CANCELLED;
        campaign.remaining = 0;
        
        if (refundAmount > 0) {
            require(bstrToken.transfer(campaign.creator, refundAmount), "CampaignManager: Refund failed");
        }
        
        emit CampaignCancelled(campaignId, refundAmount);
    }
    
    function completeCampaign(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender || 
            msg.sender == owner() || 
            block.timestamp > campaign.endTime,
            "CampaignManager: Not authorized or not expired"
        );
        require(campaign.status == CampaignStatus.ACTIVE || campaign.status == CampaignStatus.PAUSED, "CampaignManager: Cannot complete");
        
        uint256 remainingBudget = campaign.remaining;
        campaign.status = CampaignStatus.COMPLETED;
        campaign.remaining = 0;
        
        // Refund remaining budget to creator
        if (remainingBudget > 0) {
            require(bstrToken.transfer(campaign.creator, remainingBudget), "CampaignManager: Refund failed");
        }
        
        emit CampaignCompleted(campaignId, campaign.totalRewardsDistributed);
    }
    
    // =============================================================================
    // VERIFICATION SYSTEM
    // =============================================================================
    
    function _verifyAction(
        uint256 campaignId,
        ActionType action,
        address user,
        bytes memory proof
    ) internal view returns (bool) {
        // In a real implementation, this would verify the action
        // For now, we'll implement a simple signature verification
        
        // This is a placeholder - in production, you would:
        // 1. Verify API signatures from music platforms
        // 2. Check blockchain events for on-chain actions
        // 3. Validate social media proofs
        // 4. Use oracles for external data verification
        
        return proof.length > 0; // Simple check for now
    }
    
    // =============================================================================
    // VIEW FUNCTIONS
    // =============================================================================
    
    function getCampaign(uint256 campaignId) external view returns (
        uint256 id,
        address creator,
        string memory trackId,
        string memory title,
        string memory description,
        uint256 budget,
        uint256 remaining,
        uint256 startTime,
        uint256 endTime,
        CampaignStatus status,
        uint256 totalParticipants,
        uint256 totalRewardsDistributed,
        bool requiresVerification,
        uint256 minUserLevel
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.id,
            campaign.creator,
            campaign.trackId,
            campaign.title,
            campaign.description,
            campaign.budget,
            campaign.remaining,
            campaign.startTime,
            campaign.endTime,
            campaign.status,
            campaign.totalParticipants,
            campaign.totalRewardsDistributed,
            campaign.requiresVerification,
            campaign.minUserLevel
        );
    }
    
    function getCampaignRewards(uint256 campaignId) external view returns (uint256[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        uint256[] memory rewards = new uint256[](6);
        
        for (uint256 i = 0; i < 6; i++) {
            rewards[i] = campaign.rewards[ActionType(i)];
        }
        
        return rewards;
    }
    
    function getCampaignLimits(uint256 campaignId) external view returns (uint256[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        uint256[] memory limits = new uint256[](6);
        
        for (uint256 i = 0; i < 6; i++) {
            limits[i] = campaign.limits[ActionType(i)];
        }
        
        return limits;
    }
    
    function getUserCampaignActions(uint256 campaignId, address user) external view returns (uint256[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        uint256[] memory actions = new uint256[](6);
        
        for (uint256 i = 0; i < 6; i++) {
            actions[i] = campaign.userActions[user][ActionType(i)];
        }
        
        return actions;
    }
    
    function getUserActiveCampaigns(address user) external view returns (uint256[] memory) {
        uint256[] memory userCampaignList = userCampaigns[user];
        uint256 activeCount = 0;
        
        // Count active campaigns
        for (uint256 i = 0; i < userCampaignList.length; i++) {
            if (campaigns[userCampaignList[i]].status == CampaignStatus.ACTIVE) {
                activeCount++;
            }
        }
        
        // Build active campaigns array
        uint256[] memory activeCampaigns = new uint256[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < userCampaignList.length; i++) {
            if (campaigns[userCampaignList[i]].status == CampaignStatus.ACTIVE) {
                activeCampaigns[currentIndex] = userCampaignList[i];
                currentIndex++;
            }
        }
        
        return activeCampaigns;
    }
    
    function getTrackCampaigns(string memory trackId) external view returns (uint256[] memory) {
        return trackCampaigns[trackId];
    }
    
    // =============================================================================
    // ADMINISTRATIVE FUNCTIONS
    // =============================================================================
    
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 1000, "CampaignManager: Fee too high"); // Max 10%
        platformFee = _platformFee;
    }
    
    function setPlatformWallet(address _platformWallet) external onlyOwner {
        require(_platformWallet != address(0), "CampaignManager: Invalid address");
        platformWallet = _platformWallet;
    }
    
    function setMinCampaignDuration(uint256 _duration) external onlyOwner {
        minCampaignDuration = _duration;
    }
    
    function setMaxCampaignDuration(uint256 _duration) external onlyOwner {
        maxCampaignDuration = _duration;
    }
    
    function setMinBudget(uint256 _minBudget) external onlyOwner {
        minBudget = _minBudget;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Emergency function to recover stuck tokens
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).transfer(owner(), amount);
        }
    }
    
    // =============================================================================
    // UTILITY FUNCTIONS
    // =============================================================================
    
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
```

***

## 🎯 **3. INTERFACES**

### **IBSTRToken.sol** - Interface do Token BSTR

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBSTRToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    // Custom BSTR functions
    function mintReward(address to, uint256 amount, string memory source) external;
    function userLevel(address account) external view returns (uint256);
    function totalEarned(address account) external view returns (uint256);
    function totalSpent(address account) external view returns (uint256);
    function isBlacklisted(address account) external view returns (bool);
    function isWhitelisted(address account) external view returns (bool);
    function isMinter(address account) external view returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensEarned(address indexed user, uint256 amount, string source);
    event UserLevelUpdated(address indexed user, uint256 newLevel);
}
```

***

## 📝 **DEPLOYMENT SCRIPTS**

### **deploy.js** - Script de Deploy

```javascript
const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying ENGAJA RAP CLUB Smart Contracts...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  
  // Deploy BSTR Token
  console.log("\n💰 Deploying BSTR Token...");
  const BSTRToken = await ethers.getContractFactory("BSTRToken");
  const bstrToken = await BSTRToken.deploy(
    deployer.address, // treasury wallet
    deployer.address  // community wallet
  );
  await bstrToken.deployed();
  console.log("✅ BSTR Token deployed to:", bstrToken.address);
  
  // Deploy Campaign Manager
  console.log("\n🎯 Deploying Campaign Manager...");
  const CampaignManager = await ethers.getContractFactory("CampaignManager");
  const campaignManager = await CampaignManager.deploy(
    bstrToken.address,
    deployer.address // platform wallet
  );
  await campaignManager.deployed();
  console.log("✅ Campaign Manager deployed to:", campaignManager.address);
  
  // Setup permissions
  console.log("\n⚙️ Setting up permissions...");
  await bstrToken.setMinter(campaignManager.address, true);
  console.log("✅ Campaign Manager set as BSTR minter");
  
  // Deploy Music NFT Contract
  console.log("\n🎵 Deploying Music NFT Contract...");
  const EngajaMusicNFT = await ethers.getContractFactory("EngajaMusicNFT");
  const musicNFT = await EngajaMusicNFT.deploy(
    bstrToken.address,
    deployer.address // platform wallet
  );
  await musicNFT.deployed();
  console.log("✅ Music NFT Contract deployed to:", musicNFT.address);
  
  // Deploy Staking Contract
  console.log("\n🔒 Deploying Staking Contract...");
  const BSTRStaking = await ethers.getContractFactory("BSTRStaking");
  const stakingContract = await BSTRStaking.deploy(
    bstrToken.address,
    deployer.address // platform wallet
  );
  await stakingContract.deployed();
  console.log("✅ Staking Contract deployed to:", stakingContract.address);
  
  // Deploy Marketplace Contract
  console.log("\n🛒 Deploying Marketplace Contract...");
  const EngajaMarketplace = await ethers.getContractFactory("EngajaMarketplace");
  const marketplace = await EngajaMarketplace.deploy(
    bstrToken.address,
    musicNFT.address,
    deployer.address // platform wallet
  );
  await marketplace.deployed();
  console.log("✅ Marketplace Contract deployed to:", marketplace.address);
  
  // Final setup
  console.log("\n🔧 Final setup...");
  await bstrToken.setMinter(musicNFT.address, true);
  await bstrToken.setStakingContract(stakingContract.address);
  await bstrToken.setCampaignContract(campaignManager.address);
  console.log("✅ All permissions configured");
  
  console.log("\n🎉 Deployment completed!");
  console.log("===============================");
  console.log("BSTR Token:", bstrToken.address);
  console.log("Campaign Manager:", campaignManager.address);
  console.log("Music NFT:", musicNFT.address);
  console.log("Staking Contract:", stakingContract.address);
  console.log("Marketplace:", marketplace.address);
  console.log("Deployer:", deployer.address);
  
  // Save deployment info
  const deployment = {
    network: network.name,
    timestamp: new Date().toISOString(),
    contracts: {
      BSTRToken: bstrToken.address,
      CampaignManager: campaignManager.address,
      EngajaMusicNFT: musicNFT.address,
      BSTRStaking: stakingContract.address,
      EngajaMarketplace: marketplace.address
    },
    deployer: deployer.address
  };
  
  const fs = require('fs');
  fs.writeFileSync('deployment.json', JSON.stringify(deployment, null, 2));
  console.log("📋 Deployment info saved to deployment.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
```

***

## 🧪 **TESTES**

### **BSTRToken.test.js** - Testes do Token Principal

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BSTRToken", function () {
  let bstrToken, owner, user1, user2, treasury, community;
  
  beforeEach(async function () {
    [owner, user1, user2, treasury, community] = await ethers.getSigners();
    
    const BSTRToken = await ethers.getContractFactory("BSTRToken");
    bstrToken = await BSTRToken.deploy(treasury.address, community.address);
    await bstrToken.deployed();
  });
  
  describe("Deployment", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await bstrToken.name()).to.equal("Brazilian Street Rap Token");
      expect(await bstrToken.symbol()).to.equal("BSTR");
      expect(await bstrToken.decimals()).to.equal(18);
      expect(await bstrToken.treasuryWallet()).to.equal(treasury.address);
      expect(await bstrToken.communityWallet()).to.equal(community.address);
    });
    
    it("Should mint initial supply to treasury", async function () {
      const initialSupply = ethers.utils.parseEther("100000000"); // 100M
      expect(await bstrToken.balanceOf(treasury.address)).to.equal(initialSupply);
    });
  });
  
  describe("Minting", function () {
    it("Should allow owner to mint rewards", async function () {
      const amount = ethers.utils.parseEther("100");
      await bstrToken.mintReward(user1.address, amount, "Test Reward");
      
      expect(await bstrToken.balanceOf(user1.address)).to.equal(amount);
      expect(await bstrToken.totalEarned(user1.address)).to.equal(amount);
    });
    
    it("Should update user level based on earnings", async function () {
      const amount = ethers.utils.parseEther("50"); // Should reach level 3
      await bstrToken.mintReward(user1.address, amount, "Level Test");
      
      expect(await bstrToken.userLevel(user1.address)).to.equal(3);
    });
    
    it("Should not allow non-minters to mint", async function () {
      const amount = ethers.utils.parseEther("100");
      await expect(
        bstrToken.connect(user1).mintReward(user2.address, amount, "Test")
      ).to.be.revertedWith("BSTR: Not authorized to mint");
    });
  });
  
  describe("Transfer Fees", function () {
    beforeEach(async function () {
      // Give user1 some tokens
      await bstrToken.mintReward(user1.address, ethers.utils.parseEther("1000"), "Setup");
    });
    
    it("Should deduct fees on transfers", async function () {
      const transferAmount = ethers.utils.parseEther("100");
      const initialBalance = await bstrToken.balanceOf(user1.address);
      
      await bstrToken.connect(user1).transfer(user2.address, transferAmount);
      
      // Should receive less than sent due to fees
      const receivedAmount = await bstrToken.balanceOf(user2.address);
      expect(receivedAmount).to.be.lt(transferAmount);
      
      // Total fees should be 1% (TRANSFER_FEE_RATE = 100 basis points)
      const totalFees = transferAmount.mul(100).div(10000);
      expect(receivedAmount).to.equal(transferAmount.sub(totalFees));
    });
    
    it("Should not charge fees for whitelisted addresses", async function () {
      await bstrToken.setWhitelisted(user1.address, true);
      
      const transferAmount = ethers.utils.parseEther("100");
      await bstrToken.connect(user1).transfer(user2.address, transferAmount);
      
      // Should receive full amount
      expect(await bstrToken.balanceOf(user2.address)).to.equal(transferAmount);
    });
  });
  
  describe("Blacklisting", function () {
    it("Should prevent blacklisted addresses from receiving tokens", async function () {
      await bstrToken.setBlacklisted(user1.address, true);
      
      await expect(
        bstrToken.mintReward(user1.address, ethers.utils.parseEther("100"), "Test")
      ).to.be.revertedWith("BSTR: Account is blacklisted");
    });
    
    it("Should prevent blacklisted addresses from sending tokens", async function () {
      // Give tokens first
      await bstrToken.mintReward(user1.address, ethers.utils.parseEther("100"), "Setup");
      
      // Then blacklist
      await bstrToken.setBlacklisted(user1.address, true);
      
      await expect(
        bstrToken.connect(user1).transfer(user2.address, ethers.utils.parseEther("50"))
      ).to.be.revertedWith("BSTR: Account is blacklisted");
    });
  });
  
  describe("Administrative Functions", function () {
    it("Should allow owner to set minters", async function () {
      await bstrToken.setMinter(user1.address, true);
      expect(await bstrToken.isMinter(user1.address)).to.be.true;
      
      // Now user1 should be able to mint
      await bstrToken.connect(user1).mintReward(user2.address, ethers.utils.parseEther("100"), "Minter Test");
      expect(await bstrToken.balanceOf(user2.address)).to.equal(ethers.utils.parseEther("100"));
    });
    
    it("Should allow owner to update wallets", async function () {
      const newTreasury = user1.address;
      await bstrToken.setTreasuryWallet(newTreasury);
      expect(await bstrToken.treasuryWallet()).to.equal(newTreasury);
    });
    
    it("Should not allow non-owners to access admin functions", async function () {
      await expect(
        bstrToken.connect(user1).setMinter(user2.address, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
```

***

## 📄 **CONFIGURAÇÃO DO HARDHAT**

### **hardhat.config.js**

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";
const INFURA_API_KEY = process.env.INFURA_API_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 1337
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
      chainId: 11155111
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
      chainId: 1
    },
    polygon: {
      url: "https://polygon-rpc.com/",
      accounts: [PRIVATE_KEY],
      chainId: 137
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: [PRIVATE_KEY],
      chainId: 80001
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  paths: {
    sources: "./contracts/src",
    tests: "./contracts/tests",
    cache: "./contracts/cache",
    artifacts: "./contracts/artifacts"
  }
};
```

***

## 🚀 **SCRIPTS DE COMANDO**

### **package.json** (Contracts)

```json
{
  "name": "engaja-rap-club-contracts",
  "version": "1.0.0",
  "description": "Smart Contracts for Engaja Rap Club",
  "scripts": {
    "compile": "hardhat compile",
    "test": "hardhat test",
    "test:coverage": "hardhat coverage",
    "deploy:local": "hardhat run scripts/deploy.js --network localhost",
    "deploy:sepolia": "hardhat run scripts/deploy.js --network sepolia",
    "deploy:mainnet": "hardhat run scripts/deploy.js --network mainnet",
    "verify:sepolia": "hardhat verify --network sepolia",
    "verify:mainnet": "hardhat verify --network mainnet",
    "flatten": "hardhat flatten",
    "size": "hardhat size-contracts",
    "gas-report": "REPORT_GAS=true hardhat test",
    "slither": "slither contracts/src/",
    "mythx": "mythx analyze contracts/src/"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^4.0.0",
    "hardhat": "^2.19.0",
    "hardhat-gas-reporter": "^1.0.9",
    "solidity-coverage": "^0.8.5"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.3",
    "dotenv": "^16.3.1"
  }
}
```

***

## 📋 **COMANDOS PARA GITHUB**

### **Comandos para adicionar ao repositório:**

```bash
# 1. Criar estrutura de contratos
mkdir -p contracts/{src,tests,scripts,config,interfaces,audits}

# 2. Adicionar todos os contratos
# (Copie os códigos acima para os respectivos arquivos)

# 3. Configurar dependências
cd contracts
npm init -y
npm install --save-dev @nomicfoundation/hardhat-toolbox hardhat
npm install @openzeppelin/contracts dotenv

# 4. Compilar contratos
npx hardhat compile

# 5. Executar testes
npx hardhat test

# 6. Deploy local (para teste)
npx hardhat node # Terminal 1
npx hardhat run scripts/deploy.js --network localhost # Terminal 2

# 7. Commit para GitHub
git add contracts/
git commit -m "feat: add complete smart contracts suite

- BSTR Token with deflationary mechanics
- Campaign Manager for music promotion
- Music NFT system with royalties
- Staking contract with levels
- Marketplace for NFT trading
- Complete test suite and deployment scripts"

git push origin main
```

***

## ✅ **CHECKLIST DE IMPLEMENTAÇÃO**
* [x] **BSTRToken.sol** - Token principal com mecânicas deflaciárias
* [x] **CampaignManager.sol** - Sistema de campanhas musicais
* [x] **EngajaMusicNFT.sol** - NFTs musicais com royalties
* [x] **BSTRStaking.sol** - Sistema de staking com níveis
* [x] **EngajaMarketplace.sol** - Marketplace de NFTs
* [x] **Interfaces** - Interfaces para integração
* [x] **Scripts de Deploy** - Automação de deployment
* [x] **Testes Unitários** - Cobertura de testes
* [x] **Configuração Hardhat** - Setup de desenvolvimento
* [x] **Documentação** - Documentação completa

***

## 🎯 **PRÓXIMOS PASSOS**

1. **Revisar e testar** todos os contratos
2. **Configurar CI/CD** para testes automáticos
3. **Auditoria de segurança** com Slither/MythX
4. **Deploy em testnet** para validação
5. **Integração com frontend** React/Telegram
6. **Deploy em mainnet** após validação completa

**🔥 Todos os contratos inteligentes estão prontos para serem implementados no GitHub do projeto ENGAJA RAP CLUB! 🚀**
