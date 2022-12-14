pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

//node_modules\@openzeppelin\contracts\token\ERC721\ERC721.sol
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "./ERC721"

contract SmartEstate is ERC721{
    uint private buyerId;
    uint private tokenId;
    
    enum offerApproval{pending,approved,rejected}
    
    struct PropertyDetails{
        address sellerAddress;
        uint propertyId;
        string propertyAddress;
        string city;
        uint room;
        string area;
        string propertyType;
        uint price;
        bool saleStatus;
    }
    
    struct BuyerInfo{
        uint bId;
        address buyerAddress;
        uint buyerOffer;
        offerApproval request;    
    }
    
    modifier propertyOwner(){
        require(OnlyOwner[msg.sender].sellerAddress == msg.sender, "Error: Only Property Owner run this");
         _;
    }
    
    mapping(address=>PropertyDetails) public OnlyOwner;
    mapping(uint=>address) public PropertyList;
    mapping(address=>BuyerInfo) public BuyerList;
    mapping(uint=>BuyerInfo[]) public AllBuyers;
    mapping(uint=>bool) public Offers;
    
    constructor() ERC721('Smart Estate Properties', 'ESP')public{
        
    }
    
    function RegisterProperty(string memory _propertyAddress,string memory _city,uint _room,string memory _area,uint _priceInEther,string memory _propertyType, bool _saleStatus,string memory _tokenUri) public returns(bool) {
        tokenId++;
        uint thisId= tokenId;
        _mint(msg.sender,thisId);
        _setTokenURI(thisId,_tokenUri);
        
        PropertyDetails memory tempDetails;
        
        tempDetails =PropertyDetails({
            sellerAddress: msg.sender,
            propertyId: thisId,
            propertyAddress: _propertyAddress,
            city: _city,
            room: _room,
            area: _area,
            propertyType:_propertyType,
            price:_priceInEther,
            saleStatus:false
        });
        OnlyOwner[msg.sender] = tempDetails;
        PropertyList[thisId] = msg.sender;
        return true;
    }
    
    function EnablePropertySale(uint PropertyId_TokenId) public propertyOwner returns(bool){
        require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
        OnlyOwner[PropertyList[PropertyId_TokenId]].saleStatus=true;
        return true;
    }
    
    function PropertyPricing(uint PropertyId_TokenId) public propertyOwner returns(uint256){
        require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
        return OnlyOwner[PropertyList[PropertyId_TokenId]].price;
    }
    
    function BuyingRequest(uint PropertyId_TokenId,uint offerInEthers) public returns(bool){
        require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
        require(OnlyOwner[PropertyList[PropertyId_TokenId]].saleStatus,"Error:This Property not on Sale");
        
        buyerId++;
        
        BuyerInfo memory tempDetails;
        tempDetails=BuyerInfo({
            bId:buyerId,
           buyerAddress:msg.sender,
           buyerOffer:offerInEthers,
           request:offerApproval.pending
        });
        AllBuyers[PropertyId_TokenId].push(tempDetails);
        BuyerList[msg.sender] = tempDetails;
        BuyerList[msg.sender].request = offerApproval.pending;
        
        
        return true;
    } 
    
    function OfferStatus(uint PropertyId_TokenId) public propertyOwner returns (BuyerInfo[] memory){
        require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
        BuyerInfo[] memory tempDetails;
        tempDetails = AllBuyers[PropertyId_TokenId];
        return tempDetails;
    }
    
    function OfferReject(uint PropertyId_TokenId,address _buyerAddress) public propertyOwner returns(bool){
         require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
         require(BuyerList[_buyerAddress].buyerAddress == _buyerAddress,"Error: INVALID buyer address ");
         BuyerList[_buyerAddress].request = offerApproval.rejected;
        return true;
    }
    
    function OfferAccept(uint PropertyId_TokenId,address _buyerAddress) public propertyOwner returns(bool){
         require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
         require(BuyerList[_buyerAddress].buyerAddress == _buyerAddress,"Error: INVALID buyer address ");
         BuyerList[_buyerAddress].request = offerApproval.approved;
        return true;
    }
    
    function BuyProperty(uint PropertyId_TokenId) public payable returns(bool){
        require(_exists(PropertyId_TokenId),"Error: INVALID Property id or token id");
        require(BuyerList[msg.sender].buyerAddress == msg.sender,"Error: INVALID buyer address ");
        require(BuyerList[msg.sender].request == offerApproval.approved,"Error: This Property not for sale (Offer request not approved)");
        require(msg.value > 0,"Error: Ether(s) not provided ");
        uint PropertyPrice = BuyerList[msg.sender].buyerOffer.mul(1*10**18);
        require(PropertyPrice == msg.value, "Error: Sorry, Pricing of property not matched with offer");
        address BuyerAddress = OnlyOwner[PropertyList[PropertyId_TokenId]].sellerAddress;
        _transfer(BuyerAddress,msg.sender,PropertyId_TokenId);
        emit Transfer(BuyerAddress,msg.sender,PropertyId_TokenId);
    }

}