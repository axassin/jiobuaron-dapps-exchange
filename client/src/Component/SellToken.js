import React, {Component} from 'react'


class SellToken extends Component {
    constructor(props) {
        super()
        this.state = {
            name: "",
            token:0,
            wei:0,
            tokenAddress: props.tokenInstance.address,
            toAddress:props.exchangeInstance.address,
            tokenName: "FIXED",
            sell:[]
        }
    }

    componentWillMount() {
        this.props.exchangeInstance.getSellBook(this.state.tokenName).then(result => {
            var BN = this.props.web3.utils.BN;
            // const price = new BN(result[0]).toString()
            // const volume = new BN(result[1]).toString()
            // console.log(result.length)
            // this.setState({buy: [{price,volume},...this.state.buy]})
            console.log(result)
            result[0].map((x,i) => {
                const price = new BN(x).toString()
                const volume = new BN(result[1][i]).toString()
                this.setState({sell: [{price,volume},...this.state.sell]})
            })

        }).catch(err => {
         console.log(err)
        })
    }

    async sellToken() {
       this.props.exchangeInstance.sellToken(this.state.name, this.state.wei, this.state.token, {from: this.props.acc}).then(result => {
           console.log(result)
       }).catch(err => {
           console.log(err)
        alert("FAiled")
       })
    }

    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Sell Token</p>
                    <p>Token Name:</p>
                        <input type="text" value={this.state.name} onChange={(val => {this.setState({name: val.target.value})})} />
                   </div>
                   <div>
                   <p>Token amount:</p>
                        <input type="text" value={this.state.token} onChange={(val => {this.setState({token: val.target.value})})} />
                   </div>
                   <div>
                   <p>Price in Wei:</p>
                        <input type="text" value={this.state.wei} onChange={(val => {this.setState({wei: val.target.value})})} />
                   </div>
                   <button onClick={this.sellToken.bind(this)}>
                        Sell Token
                    </button>
               </div>

                 <div>
                    <p>ASK</p>
                     {
                         this.state.sell.map((sell, i) => (
                             <div key={i}>
                                <p>Price:{sell.price}<span>&nbsp;&nbsp;</span>Volume:{sell.volume}</p>
                             </div>
                         ))
                     }
                </div>
            </div>
        )
    }
}


export default SellToken