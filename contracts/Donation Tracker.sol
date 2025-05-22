// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    struct Donation {
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    struct Campaign {
        string title;
        string description;
        address payable recipient;
        uint256 targetAmount;
        uint256 raisedAmount;
        bool isActive;
        uint256 createdAt;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Donation[]) public campaignDonations;
    mapping(address => uint256[]) public userDonations;
    
    uint256 public campaignCounter;
    uint256 public totalDonations;
    uint256 public totalAmountRaised;

    event CampaignCreated(
        uint256 indexed campaignId,
        string title,
        address indexed recipient,
        uint256 targetAmount
    );

    event DonationMade(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount,
        string message
    );

    event CampaignClosed(uint256 indexed campaignId);

    modifier campaignExists(uint256 _campaignId) {
        require(_campaignId < campaignCounter, "Campaign does not exist");
        _;
    }

    modifier campaignActive(uint256 _campaignId) {
        require(campaigns[_campaignId].isActive, "Campaign is not active");
        _;
    }

    // Core Function 1: Create a new donation campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _targetAmount
    ) external returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_targetAmount > 0, "Target amount must be greater than 0");

        uint256 campaignId = campaignCounter;
        
        campaigns[campaignId] = Campaign({
            title: _title,
            description: _description,
            recipient: payable(msg.sender),
            targetAmount: _targetAmount,
            raisedAmount: 0,
            isActive: true,
            createdAt: block.timestamp
        });

        campaignCounter++;

        emit CampaignCreated(campaignId, _title, msg.sender, _targetAmount);
        
        return campaignId;
    }

    // Core Function 2: Make a donation to a specific campaign
    function makeDonation(
        uint256 _campaignId,
        string memory _message
    ) external payable campaignExists(_campaignId) campaignActive(_campaignId) {
        require(msg.value > 0, "Donation amount must be greater than 0");

        Campaign storage campaign = campaigns[_campaignId];
        
        // Create donation record
        Donation memory newDonation = Donation({
            donor: msg.sender,
            amount: msg.value,
            message: _message,
            timestamp: block.timestamp
        });

        // Update campaign and global statistics
        campaign.raisedAmount += msg.value;
        campaignDonations[_campaignId].push(newDonation);
        userDonations[msg.sender].push(_campaignId);
        totalDonations++;
        totalAmountRaised += msg.value;

        // Transfer funds to campaign recipient
        campaign.recipient.transfer(msg.value);

        emit DonationMade(_campaignId, msg.sender, msg.value, _message);

        // Auto-close campaign if target is reached
        if (campaign.raisedAmount >= campaign.targetAmount) {
            campaign.isActive = false;
            emit CampaignClosed(_campaignId);
        }
    }

    // Core Function 3: Get detailed campaign information and donation history
    function getCampaignDetails(uint256 _campaignId)
        external
        view
        campaignExists(_campaignId)
        returns (
            Campaign memory campaign,
            Donation[] memory donations,
            uint256 donationCount
        )
    {
        campaign = campaigns[_campaignId];
        donations = campaignDonations[_campaignId];
        donationCount = donations.length;
    }

    // Additional utility functions
    function closeCampaign(uint256 _campaignId)
        external
        campaignExists(_campaignId)
        campaignActive(_campaignId)
    {
        require(
            msg.sender == campaigns[_campaignId].recipient,
            "Only campaign creator can close the campaign"
        );
        
        campaigns[_campaignId].isActive = false;
        emit CampaignClosed(_campaignId);
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campaignCounter);
        
        for (uint256 i = 0; i < campaignCounter; i++) {
            allCampaigns[i] = campaigns[i];
        }
        
        return allCampaigns;
    }

    function getUserDonationHistory(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userDonations[_user];
    }

    function getContractStats()
        external
        view
        returns (
            uint256 totalCampaigns,
            uint256 totalDonationsCount,
            uint256 totalRaised
        )
    {
        return (campaignCounter, totalDonations, totalAmountRaised);
    }
}
