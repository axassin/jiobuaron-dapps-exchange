import React, {Component} from 'react'


class Token extends Component {
    constructor(props) {
        super()
        this.state = {
            dTokenName: "",
            wTokenName: "",
            dTokenAmount:0,
            wTokenAmount:0,
            gas:4500000
        }

        
    }


    async deposit() {
       this.props.exchangeInstance.depositToken(this.state.dTokenName, this.state.dTokenAmount, {from: this.props.acc, gas: this.state.gas}).then(result => {
           console.log(result)
       }).catch(err => {
        console.log(err)
        alert("Token is already registered or Invalid Token Address")
       })
    }

    async withdraw() {
        this.props.exchangeInstance.withdrawToken(this.state.wTokenName, this.state.wTokenAmount, {from: this.props.acc, gas: this.state.gas}).then(result => {
            console.log(result)
        }).catch(err => {
         alert("Token is already registered or Invalid Token Address")
        })
    }

    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Deposit Token</p>
                    <p>Token Name:</p>
                        <input type="text" value={this.state.dTokenName} onChange={(val => {this.setState({dTokenName: val.target.value})})} />
                   </div>
                   <div>
                   <p>Amount:</p>
                        <input type="text" value={this.state.dTokenAmount} onChange={(val => {this.setState({dTokenAmount: val.target.value})})} />
                   </div>
                   <button onClick={this.deposit.bind(this)}>
                        Deposit Token
                    </button>
               </div>
               <div>
                   <p>WithDraw Token</p>
                   <div>
                    <p>Token Name:</p>
                        <input type="text" value={this.state.wTokenName} onChange={(val => {this.setState({wTokenName: val.target.value})})} />
                   </div>
                   <div>
                   <p>Amount:</p>
                        <input type="number" value={this.state.wTokenAmount} onChange={(val => {this.setState({wTokenAmount: val.target.value})})} />
                   </div>
                   <button onClick={this.withdraw.bind(this)}>
                        Withdraw Token
                    </button>
               </div>
            </div>
        )
    }
}


export default Token