import React from 'react'

export const DisplayOrders = ({numberOfOrders, getOrders}) => {

    const headerStyle = {

        width: '100%',
        padding: '2%',
        backgroundColor: "red",
        color: 'white',
        textAlign: 'center'
    }
    
    return(
        <div style={{backgroundColor:'green'}} className="display-board">
            <h4 style={{color: 'white'}}>Orders</h4>
            <div className="number">
            {numberOfOrders}
            </div>
            <div className="btn">
                <button type="button" onClick={(e) => getOrders()} className="btn btn-warning">Get all Orders</button>
            </div>
        </div>
    )
}