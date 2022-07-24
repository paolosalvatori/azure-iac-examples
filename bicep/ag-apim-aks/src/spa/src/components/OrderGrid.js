import React, { useState, useEffect } from 'react'
import { getOrders } from '../orderService';
import MaterialTable from "material-table";
import tableIcons from "./MaterialTableIcons";
import { useMsal } from "@azure/msal-react";
import { apiConfig } from "../authConfig";

const columns = [
    { field: 'ID', title: 'ID', type: 'numeric' },
    { field: 'Name', title: 'Name' },
    { field: 'Description', title: 'Description' }
]

export const OrderGrid = () => {
    const { instance, accounts } = useMsal();
    const [tableData, setTableData] = useState([])

    useEffect(() => {
        instance.acquireTokenSilent({
            ...apiConfig.orderApiReadScope,
            account: accounts[0]
        }).then((response) => {
            let accessToken = response.accessToken;
            getOrders(accessToken)
            .catch(error => console.log(error))
            .then((data) => setTableData(data));
        })
    }, [])

    console.log(tableData)

    return (
        <div style={{ height: 500, width: '90%', margin: 'auto'}}>
            <MaterialTable title="Orders" columns={columns} data={tableData} icons={tableIcons} />
        </div>
    )
}