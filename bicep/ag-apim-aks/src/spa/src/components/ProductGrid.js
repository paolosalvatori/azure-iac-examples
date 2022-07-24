import React, { useState, useEffect } from 'react'
import { getProducts } from '../productService';
import MaterialTable from "material-table";
import tableIcons from "./MaterialTableIcons";
import { useMsal } from "@azure/msal-react";
import { apiConfig } from "../authConfig";

const columns = [
    { field: 'ID', title: 'ID', type: "numeric" },
    { field: 'Name', title: 'Name', width: 300 },
    { field: 'Description', title: 'Description', width: 600 }
]

export const ProductGrid = () => {
    const { instance, accounts } = useMsal();
    const [tableData, setTableData] = useState([])

    useEffect(() => {
        instance.acquireTokenSilent({
            ...apiConfig.productApiReadScope,
            account: accounts[0]
        }).then((response) => {
            let accessToken = response.accessToken;
            getProducts(accessToken)
            .catch(error => console.log(error))
            .then((data) => setTableData(data));
        })
    }, [])

    console.log(tableData)

    return (
        <div style={{ height: 500, width: '90%', margin: 'auto' }}>
            <MaterialTable title="Products" columns={columns} data={tableData} icons={tableIcons} />
        </div>
    )
}