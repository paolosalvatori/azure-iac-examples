import React, { useState, useEffect } from 'react'
import { getProducts } from '../productService';
import MaterialTable from "material-table";
import tableIcons from "./MaterialTableIcons";

const columns = [
    { field: 'ID', title: 'ID', type: "numeric" },
    { field: 'Name', title: 'Name', width: 300 },
    { field: 'Description', title: 'Description', width: 600 }
  ]

export const ProductGrid = () => {
    const [tableData, setTableData] = useState([])

    useEffect(() => {
        getProducts()
            .then((data) => setTableData(data))
    }, [])
    console.log(tableData)

    return (
        <div style={{ height: 500, width: '65%' }}>
            <MaterialTable title="Products" columns={columns} data={tableData} icons={tableIcons}/>
        </div>
    )
}
