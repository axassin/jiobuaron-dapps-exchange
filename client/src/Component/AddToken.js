import React, {Component} from 'react'


class AddToken extends Component {
    constructor(props) {
        super()
        this.state = {
            tokenName: "",
            tokenAddress: props.tokenInstance.address,
            tokenAmount:0,
            toAddress:props.exchangeInstance.address
        }

        
    }

    async addToken() {
       this.props.exchangeInstance.addToken(this.state.tokenName, this.state.tokenAddress, {from: this.props.acc}).then(result => {
           console.log(result)
       }).catch(err => {
        alert("Token is already registered or Invalid Token Address")
       })
    }

    async approveToken() {
        this.props.tokenInstance.approve(this.state.toAddress, this.state.tokenAmount, {from: this.props.acc}).then(result => {
            console.log(result)
        }).catch(err => console.log(err))
    }

    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Add Token</p>
                    <p>Token Name:</p>
                        <input type="text" value={this.state.tokenName} onChange={(val => {this.setState({tokenName: val.target.value})})} />
                   </div>
                   <div>
                   <p>Token Address:</p>
                        <input type="text" value={this.state.tokenAddress} onChange={(val => {this.setState({tokenAddress: val.target.value})})} />
                   </div>
                   <button onClick={this.addToken.bind(this)}>
                        Add Token
                    </button>
               </div>
               <div>
                   <p>Approve Token</p>
                   <div>
                    <p>Token Amount:</p>
                        <input type="number" value={this.state.tokenAmount} onChange={(val => {this.setState({tokenAmount: val.target.value})})} />
                   </div>
                   <div>
                   <p>To Address:</p>
                        <input type="text" value={this.state.toAddress} onChange={(val => {this.setState({toAddress: val.target.value})})} />
                   </div>
                   <button onClick={this.approveToken.bind(this)}>
                        Approve Token
                    </button>
               </div>
            </div>
        )
    }
}


export default AddToken