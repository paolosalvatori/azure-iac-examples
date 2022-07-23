import React from 'react'

export const Orders = ({ orders }) => {

    console.log('orders length:::', orders.length)
    if (orders.length === 0) return null

    const ProductRow = (order, index) => {

        return (
            <tr key={index} className={index % 2 === 0 ? 'odd' : 'even'}>
                <td>{order.ID}</td>
                <td>{order.Name}</td>
                <td>{orders.Description}</td>
            </tr>
        )
    }

    const orderTable = orders.map((order, index) => ProductRow(order, index))

    return (
        <div className="container">
            <table className="table table-bordered">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    {orderTable}
                </tbody>
            </table>
        </div>
    )
}