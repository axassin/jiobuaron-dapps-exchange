import React, {Component} from 'react'
import BuyToken from './BuyToken';
import SellToken from './SellToken';
import Home from './Home';
import SendToken from './SendToken';
import {Switch, Route, Link} from 'react-router-dom'

class Market extends Component {

    state = {
        balance: 0
    }

    componentDidMount() {
        console.log(this.props.accounts[0])
        this.props.tokenInstance.balanceOf.call(this.props.accounts[0]).then(balance => {
            this.setState({balance})
        })
    }

    render() {
        return(
            <div>
                <div>
                    {`Current Token: ${this.state.balance}`}
                </div>
                <div>
                    <Link to="/">Home</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/buyToken">Buy Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/sellToken">Sell Token</Link><span>&nbsp;&nbsp;</span>
                    <Link to="/sendToken">Send Token</Link>
                </div>
                <Switch>
                  <Route name="home" exact path='/' component={() => <Home {...this.props}/>}/>
                  <Route name="sellToken" path='/sellToken' component={SellToken}/>
                  <Route name="buyToken" path='/buyToken' component={BuyToken}/>
                  <Route name="sendToken" path='/sendToken' component={SendToken}/>
                </Switch>
            </div>

        )
    }
}


export default Market