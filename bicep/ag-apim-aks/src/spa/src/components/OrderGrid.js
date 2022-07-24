import React, { useState, useEffect } from 'react'
import { getOrders } from '../orderService';
import MaterialTable from "material-table";
import tableIcons from "./MaterialTableIcons";

const columns = [
    { field: 'ID', title: 'ID', type: "numeric" },
    { field: 'Name', title: 'Name', width: 300 },
    { field: 'Description', title: 'Description', width: 600 }
  ]

export const OrderGrid = () => {
    const [tableData, setTableData] = useState([])

    useEffect(() => {
        getOrders()
            .then((data) => setTableData(data))
    }, [])
    console.log(tableData)

    return (
        <div style={{ height: 500, width: '65%' }}>
            <MaterialTable title="Orders" columns={columns} data={tableData} icons={tableIcons}/>
        </div>
    )
}