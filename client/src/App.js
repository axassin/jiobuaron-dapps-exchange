import React, { Component } from "react";
import Token from "./contracts/FixedSupplyToken.json";
import Exhange from "./contracts/Exchange.json";
import getWeb3 from "./utils/getWeb3";
import truffleContract from "truffle-contract";
import Market from './Component/Market';
import "./App.css";

class App extends Component {
  state = { storageValue: 0, web3: null, accounts: null, tokenInstance: null, exchangeInstance: null };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const TokenContract = truffleContract(Token);
      TokenContract.setProvider(web3.currentProvider);
      const tokenInstance = await TokenContract.deployed();

      const ExchangeContract = truffleContract(Exhange);
      ExchangeContract.setProvider(web3.currentProvider);
      const exchangeInstance = await ExchangeContract.deployed();


      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, tokenInstance, exchangeInstance});
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.log(error);
    }
  };


  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
        <Market accounts={this.state.accounts || []} tokenInstance={this.state.tokenInstance} exchangeInstance={this.state.exchangeInstance}/>
    );
  }
}

export default App;
