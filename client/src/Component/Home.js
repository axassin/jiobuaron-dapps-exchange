import React, {Component} from 'react'

class Home extends Component {

    state = {
        wew: 0
    }
    
    componentDidMount() {

    }

    render() {
        return(
            <div>
                {this.state.wew}
            </div>

        )
    }
}


export default Home