import React, {Component} from 'react'


class BuyToken extends Component {
    constructor(props) {
        super()
        this.state = {
            name: "",
            token:0,
            wei:0,
            tokenAddress: props.tokenInstance.address,
            toAddress:props.exchangeInstance.address,
            tokenName: "FIXED",
            buy:[]
        }
    }

    componentWillMount() {
        this.props.exchangeInstance.getBuyOrderBook(this.state.tokenName,{from:this.props.acc}).then(result => {
            var BN = this.props.web3.utils.BN;
            // const price = new BN(result[0]).toString()
            // const volume = new BN(result[1]).toString()
            // console.log(result.length)
            // this.setState({buy: [{price,volume},...this.state.buy]})

            result[0].map((x,i) => {
                const price = new BN(x).toString()
                const volume = new BN(result[1][i]).toString()
                this.setState({buy: [{price,volume},...this.state.buy]})
            })
        }).catch(err => {
         console.log(err)
        })
    }

    async buyToken() {
       this.props.exchangeInstance.buyToken(this.state.name, this.state.wei, this.state.token, {from: this.props.acc}).then(result => {
           console.log(result)
       }).catch(err => {
           console.log(err)
       })
    }

    render() {
        return(
            <div>
               <div>
                   <div>
                    <p>Buy Token</p>
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
                   <button onClick={this.buyToken.bind(this)}>
                        Buy Token
                    </button>
               </div>

                <div>
                    <p>BID</p>
                     {
                         this.state.buy.map((buy, i) => (
                             <div key={i}>
                                <p>Price:{buy.price}<span>&nbsp;&nbsp;</span>Volume:{buy.volume}</p>
                             </div>
                         ))
                     }
                </div>
            </div>
        )
    }
}


export default BuyToken