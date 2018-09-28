import React, {Component} from 'react'


class SendToken extends Component {
    state = {
        address: "",
        token: 0
    }

    sendToken() {
        console.log(this.state.address)
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