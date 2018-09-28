pragma solidity ^0.4.24;

import "./Owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is Owned {
    
    struct Offer {
        uint256 amount;
        address bidder;
    }
    
    struct OrderBook {
        uint256 higherPrice;
        uint256 lowerPrice;
        
        mapping (uint256 => Offer) offers;
        
        uint256 offers_key;
        uint256 offers_length;
        
    }
    
    struct Token {
        address tokenContract;
        string symbolName;
        
        mapping (uint256 => OrderBook) buyBook;
        
        uint256 curBuyPrice;
        uint256 lowestBuyPrice;
        uint256 amountBuyPrices;
        
        mapping(uint256 => OrderBook) sellBook;
        
        uint256 curSellPrice;
        uint256 highestSellPrice;
        uint256 amountSellPrices;
        
    }
    
    mapping (uint256 => Token) tokens;
    
    uint256 symbolNameIndex;
    
    mapping (address => mapping(uint256 => uint256)) tokenBalance;
    
    mapping (address => uint256) ethBalance;
    
        //events
    
    event TokenAdded(uint256 _symbolNameIndex, string _token, uint256 _timestamp);
    
    //deposit withdrawal events
    event DepositToken(address indexed _from, uint256 indexed _symbolNameIndex, uint256 _amount, uint256 _timestamp);
    event WithdrawToken(address indexed _from, uint256 indexed _symbolNameIndex, uint256 _amount, uint256 _timestamp);
    event DepositEther(address indexed _from, uint256 _amount, uint256 _timestamp);
    event WithdrawEther(address indexed _from, uint256 _amount, uint256 _timestamp);
    
    
    //orderbook event
    event LimitSellOrderCreated(uint256 indexed _symbolNameIndex, address indexed _who, uint256 _amount, uint256 _priceInWei, uint256 _orderKey );
    event LimitBuyOrderCreated(uint256 indexed _symbolNameIndex, address indexed _who, uint256 _amount, uint256 _priceInWei, uint256 _orderKey );
    event SellOrderFulfilled(uint indexed _symbolNameIndex, uint256 _priceInWei, uint256 _amountInWei, uint256 _orderKey);
    event BuyOrderFulfilled(uint indexed _symbolNameIndex, uint256 _priceInWei, uint256 _amountInWei, uint256 _orderKey);
    event SellOrderCancelled(uint indexed _symbolNameIndex, uint256 _priceInWei, uint256 _orderKey);
    event BuyOrderCancelled(uint indexed _symbolNameIndex, uint256 _priceInWei, uint256 _orderKey);
    
    //deposit and withdrawal ether
    
    function depositEther() payable {
        require(ethBalance[msg.sender] + msg.value >= ethBalance[msg.sender]);
        ethBalance[msg.sender] += msg.value;
        emit DepositEther(msg.sender, msg.value, now);
    }
    
    function withdrawEther(uint amountInWei) {
         require(ethBalance[msg.sender] - amountInWei >= 0);
         require(ethBalance[msg.sender] - amountInWei <= ethBalance[msg.sender]);
         ethBalance[msg.sender] -= amountInWei;
         emit WithdrawEther(msg.sender, amountInWei, now);
         msg.sender.transfer(amountInWei);
    }
    
    function getEthBalanceInWei() view returns (uint) {
        return ethBalance[msg.sender];
    }
    
    //deposit and withdraw taken
    
    function getSymbolIndexOrThrow(string symbolName) internal view returns (uint256) {
            uint256 index = getSymbolIndex(symbolName);
            require(index > 0);
            return index;
    }
    
    function depositToken(string symbolName, uint256 amount) {
        uint256 symbolIndex = getSymbolIndexOrThrow(symbolName);
        
        require(tokens[symbolIndex].tokenContract != address(0));
        
        ERC20Interface token = ERC20Interface(tokens[symbolIndex].tokenContract);
        
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        require(tokenBalance[msg.sender][symbolIndex] + amount >= tokenBalance[msg.sender][symbolIndex]);
        
        tokenBalance[msg.sender][symbolIndex] += amount;
        
        emit DepositToken(msg.sender, symbolIndex, amount, now);
    }
    
    function withdrawToken(string symbolName, uint256 amount) {
        uint256 symbolIndex = getSymbolIndexOrThrow(symbolName);
        require(tokens[symbolIndex].tokenContract != address(0));
        
        ERC20Interface token = ERC20Interface(tokens[symbolIndex].tokenContract);
        require(tokenBalance[msg.sender][symbolIndex] - amount >= 0);
        require(tokenBalance[msg.sender][symbolIndex] - amount <= tokenBalance[msg.sender][symbolIndex]);
        require(token.transfer(msg.sender, amount) == true);
        
        tokenBalance[msg.sender][symbolIndex] -= amount;
        
        emit WithdrawToken(msg.sender, symbolIndex, amount, now);
    }
    
    function getTokenBalance(string symbolName) view returns (uint256){
        uint256 index = getSymbolIndexOrThrow(symbolName);
        return tokenBalance[msg.sender][index];
    }
    
    //token management
    
    function addToken(string symbolName, address ercTokenAddress) onlyOwner {
        require(!hasToken(symbolName));
        symbolNameIndex++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = ercTokenAddress;
        
    }
    
    function currentsymbolIndex() view returns (uint256) {
        return symbolNameIndex;
    }
    
    function hasToken(string symbolName) view returns (bool) {
        uint256 index = getSymbolIndex(symbolName);
        if(index == 0) {
            return false;
        }
        
        return true;
    }
    
    function getSymbolIndex(string symbolName) internal view returns (uint256) {
        for( uint256 i; i <= symbolNameIndex; i++) {
            if(isEqualString(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
        
        return 0;
    }
    
    function isEqualString(string a, string b) view returns (bool) {
        return keccak256(a) == keccak256(b);
    }
    
    function buyToken(string symbolName, uint256 priceInWei,  uint256 amount) {
        uint256 symbolIndex = getSymbolIndexOrThrow(symbolName);
        uint256 total_amount_ether_valid = 0;
        uint256 total_amount_ether_avail = 0;
        
        if(tokens[symbolIndex].amountSellPrices == 0 || tokens[symbolIndex].curSellPrice > priceInWei) {
            
            total_amount_ether_valid = priceInWei * amount;
            
            require(total_amount_ether_valid >= priceInWei);
            require(total_amount_ether_valid >= amount);
            
            require(ethBalance[msg.sender] >= total_amount_ether_valid);
            require(ethBalance[msg.sender] - total_amount_ether_valid >= 0);
            
            ethBalance[msg.sender] -= total_amount_ether_valid;
        
            addBuyOffer(symbolIndex, priceInWei, amount, msg.sender);
            emit LimitBuyOrderCreated(symbolIndex, msg.sender, amount, priceInWei, tokens[symbolIndex].buyBook[priceInWei].offers_length);
            
        } else {
            
            uint whilePrice = tokens[symbolIndex].curSellPrice;
            uint amountValid = amount;
            uint offers_key;
            
            while(whilePrice <= priceInWei && amountValid > 0) {
                
                offers_key = tokens[symbolIndex].buyBook[whilePrice].offers_key;
                
                while(offers_key <= tokens[symbolIndex].sellBook[whilePrice].offers_length && amountValid > 0) {
                    
                    uint volumeAtPriceFromAddress = tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount;

                    if(volumeAtPriceFromAddress <= amountValid) {
                        
                        total_amount_ether_avail = volumeAtPriceFromAddress * priceInWei;

                        require(ethBalance[msg.sender] >= total_amount_ether_avail);
                        
                        require(ethBalance[msg.sender] - total_amount_ether_avail <= ethBalance[msg.sender]);
                        
                        ethBalance[msg.sender] -= total_amount_ether_avail;
                        
                        require(tokenBalance[msg.sender][symbolIndex] + volumeAtPriceFromAddress >= tokenBalance[msg.sender][symbolIndex]);
                        
                        require(ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder] + total_amount_ether_avail >= ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder]) ;
                        
                        tokenBalance[msg.sender][symbolIndex] += volumeAtPriceFromAddress;
                        
                        tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount = 0;
                        
                        ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder] += total_amount_ether_avail;
                        
                        tokens[symbolIndex].sellBook[whilePrice].offers_key++;
                        
                        emit BuyOrderFulfilled(symbolIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
                        
                        amountValid -= volumeAtPriceFromAddress;
                        
                    } else {
                        
                        require(tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount > amountValid);
                        
                        total_amount_ether_valid = amountValid * whilePrice;
                        
                        require(ethBalance[msg.sender] - total_amount_ether_valid <= ethBalance[msg.sender]);
                        
                        ethBalance[msg.sender] -= total_amount_ether_valid;
                        
                        
                        require(ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder] + total_amount_ether_valid >= ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder]);
                        
                        tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount -= amountValid;
                        
                        ethBalance[tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].bidder] += total_amount_ether_valid;
                        
                        tokenBalance[msg.sender][symbolIndex] -= amountValid;
                        
                        amountValid = 0;
                        
                        emit BuyOrderFulfilled(symbolIndex, amountValid, whilePrice, offers_key);
                    }
                    
                    if(offers_key == tokens[symbolIndex].sellBook[whilePrice].offers_length && tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount == 0) {
                        tokens[symbolIndex].amountBuyPrices--;
                        
                        if(whilePrice == tokens[symbolIndex].sellBook[symbolIndex].higherPrice || tokens[symbolIndex].sellBook[whilePrice].higherPrice == 0) {
                            tokens[symbolIndex].curSellPrice = 0;
                            
                        } else {
                            tokens[symbolIndex].curSellPrice = tokens[symbolIndex].sellBook[whilePrice].higherPrice;
                            tokens[symbolIndex].sellBook[tokens[symbolIndex].sellBook[whilePrice].higherPrice].lowerPrice = 0;
                                
                        }
                    }
                    
                    offers_key++;
                }
                whilePrice = tokens[symbolIndex].curSellPrice;
            }
            
            if(amountValid >= 0) {
                buyToken(symbolName, priceInWei, amountValid);
            }
        }
        
    }
    
    function sellToken(string symbolName, uint256 priceInWei, uint256 amount) {
        uint256 symbolIndex = getSymbolIndexOrThrow(symbolName);
        uint256 total_amount_ether_valid = 0;
        uint256 total_amount_ether_avail = 0;
    
        
        if(tokens[symbolIndex].amountBuyPrices == 0 || tokens[symbolIndex].curBuyPrice < priceInWei) {
            
            total_amount_ether_valid = priceInWei * amount;
            
            require(total_amount_ether_valid >= priceInWei);
            require(total_amount_ether_valid >= amount);
            require(tokenBalance[msg.sender][symbolIndex] >= amount);
            require(tokenBalance[msg.sender][symbolIndex] - amount >= 0);
            require(ethBalance[msg.sender] + total_amount_ether_valid >= ethBalance[msg.sender]);
            
            tokenBalance[msg.sender][symbolIndex] -= amount;
            addSellOffer(symbolIndex, priceInWei, amount, msg.sender);
            
            
            emit LimitSellOrderCreated(symbolIndex, msg.sender, amount, priceInWei, tokens[symbolIndex].buyBook[priceInWei].offers_length);
        } else {
            uint whilePrice = tokens[symbolIndex].curBuyPrice;
            uint amountValid = amount;
            uint offers_key;
            while(whilePrice >= priceInWei && amountValid > 0) {
                offers_key = tokens[symbolIndex].buyBook[whilePrice].offers_key;
                while(offers_key <= tokens[symbolIndex].buyBook[whilePrice].offers_length && amountValid > 0) {
                    uint volumeAtPriceFromAddress = tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].amount;

                    if(volumeAtPriceFromAddress <= amountValid) {
                        total_amount_ether_avail = volumeAtPriceFromAddress * priceInWei;

                        require(tokenBalance[msg.sender][symbolIndex] - volumeAtPriceFromAddress >= 0);
                        
                        tokenBalance[msg.sender][symbolIndex] -= volumeAtPriceFromAddress;
                        
                        require(tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex] + volumeAtPriceFromAddress >= tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex]);
                        require(tokenBalance[msg.sender][symbolIndex] + total_amount_ether_avail >= tokenBalance[msg.sender][symbolIndex]);
                        
                        tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex] += volumeAtPriceFromAddress;
                        tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                        tokenBalance[msg.sender][symbolIndex] += total_amount_ether_avail;
                        tokens[symbolIndex].buyBook[whilePrice].offers_key++;
                        
                        emit SellOrderFulfilled(symbolIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
                        
                        amountValid -= volumeAtPriceFromAddress;
                    } else {
                        require(volumeAtPriceFromAddress - amountValid >= 0);
                        
                        total_amount_ether_valid = amountValid * whilePrice;
                        
                        require(tokenBalance[msg.sender][symbolIndex] >= amountValid);
                        
                        tokenBalance[msg.sender][symbolIndex] -= amountValid;
                        
                        require(tokenBalance[msg.sender][symbolIndex] + total_amount_ether_valid >= tokenBalance[msg.sender][symbolIndex]);
                        require(tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex] + amountValid >= tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex]);
                        
                        tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].amount -= amountValid;
                        tokenBalance[msg.sender][symbolIndex] -= total_amount_ether_valid;
                        tokenBalance[tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].bidder][symbolIndex] += amountValid;
                    
                        emit SellOrderFulfilled(symbolIndex, amountValid, whilePrice, offers_key);
                    }
                    
                    if(offers_key == tokens[symbolIndex].buyBook[whilePrice].offers_length && tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].amount == 0) {
                        tokens[symbolIndex].amountBuyPrices--;
                        
                        if(whilePrice == tokens[symbolIndex].buyBook[symbolIndex].lowerPrice || tokens[symbolIndex].buyBook[whilePrice].lowerPrice == 0) {
                            tokens[symbolIndex].curBuyPrice = 0;
                            
                        } else {
                            tokens[symbolIndex].curBuyPrice = tokens[symbolIndex].buyBook[whilePrice].lowerPrice;
                            tokens[symbolIndex].buyBook[tokens[symbolIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[symbolIndex].curBuyPrice;
                                
                        }
                    }
                    
                    offers_key++;
                }
                whilePrice = tokens[symbolIndex].curBuyPrice;
            }
            
            if(amountValid >= 0) {
                sellToken(symbolName, priceInWei, amountValid);
            }
        }
    }
    
    function addSellOffer(uint256 symbolIndex, uint256 priceInWei, uint256 amount,address buyer ) internal {
        tokens[symbolIndex].sellBook[priceInWei].offers_length++;
        tokens[symbolIndex].sellBook[priceInWei].offers[tokens[symbolIndex].sellBook[priceInWei].offers_length] = Offer(amount, buyer);
        
        if(tokens[symbolIndex].sellBook[priceInWei].offers_length == 1) {
            tokens[symbolIndex].sellBook[priceInWei].offers_key = 1;
            tokens[symbolIndex].amountSellPrices++;
            uint256 curSellPrice = tokens[symbolIndex].curSellPrice;
            uint256 higherSellPrice = tokens[symbolIndex].highestSellPrice;
            
            if(higherSellPrice == 0 || higherSellPrice < priceInWei) {
                if(curSellPrice == 0) {
                    tokens[symbolIndex].curSellPrice = priceInWei;
                    tokens[symbolIndex].sellBook[priceInWei].higherPrice = 0;
                    tokens[symbolIndex].sellBook[priceInWei].lowerPrice = 0;
                } else{
                    tokens[symbolIndex].sellBook[higherSellPrice].higherPrice = priceInWei;
                    tokens[symbolIndex].sellBook[priceInWei].lowerPrice = higherSellPrice;
                    tokens[symbolIndex].sellBook[priceInWei].higherPrice = 0;
                    
                    tokens[symbolIndex].highestSellPrice = priceInWei;
                }
            } else if(curSellPrice > priceInWei) {
                tokens[symbolIndex].sellBook[curSellPrice].lowerPrice = priceInWei;
                tokens[symbolIndex].sellBook[priceInWei].higherPrice = curSellPrice;
                
                tokens[symbolIndex].sellBook[priceInWei].lowerPrice = 0;
                tokens[symbolIndex].curSellPrice = priceInWei;
            }
            else {
                uint256 sellPrice = tokens[symbolIndex].curSellPrice;
                bool hasFound = false;
                
                while (sellPrice > 0 && !hasFound) {
                    if(sellPrice < priceInWei && tokens[symbolIndex].sellBook[sellPrice].higherPrice > priceInWei){
                        tokens[symbolIndex].sellBook[priceInWei].lowerPrice = sellPrice;
                        tokens[symbolIndex].sellBook[priceInWei].higherPrice = tokens[symbolIndex].sellBook[sellPrice].lowerPrice;
                    
                        tokens[symbolIndex].sellBook[tokens[symbolIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;
                        tokens[symbolIndex].sellBook[sellPrice].higherPrice = priceInWei;
                        
                        hasFound = true;
                    }
                }
                
                sellPrice = tokens[symbolIndex].sellBook[sellPrice].higherPrice;
            }
        }
    }

    function addBuyOffer(uint256 symbolIndex, uint256 priceInWei, uint256 amount, address buyer) internal {
        tokens[symbolIndex].buyBook[priceInWei].offers_length++;
        tokens[symbolIndex].buyBook[priceInWei].offers[tokens[symbolIndex].buyBook[priceInWei].offers_length] = Offer(amount, buyer);
        
        if(tokens[symbolIndex].buyBook[priceInWei].offers_length == 1) {
            tokens[symbolIndex].buyBook[priceInWei].offers_key = 1;
            
            tokens[symbolIndex].amountBuyPrices++;
            uint256 curBuyPrice = tokens[symbolIndex].curBuyPrice;
            uint256 lowestBuyPrice = tokens[symbolIndex].lowestBuyPrice;
            
            if(lowestBuyPrice == 0 || lowestBuyPrice > priceInWei) {
                if(curBuyPrice == 0) {
                    tokens[symbolIndex].curBuyPrice = priceInWei;
                    tokens[symbolIndex].buyBook[priceInWei].higherPrice = priceInWei;
                    tokens[symbolIndex].buyBook[priceInWei].lowerPrice = 0;
                } else {
                    tokens[symbolIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
                    tokens[symbolIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
                    tokens[symbolIndex].buyBook[priceInWei].lowerPrice = 0;
                }
                tokens[symbolIndex].lowestBuyPrice = priceInWei;
            }
            else if(priceInWei > curBuyPrice) {
                tokens[symbolIndex].buyBook[curBuyPrice].higherPrice = priceInWei;
                tokens[symbolIndex].buyBook[priceInWei].higherPrice = priceInWei;
                tokens[symbolIndex].curBuyPrice = priceInWei;
            }
            else {
                bool hasFound = false;
                uint256 buyPrice = tokens[symbolIndex].curBuyPrice;
                while(buyPrice > 0 && !hasFound) {
                    if(priceInWei > buyPrice && priceInWei < tokens[symbolIndex].buyBook[buyPrice].higherPrice) {
                        tokens[symbolIndex].buyBook[priceInWei].lowerPrice = buyPrice;
                        tokens[symbolIndex].buyBook[priceInWei].higherPrice = tokens[symbolIndex].buyBook[buyPrice].lowerPrice;
                        
                        tokens[symbolIndex].buyBook[tokens[symbolIndex].buyBook[buyPrice].lowerPrice].lowerPrice = priceInWei;
                        tokens[symbolIndex].buyBook[priceInWei].higherPrice = priceInWei;
                        
                        hasFound = true;
                    
                        
                    }
                    
                    buyPrice = tokens[symbolIndex].buyBook[buyPrice].lowerPrice;
                }
            }
        }
    }
    
    function getBuyOrderBook(string symbolName) view returns (uint[], uint[]) {
        uint symbolIndex = getSymbolIndexOrThrow(symbolName);
        uint[] memory arrPricesBuy = new uint[](tokens[symbolIndex].amountBuyPrices);
        uint[] memory arrVolumesBuy = new uint[](tokens[symbolIndex].amountBuyPrices);
        
        uint whilePrice = tokens[symbolIndex].lowestBuyPrice;
        uint counter = 0;
        
        if(tokens[symbolIndex].curBuyPrice > 0) {
            while (whilePrice <= tokens[symbolIndex].curBuyPrice) {
                arrPricesBuy[counter] = whilePrice;
                uint volumeAtPrice = whilePrice;
                uint offers_key = 0;
                
                offers_key = tokens[symbolIndex].buyBook[whilePrice].offers_key;
                while(offers_key <= tokens[symbolIndex].buyBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[symbolIndex].buyBook[whilePrice].offers[offers_key].amount;
                    offers_key++;
                }
                
                arrVolumesBuy[counter] = volumeAtPrice;
                
                if(whilePrice == tokens[symbolIndex].buyBook[whilePrice].higherPrice) {
                    break;
                } else {
                   whilePrice = tokens[symbolIndex].buyBook[whilePrice].higherPrice; 
                }
                counter++;
            }
        }
        
        return (arrPricesBuy, arrVolumesBuy);
    }
    
    function getSellBook(string symbolName) view returns (uint[], uint[]) {
        uint symbolIndex = getSymbolIndexOrThrow(symbolName);
        uint[] memory arrPricesSell = new uint[](tokens[symbolIndex].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[symbolIndex].amountSellPrices);
        
        uint whilePrice = tokens[symbolIndex].curSellPrice;
        uint counter = 0;
        
        if(tokens[symbolIndex].curSellPrice > 0) {
            while(whilePrice <= tokens[symbolIndex].highestSellPrice) {
                arrPricesSell[counter] = whilePrice;
                uint volumeAtPrice = 0;
                uint offers_key = 0;
                
                offers_key = tokens[symbolIndex].sellBook[whilePrice].offers_key;
                while(offers_key <= tokens[symbolIndex].sellBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[symbolIndex].sellBook[whilePrice].offers[offers_key].amount;
                    offers_key++;
                }
                
                arrPricesSell[counter] = volumeAtPrice;
                
                if(tokens[symbolIndex].sellBook[whilePrice].higherPrice == 0) {
                    break;
                } else {
                   whilePrice = tokens[symbolIndex].sellBook[whilePrice].higherPrice; 
                }
                
                counter++;
            }
        }
        
        return (arrPricesSell, arrVolumesSell);
    }
    
    function cancelOrde(string symbolName, bool isSellOrder, uint priceInWei, uint offerKey) {
        uint symbolIndex = getSymbolIndexOrThrow(symbolName);
        if(isSellOrder) {
            require(tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].bidder == msg.sender);
            
            uint tokensAmount = tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].amount;
            require(tokenBalance[msg.sender][symbolIndex] + tokensAmount >= tokenBalance[msg.sender][symbolIndex]);
            
            tokenBalance[msg.sender][symbolIndex] += tokensAmount;
            tokens[symbolIndex].sellBook[priceInWei].offers[offerKey].amount == 0;
            emit SellOrderCancelled(symbolIndex, priceInWei, offerKey);
        } 
        else {
            
            require(tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].bidder == msg.sender);
            
            uint refundEther = tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].amount * priceInWei;
            require(ethBalance[msg.sender] + refundEther >= ethBalance[msg.sender]);
            
            ethBalance[msg.sender] += refundEther;
            tokens[symbolIndex].buyBook[priceInWei].offers[offerKey].amount == 0;
            emit BuyOrderCancelled(symbolIndex, priceInWei, offerKey);
            
        }
    }
}