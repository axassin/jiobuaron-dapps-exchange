import React, {Component} from 'react'


class SendToken extends Component {
    state = {
        address: "",
        token: 0,
    }

    async sendToken() {
        const result = await this.props.tokenInstance.transfer(this.state.address, this.state.token, {from:this.props.acc}) 
        if(result){
            // this.props.setBalance()
        } else {
            alert("Transfer Amount Failed")
        }
        
    }
    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Address:</p>
                        <input type="text" value={this.state.address} onChange={(val => {this.setState({address: val.target.value})})} />
                   </div>
                   <div>
                   <p>Token:</p>
                        <input type="number" value={this.state.token} onChange={(val => {this.setState({token: val.target.value})})} />
                   </div>
                   <button onClick={this.sendToken.bind(this)}>
                        Send Token
                    </button>
               </div>
            </div>
        )
    }
}


export default SendToken