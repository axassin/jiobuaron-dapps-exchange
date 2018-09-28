import React, {Component} from 'react'
import BuyToken from './BuyToken';
import SellToken from './SellToken';
import Home from './Home';
import SendToken from './SendToken';
import {Switch, Route, Link} from 'react-router-dom'
import AddToken from './AddToken';
import Token from './Token';
import Ether from './Ether';

class Market extends Component {

    state = {
        balance: 0,
        accNumber: 0,
        curAddress: '',
        tokenBalance: 0,
        ethBalance: 0,
        tokenName: "FIXED"
    }

    componentDidMount() {
        console.log(this.props.account[0])
        this.setBalance()
        this.setEth()
        this.setToken()
    }

    setBalance() {
        this.props.tokenInstance.balanceOf.call(this.props.account[this.state.accNumber]).then(balance => {
            this.setState({balance, curAddress:this.props.account[this.state.accNumber]})
        })
        console.log("WEW")
    }

    setEth() {
        this.props.exchangeInstance.getEthBalanceInWei({from: this.props.account[this.state.accNumber]}).then(result => {
            var BN = this.props.web3.utils.BN;
            const ethBalance = new BN(result).toString()
            this.setState({ethBalance})
        }).catch(console.log)
    }

    setToken() {
        this.props.exchangeInstance.getTokenBalance(this.state.tokenName,{from: this.props.account[this.state.accNumber]}).then(result => {
            var BN = this.props.web3.utils.BN;
            const tokenBalance = new BN(result).toString()
            this.setState({tokenBalance})

            console.log(result)
        }).catch(console.log)
    }

    render() {
        return(
            <div>
                <div>
                    {`Current Token: ${this.state.balance}`}
                </div>
                <div>
                    {`Current Wei balance: ${this.state.ethBalance}`}
                </div>
                <div>
                    {`Current Token Balance: ${this.state.tokenBalance}`}
                </div>
                <div>
                    {`Current Address: ${this.state.curAddress}`}
                </div>
                <div>
                    <Link to="/">Home</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/buyToken">Buy Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/sellToken">Sell Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/sendToken">Send Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/addToken">Add Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/token">Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/ether">Ether</Link>
                </div>
                <Switch>
                  <Route name="home" exact path='/' component={() => <Home {...this.props}/>}/>
                  <Route name="sellToken" path='/sellToken' component={() => <SellToken {...this.props} acc={this.state.curAddress}/>} />
                  <Route name="buyToken" path='/buyToken' component={() => <BuyToken {...this.props} acc={this.state.curAddress}/>} />
                  <Route name="sendToken" path='/sendToken' component={() => <SendToken {...this.props} acc={this.state.curAddress}/>}/>
                  <Route name="addToken" path='/AddToken' component={() => <AddToken {...this.props} acc={this.state.curAddress}/>} />
                  <Route name="token" path='/token' component={() => <Token {...this.props} acc={this.state.curAddress}/>} />
                  <Route name="ether" path='/ether' component={() => <Ether {...this.props} acc={this.state.curAddress}/>} />
                </Switch>
            </div>

        )
    }
}


export default Market