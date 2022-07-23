import React from 'react'

export const DisplayProducts = ({numberOfProducts, getProducts}) => {

    const headerStyle = {

        width: '100%',
        padding: '2%',
        backgroundColor: "red",
        color: 'white',
        textAlign: 'center'
    }
    
    return(
        <div style={{backgroundColor:'green'}} className="display-board">
            <h4 style={{color: 'white'}}>Products</h4>
            <div className="number">
            {numberOfProducts}
            </div>
            <div className="btn">
                <button type="button" onClick={(e) => getProducts()} className="btn btn-warning">Get all Products</button>
            </div>
        </div>
    )
}