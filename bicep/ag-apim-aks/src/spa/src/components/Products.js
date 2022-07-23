import React from 'react'

export const Products = ({ products }) => {

    console.log('products length:::', products.length)
    if (products.length === 0) return null

    const ProductRow = (product, index) => {

        return (
            <tr key={index} className={index % 2 === 0 ? 'odd' : 'even'}>
                <td>{product.ID}</td>
                <td>{product.Name}</td>
                <td>{products.Description}</td>
            </tr>
        )
    }

    const productTable = products.map((product, index) => ProductRow(product, index))

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
                    {productTable}
                </tbody>
            </table>
        </div>
    )
}