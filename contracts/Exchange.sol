pragma solidity ^0.4.24;

import "./Owned.sol";
import "./FixedSupplyToken.sol";
import "./RedBlackTree.sol";

contract ExchangeToken is Owned {
    
    using RedBlackTree for RedBlackTree.Tree;
    
    struct Offer {
        uint256 quantity;
        uint256 price;
        address bidder;
    }
    
    struct ListItem {
        uint256 next;
        uint256 prev;
    }
    
    struct OrderBook {
        RedBlackTree.Tree pricesTree;
        uint256 maxPrice;
        uint256 minPrice;
        uint256 bestOffer;
   
        uint256 offer_length;
        mapping (uint256 => Offer) offers;
        mapping (uint256 => ListItem) items;
    }
    
    struct Token {
        string tokenName;
        address tokenContract;
    }
    
    // token index to OrderBook
    mapping(uint256 => OrderBook) sellingTokens;
    mapping(uint256 => OrderBook) buyingTokens; 
    
    //token current latest index
    uint256 tokenNameIndex;
    // token index by token name
    mapping (string => uint256) tokenIndex;
    // token index
    mapping (uint256 => Token) tokens;
    //user balance per token
    mapping (address => mapping (uint256 => uint256)) tokenBalance;
    // user eth balance
    mapping (address => uint256) ethBalance;
    
    function depositEther() payable {
        require(ethBalance[msg.sender] + msg.value >= ethBalance[msg.sender]);
        ethBalance[msg.sender] += msg.value;
    }
    
    function withdrawEther(uint _amountInWei) {
        require(ethBalance[msg.sender] - _amountInWei >= 0);
        require(ethBalance[msg.sender] - _amountInWei <= ethBalance[msg.sender]);
        ethBalance[msg.sender] -= _amountInWei;
        msg.sender.transfer(_amountInWei);
    }
    
    function getEthBalanceInWei() view returns (uint) {
        return ethBalance[msg.sender];
    }
    
    function getTokenIndex(string tokenName) view returns (uint256){
        return tokenIndex[tokenName];        
    }

    function createToken(string _tokenName, address _ercTokenAddress) onlyOwner {
        require(tokenIndex[_tokenName] == 0);
        tokenNameIndex++;
        tokenIndex[_tokenName] = tokenNameIndex;
        tokens[tokenNameIndex].tokenName = _tokenName;
        tokens[tokenNameIndex].tokenContract = _ercTokenAddress;
    }
    
    function depositToken(string _tokenName, uint256 _quantity) {
        ERC20Interface token = ERC20Interface(tokens[getTokenIndex(_tokenName)].tokenContract);
        require(token.transferFrom(msg.sender, address(this), _quantity) == true);
        tokenBalance[msg.sender][getTokenIndex(_tokenName)] += _quantity;
    }
    
    function getTokenBalance(string _tokenName) view returns (uint256) {
        return tokenBalance[msg.sender][getTokenIndex(_tokenName)];
    }
    
    function getSellOffer(string _tokenName, uint256 _offerIndex) view returns (uint256, uint256, uint256) {
        uint256 length = sellingTokens[getTokenIndex(_tokenName)].offer_length;
        uint256 price = sellingTokens[getTokenIndex(_tokenName)].offers[_offerIndex].price;
        uint256 quantity = sellingTokens[getTokenIndex(_tokenName)].offers[_offerIndex].quantity;
        
        return (length, price, quantity);
    }
    
        function getBuyOffer(string _tokenName, uint256 _offerIndex) view returns (uint256, uint256, uint256) {
        uint256 length = buyingTokens[getTokenIndex(_tokenName)].offer_length;
        uint256 price = buyingTokens[getTokenIndex(_tokenName)].offers[_offerIndex].price;
        uint256 quantity = buyingTokens[getTokenIndex(_tokenName)].offers[_offerIndex].quantity;
        
        return (length, price, quantity);
    }
    
    function sellToken(string _tokenName, uint256 _price, uint256 _quantity) {
        uint256 indexToken = getTokenIndex(_tokenName);

        require(tokenBalance[msg.sender][indexToken] - _quantity >= 0);
        require(tokenBalance[msg.sender][indexToken] >= _quantity);
       
        if(buyingTokens[indexToken].offer_length != 0) {
            uint256 currentId = buyingTokens[indexToken].bestOffer;
            
            uint256 tradedQuantity;
            
            while(currentId != 0 && _price <= buyingTokens[indexToken].offers[currentId].price) {
                if(buyingTokens[indexToken].offers[currentId].quantity >= _quantity) {
                   buyingTokens[indexToken].offers[currentId].quantity -= _quantity;
                   tradedQuantity = _quantity;
                   _quantity = 0;
                } else {
                    _quantity -= buyingTokens[indexToken].offers[currentId].quantity;
                    buyingTokens[indexToken].offers[currentId].quantity = 0;
                    tradedQuantity = buyingTokens[indexToken].offers[currentId].quantity;
                }
                //seller
                tokenBalance[msg.sender][indexToken] -= tradedQuantity;
                ethBalance[msg.sender] += tradedQuantity * _price;
                
                //buyer
                tokenBalance[buyingTokens[indexToken].offers[currentId].bidder][indexToken] += tradedQuantity;
                ethBalance[buyingTokens[indexToken].offers[currentId].bidder] -= _price * tradedQuantity;
                
                if(buyingTokens[indexToken].offers[currentId].quantity != 0) {
                    break;
                }
                
                ListItem memory item = removeBuyingOrder(indexToken, currentId);
                
                currentId = item.next;
            }
        }
        
        if(_quantity != 0) {
            
            uint256 id = sellingTokens[indexToken].offer_length + 1;
            
            uint256 parentId = sellingTokens[indexToken].pricesTree.find(_price);
             
            uint256 curId;
            
            if(parentId != 0 && _price >= sellingTokens[indexToken].offers[parentId].price) {
                curId = sellingTokens[indexToken].items[parentId].next;
            } else {
                curId = parentId;
            }
            
            //setting prev and next item
            ListItem memory orderItem;
            uint256 prevItem;
            orderItem.next = curId;
            
            if(curId != 0) {
                prevItem = sellingTokens[indexToken].items[curId].prev;
                sellingTokens[indexToken].items[curId].prev = id;
            } else {
                prevItem = sellingTokens[indexToken].minPrice;
                sellingTokens[indexToken].minPrice = id;
            }
            
            orderItem.prev = prevItem;
            
            if(prevItem != 0) {
                sellingTokens[indexToken].items[prevItem].next = id;
            } else {
                sellingTokens[indexToken].maxPrice = id;
            }
            
            if(curId  == sellingTokens[indexToken].bestOffer) {
                sellingTokens[indexToken].bestOffer = id;
            }
            
            sellingTokens[indexToken].offer_length++;
            
            sellingTokens[indexToken].offers[id] = Offer({quantity: _quantity, price: _price, bidder:msg.sender});
            sellingTokens[indexToken].pricesTree.placeAfter(parentId, id, _price);
            
        }
        
    }
    
    function buyToken(string _tokenName, uint256 _price, uint256 _quantity) {
        uint256 indexToken = getTokenIndex(_tokenName);

        require(ethBalance[msg.sender] - (_quantity * _price) >= 0);
        require(ethBalance[msg.sender] >= (_quantity * _price));
        
        if(sellingTokens[indexToken].offer_length != 0) {
            
            uint256 currentId = sellingTokens[indexToken].bestOffer;
            
            uint256 tradedQuantity;
            
            while(currentId != 0 && _price >= sellingTokens[indexToken].offers[currentId].price) {
                if(sellingTokens[indexToken].offers[currentId].quantity >= _quantity) {
                   sellingTokens[indexToken].offers[currentId].quantity -= _quantity;
                   tradedQuantity = _quantity;
                   _quantity = 0;
                } else {
                    _quantity -= sellingTokens[indexToken].offers[currentId].quantity;
                    sellingTokens[indexToken].offers[currentId].quantity = 0;
                    tradedQuantity = sellingTokens[indexToken].offers[currentId].quantity;
                }
                //buyer
                tokenBalance[msg.sender][indexToken] += tradedQuantity;
                ethBalance[msg.sender] -= tradedQuantity * _price;
                
                //seller
                tokenBalance[sellingTokens[indexToken].offers[currentId].bidder][indexToken] -= tradedQuantity;
                ethBalance[sellingTokens[indexToken].offers[currentId].bidder] += _price * tradedQuantity;
                
                if(sellingTokens[indexToken].offers[currentId].quantity != 0) {
                    break;
                }
                
                ListItem memory item = removeSellingOrder(indexToken, currentId);
                
                currentId = item.next;
            }
        }
        
       
        
        if(_quantity != 0) {
             uint256 id = buyingTokens[indexToken].offer_length + 1;
             
            uint256 parentId = buyingTokens[indexToken].pricesTree.find(_price);
             
            uint256 curId;
            
            if(parentId != 0 && _price >= buyingTokens[indexToken].offers[parentId].price) {
                curId = buyingTokens[indexToken].items[parentId].next;
            } else {
                curId = parentId;
            }
            
            //setting prev and next item
            ListItem memory orderItem;
            uint256 prevItem;
            orderItem.next = curId;
            
            if(curId != 0) {
                prevItem = buyingTokens[indexToken].items[curId].prev;
                buyingTokens[indexToken].items[curId].prev = id;
            } else {
                prevItem = buyingTokens[indexToken].minPrice;
                buyingTokens[indexToken].minPrice = id;
            }
            
            orderItem.prev = prevItem;
            
            if(prevItem != 0) {
                buyingTokens[indexToken].items[prevItem].next = id;
            } else {
                buyingTokens[indexToken].maxPrice = id;
            }
            
            if(curId  == buyingTokens[indexToken].bestOffer) {
                buyingTokens[indexToken].bestOffer = id;
            }
            
            buyingTokens[indexToken].offer_length++;
            
            buyingTokens[indexToken].offers[id] = Offer({quantity: _quantity, price: _price, bidder:msg.sender});
            buyingTokens[indexToken].pricesTree.placeAfter(parentId, id, _price);
            
        }
    }
    
    function removeBuyingOrder(uint256 _tokenIndex, uint256 _id) private returns (ListItem) {
        if(buyingTokens[_tokenIndex].items[_id].next != 0) {
            buyingTokens[_tokenIndex].items[ buyingTokens[_tokenIndex].items[_id].next].prev =  buyingTokens[_tokenIndex].items[_id].prev;
        }
        
        if(buyingTokens[_tokenIndex].items[_id].prev != 0) {
            buyingTokens[_tokenIndex].items[ buyingTokens[_tokenIndex].items[_id].prev].next =  buyingTokens[_tokenIndex].items[_id].next;
        }
        
        if(buyingTokens[_tokenIndex].minPrice == _id) {
            buyingTokens[_tokenIndex].minPrice = buyingTokens[_tokenIndex].items[_id].prev;
        }
        
        if(buyingTokens[_tokenIndex].maxPrice == _id) {
            buyingTokens[_tokenIndex].maxPrice = buyingTokens[_tokenIndex].items[_id].next;
        }
        
        buyingTokens[_tokenIndex].pricesTree.remove(_id);
        
        delete buyingTokens[_tokenIndex].items[_id];
        delete buyingTokens[_tokenIndex].offers[_id];
        
        return buyingTokens[_tokenIndex].items[_id];
    }
    
    function removeSellingOrder(uint256 _tokenIndex, uint256 _id) private returns (ListItem) {
        if(sellingTokens[_tokenIndex].items[_id].next != 0) {
            sellingTokens[_tokenIndex].items[ sellingTokens[_tokenIndex].items[_id].next].prev =  sellingTokens[_tokenIndex].items[_id].prev;
        }
        
        if(sellingTokens[_tokenIndex].items[_id].prev != 0) {
            sellingTokens[_tokenIndex].items[ sellingTokens[_tokenIndex].items[_id].prev].next =  sellingTokens[_tokenIndex].items[_id].next;
        }
        
        if(sellingTokens[_tokenIndex].minPrice == _id) {
            sellingTokens[_tokenIndex].minPrice = sellingTokens[_tokenIndex].items[_id].prev;
        }
        
        if(sellingTokens[_tokenIndex].maxPrice == _id) {
            sellingTokens[_tokenIndex].maxPrice = sellingTokens[_tokenIndex].items[_id].next;
        }
        
        sellingTokens[_tokenIndex].pricesTree.remove(_id);
        delete sellingTokens[_tokenIndex].items[_id];
        delete sellingTokens[_tokenIndex].offers[_id];
        
        return sellingTokens[_tokenIndex].items[_id];
    }
    
}