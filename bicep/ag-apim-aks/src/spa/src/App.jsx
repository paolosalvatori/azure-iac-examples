import React, { useState, useEffect } from 'react';
import { AuthenticatedTemplate, UnauthenticatedTemplate, useMsal } from "@azure/msal-react";
import { loginRequest } from "./authConfig";
import { PageLayout } from "./components/PageLayout";
import { ProfileData } from "./components/ProfileData";
import { callMsGraph } from "./graph";
import Button from "react-bootstrap/Button";
import { DisplayProducts } from './components/DisplayProducts';
import { DisplayOrders } from "./components/DisplayOrders";
import { Products } from "./components/Products";
import { Orders } from "./components/Orders";
import { getProducts, getProduct } from "./productService";
import { getOrders, getOrder } from "./orderService";
import "./styles/App.css";

/**
 * Renders information about the signed-in user or a button to retrieve data about the user
 */
const ProfileContent = () => {
    const { instance, accounts } = useMsal();
    const [graphData, setGraphData] = useState(null);

    function RequestProfileData() {
        // Silently acquires an access token which is then attached to a request for MS Graph data
        instance.acquireTokenSilent({
            ...loginRequest,
            account: accounts[0]
        }).then((response) => {
            callMsGraph(response.accessToken).then(response => setGraphData(response));
        });
    }

    return (
        <>
            <h5 className="card-title">Welcome {accounts[0].name}</h5>
            {graphData ?
                <ProfileData graphData={graphData} />
                :
                <Button variant="secondary" onClick={RequestProfileData}>Request Profile Information</Button>
            }
        </>
    );
};

/**
 * If a user is authenticated the ProfileContent component above is rendered. Otherwise a message indicating a user is not authenticated is rendered.
 */
const MainContent = () => {

    const [product, setProduct] = useState({})
    const [products, setProducts] = useState({})
    const [numberOfProducts, setNumberOfProducts] = useState(0)

    const [order, setOrder] = useState({})
    const [orders, setOrders] = useState({})
    const [numberOfOrders, setNumberOfOrders] = useState(0)

    const fetchAllProducts = () => {
        getProducts()
            .then(products => {
                console.log(products);
                setProducts(products);
                if (products == null) {
                    console.log("no products found");
                } else {
                setNumberOfProducts(products.length);
                }
                (error) => {
                    if (error) {
                      console.log(error);
                    }
                  }
            })
    }

    useEffect(() => {
        getProducts()
          .then(products => {
            console.log(products)
            setProducts(products);
            setNumberOfProducts(products.length)
          });
      }, [])

    const fetchAllOrders = () => {
        getOrders()
            .then(orders => {
                console.log(orders);
                setOrders(orders);
                if (orders == null) {
                    console.log("no orders found");
                } else {
                setNumberOfOrders(orders.length);
                }
                (error) => {
                    if (error) {
                      console.log(error);
                    }
                  }
            })
    }

    useEffect(() => {
        getOrders()
          .then(orders => {
            console.log(orders)
            setOrders(orders);
            setNumberOfOrders(orders.length)
          });
      }, [])

    return (
        <div className="App">
            <AuthenticatedTemplate>
                <ProfileContent />
                <DisplayProducts
                    numberOfProducts={numberOfProducts}
                    getProducts={fetchAllProducts}
                >
                </DisplayProducts>
                <Products products={products}></Products>
                <DisplayOrders
                    numberOfOrders={numberOfOrders}
                    getOrders={fetchAllOrders}
                >
                </DisplayOrders>
                <Orders orders={orders}></Orders>
            </AuthenticatedTemplate>

            <UnauthenticatedTemplate>
                <h5 className="card-title">Please sign-in to see your profile information.</h5>
            </UnauthenticatedTemplate>
        </div>
    );
};

export default function App() {
    return (
        <PageLayout>
            <MainContent />
        </PageLayout>
    );
}
