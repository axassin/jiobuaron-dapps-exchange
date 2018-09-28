import React, {Component} from 'react'


class Ether extends Component {
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
       this.props.exchangeInstance.depositEther({value: this.props.web3.utils.toWei(this.state.dTokenAmount, "Ether"),from:this.props.acc}).then(result => {
           console.log(result)
       }).catch(err => {
        console.log(err)
        alert("Cant deposit Token")
       })
    }

    async withdraw() {
        this.props.exchangeInstance.withdrawEther(this.props.web3.utils.toWei(this.state.wTokenAmount, "Ether"),{from:this.props.acc}).then(result => {
            console.log(result)
        }).catch(err => {
         console.log(err)
         alert("Can't Withdraw Token")
        })
    }

    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Deposit Ether</p>
                   </div>
                   <div>
                   <p>Amount:</p>
                        <input type="text" value={this.state.dTokenAmount} onChange={(val => {this.setState({dTokenAmount: val.target.value})})} />
                   </div>
                   <button onClick={this.deposit.bind(this)}>
                        Deposit Ether
                    </button>
               </div>
               <div>
                   <div>
                    <p>WithDraw Ether</p>
                   </div>
                   <div>
                   <p>Amount:</p>
                     <input type="number" value={this.state.wTokenAmount} onChange={(val => {this.setState({wTokenAmount: val.target.value})})} />
                   </div>
                   <button onClick={this.withdraw.bind(this)}>
                        Withdraw Ether
                    </button>
               </div>
            </div>
        )
    }
}


export default Ether